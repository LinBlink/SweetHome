# Web 部署

## 构建

```bash
flutter pub get
python scripts/fetch_gfonts_mirror.py     # 需要能访问 fonts.gstatic.com
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
python scripts/precompress_web.py
```

`fetch_gfonts_mirror.py` 把引擎的整套字体回退集（724 个文件、约 21MB）抓到
`web/gfonts/`，由普通构建一并复制进 `build/web/`。已经抓过的不重复下载，
所以日常构建时它是个空操作。**这一步不能省**，理由见下面的「字体回退」一节。
`web/gfonts/` 不进 git（体积大且可确定性重建），换机器或升级 Flutter 后
重跑一次即可；`--check` 可以只校验不下载。

`--no-web-resources-cdn` **不是可选项**。省略它，`flutter_bootstrap.js` 会从
`https://www.gstatic.com/flutter-canvaskit/` 加载渲染引擎 —— 该域名在中国大陆不可达，
结果是永久白屏。加上它之后引擎从本站 `/canvaskit/` 提供。

改过 `lib/l10n/*.arb` 之后，还要重新生成界面字体子集，否则新加的字要走网络回退：

```bash
python scripts/build_ui_fonts.py
```

## 部署

把 `build/web/` 整个目录（含 `.br` / `.gz` 伴生文件）同步到静态根目录：

```bash
rsync -a --delete build/web/ user@host:/var/www/sweethome/
```

## nginx

```nginx
# ── http {} 层 ────────────────────────────────────────────────
# WebSocket 升级头透传用（见下面的 /api/v1/ws）
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

# 字体回退的磁盘缓存。365d 是安全的：Google Fonts 的 URL 自带内容版本号，
# 同一个 URL 的内容永不改变。
proxy_cache_path /var/cache/nginx/gfonts levels=1:2 keys_zone=gfonts:10m
                 max_size=512m inactive=365d use_temp_path=off;

# .wasm 默认不在 nginx 的 mime.types 里，缺了它浏览器拒绝流式编译，
# 引擎启动会慢一大截。
types {
    application/wasm  wasm;
}

# ── server {} ─────────────────────────────────────────────────
server {
    listen 443 ssl;
    http2 on;
    server_name sweethome.asia;

    root /var/www/sweethome;
    index index.html;

    # ── 压缩 ──────────────────────────────────────────────────
    # 预压缩优先：precompress_web.py 用 brotli q11 生成过 .br，
    # 比 nginx 实时压缩更小，且不占请求时的 CPU。
    brotli_static on;          # 需要 ngx_brotli 模块，没有就删掉这行
    gzip_static on;
    # 兜底：漏掉的文件仍然实时压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/javascript application/json
               application/wasm image/svg+xml font/ttf font/otf;

    # ── 缓存 ──────────────────────────────────────────────────
    # 注意：Flutter 的产物文件名不带内容哈希（永远叫 main.dart.js），
    # 所以【不能】用 `expires 1y; immutable` —— 那会让用户永久卡在旧版本。
    # must-revalidate + ETag 让重复访问走 304，省下传输但不牺牲新鲜度；
    # 真正的零请求由 Service Worker 负责。
    location ~* \.(js|wasm|ttf|otf|png|svg|json|css)$ {
        add_header Cache-Control "public, max-age=0, must-revalidate";
    }

    # 这几个决定「有没有新版本」，必须每次问。
    location = /index.html            { add_header Cache-Control "no-cache"; }
    location = /flutter_bootstrap.js  { add_header Cache-Control "no-cache"; }
    location = /flutter_service_worker.js { add_header Cache-Control "no-cache"; }
    location = /version.json          { add_header Cache-Control "no-cache"; }

    # ── 字体回退出口 ──────────────────────────────────────────
    # CanvasKit 看不到系统字体，找不到的字形会向 fontFallbackBaseUrl 取。
    # web/flutter_bootstrap.js 已把它从 fonts.gstatic.com 改指到这里，
    # 文件由 fetch_gfonts_mirror.py 预先抓好、随构建产物一起发布，
    # 所以这里就是普通静态目录，服务器不需要出网。
    #
    # URL 自带内容版本号（notosanssc/v37/...），同一 URL 内容永不改变，
    # 可以放心 immutable。上面那条通用静态规则不覆盖 .woff2，所以要单列。
    location /gfonts/ {
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # ── 应用 ──────────────────────────────────────────────────
    # SPA 回退：深链接刷新时不能 404。
    location / {
        try_files $uri $uri/ /index.html;
    }

    # ── 后端 ──────────────────────────────────────────────────
    location /api/v1/ws {
        proxy_pass http://127.0.0.1:6001/v1/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering    off;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:6001/;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 10s;
        proxy_read_timeout    60s;
        proxy_send_timeout    60s;
    }
}
```

## 字体回退：为什么必须让它真的能用

`/gfonts/` 早先是【故意】返回 404 的，想法是「没内置的字形就让它退化成豆腐块，
快速失败总比卡住好」。引擎不这么配合。

`_FallbackFontDownloadQueue` 只记录**成功**的下载：失败时它把 URL 从
`pendingFonts` 里删掉，却不写进 `downloadedFonts`。于是同一段文字下次排版又会
把同一个字体重新入队；而每批下载结束（哪怕全军覆没）都会广播一次字体变更消息，
触发全应用重新排版，又回到原点。**一个没覆盖的字符不是一次 404，是无限次**——
如果那段文字在动画里，就是逐帧刷屏。

这个洞也堵不上：`build_ui_fonts.py` 能扫到的只有我们自己的 ARB 和 Dart 源码，
它看不见服务端下发的人名里的生僻字、聊天正文里的日文、消息里的 emoji。
所以唯一的出路是让回退真的取得到——成功的下载引擎才会记住。

整套 724 个文件才 21MB，客户端只按需取其中的几个 ~25KB 分片，
放在自己站点上等于零首屏代价换无限覆盖。

内置子集（`pubspec.yaml` 的 `fonts:` 段）保留：它让界面文案和常用汉字
一次网络请求都不用发，镜像只兜底剩下的部分。

升级 Flutter 之后重跑一次 `fetch_gfonts_mirror.py`：URL 里的版本号
（`v37`、`v53`……）由 SDK 决定，脚本直接读 SDK 里的
`font_fallback_data.dart`，两边不会走散。

## Emoji

emoji **不内置**，全部走 `/gfonts/` 镜像里的 Noto Color Emoji（彩色，完整）。

以前是内置的：`ui_emoji.ttf`，3.8MB，而且在 `pubspec.yaml` 的 `fonts:` 段里
——那里面的字体引擎启动时全部加载，等于每次首屏都背这 3.8MB。更糟的是子集化
一个 COLR 字体本来就不干净：U+200D 和约 9500 个字形被裁掉了，ZWJ 一没，
整字器就拼不出组合 emoji（👨‍👩‍👧‍👦）和国旗（🇨🇳）——花 3.8MB 买到的是比原版
更差的覆盖。镜像一到位这个取舍就不成立了，于是删掉。

现在的代价是每个 emoji 分片首次出现时一次 ~150KB 的按需请求
（`notocoloremoji` 共 12 片，1.9MB），之后按 `immutable` 永久缓存。

唯一需要留意的地方是 PDF 导出：`ChatExportPdfService` 把 emoji 用
`TextPainter` 同步栅格化成 PNG，等不了异步下载。它因此在导出时用
`FontLoader` 临时注册 `assets/fonts/NotoEmoji-Regular.ttf`（同一份上游字体，
本来就要读给 `pdf` 包用），不进 `fonts:` 段，所以不占首屏。

## 验证

```bash
# 应返回 content-encoding: br（或 gzip）
curl -sI -H 'Accept-Encoding: br' https://sweethome.asia/main.dart.js | grep -i 'content-encoding\|content-length'

# 应返回 content-type: application/wasm
curl -sI https://sweethome.asia/canvaskit/chromium/canvaskit.wasm | grep -i content-type

# 字体回退镜像，应返回 200 + font/woff2
curl -sI https://sweethome.asia/gfonts/notocoloremoji/v32/Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.0.woff2 | grep -i 'HTTP/\|content-type\|cache-control'

# 本地校验镜像是否完整（不下载）
python scripts/fetch_gfonts_mirror.py --check
```

浏览器 DevTools 的 Network 面板里**不应出现任何 gstatic.com 请求**。出现了就说明
构建时漏了 `--no-web-resources-cdn`，或者 `flutter_bootstrap.js` 被默认模板覆盖了。

`/gfonts/` 下**不应出现任何 404**，更不应出现同一个 URL 反复请求。出现了就是
镜像没跟上 SDK（重跑 `fetch_gfonts_mirror.py`）或者根本没发布上去。

## Service Worker 的注意事项

**这个功能实际上已经没了。** 当前 SDK 生成的 `build/web/flutter_service_worker.js`
只有 800 字节，内容是「安装即 skipWaiting，激活即 `registration.unregister()`
并让所有页面重新导航」—— 一个专门用来把历史遗留 SW 注销掉的空壳，不再缓存任何东西。
`web/flutter_bootstrap.js` 里的 `serviceWorkerSettings` 因此只剩注销的作用，
删掉它也可以。

所以重复访问现在靠的是上面那套 HTTP 缓存：一串 304，比 SW 慢但可接受。
顺带一提，这也意味着 `/gfonts/` 那 21MB **不会**被 SW 整体预缓存——
浏览器只会取实际用到的那几个分片，并按 `immutable` 永久留着。

如果有用户仍卡在旧版本，多半是旧 SW 还在：让他在
DevTools → Application → Service Workers 里 Unregister，或者临时把
`flutter_service_worker.js` 返回 404。
