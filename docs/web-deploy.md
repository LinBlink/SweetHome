# Web 部署

## 构建

```bash
flutter pub get
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
python scripts/precompress_web.py
```

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
    # web/flutter_bootstrap.js 已把它从 fonts.gstatic.com 改指到这里。
    #
    # 本服务器出不了网，所以这里直接 404 —— 这一行【不能省】：没有它，
    # 下面 `location /` 的 try_files 会把 index.html 当字体返回给引擎，
    # 引擎拿 HTML 当 woff2 解析，反复失败重试。返回 404 则是瞬时失败，
    # 引擎立刻放弃并使用内置字体。
    #
    # 应用已内置全部界面文案用字 + 3755 常用汉字 + 全部单色 emoji
    # （见 pubspec.yaml 的 fonts: 段），走到这里的只剩生僻字、
    # 非中文的用户正文、以及彩色/组合 emoji。
    location /gfonts/ {
        return 404;
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

## 如果将来服务器能出网

把 `location /gfonts/` 换成反向代理，生僻字和彩色 emoji 就能补齐：

```nginx
# http {} 层
proxy_cache_path /var/cache/nginx/gfonts levels=1:2 keys_zone=gfonts:10m
                 max_size=512m inactive=365d use_temp_path=off;

# server {} 层
location /gfonts/ {
    proxy_pass https://fonts.gstatic.com/s/;
    proxy_set_header Host fonts.gstatic.com;
    proxy_ssl_server_name on;
    proxy_cache gfonts;
    # Google Fonts 的 URL 自带内容版本号，同一 URL 内容永不变，可以长缓存
    proxy_cache_valid 200 365d;
    proxy_cache_valid 404 1m;
    add_header Cache-Control "public, max-age=31536000, immutable";
    add_header X-Cache-Status $upstream_cache_status;
    resolver 223.5.5.5 119.29.29.29 valid=300s;
}
```

不出网但想补齐的话，也可以在能访问的机器上把
`notocoloremoji` 和 `roboto` 两个目录抓下来放进
`/var/www/sweethome/gfonts/`，保持 `fonts.gstatic.com/s/` 的目录结构，
再把 `return 404` 换成静态目录。

## 已知的显示差异

内置字体是**单色轮廓** emoji，不是彩色的 —— 彩色版（Noto Color Emoji）
有好几 MB，且客户端和服务器都够不着 gstatic，没有可行的加载途径。

组合 emoji（👨‍👩‍👧‍👦 这类 ZWJ 序列）会显示为并排的单个 emoji。保留组合字形
需要把字体从 71KB 撑到 3.7MB，不划算。

国旗 emoji（🇨🇳）不显示。它靠区域指示符的连字实现，同样在被裁掉的那批里。
手机号输入框的国家选择器因此只有区号没有旗帜。

## 验证

```bash
# 应返回 content-encoding: br（或 gzip）
curl -sI -H 'Accept-Encoding: br' https://sweethome.asia/main.dart.js | grep -i 'content-encoding\|content-length'

# 应返回 content-type: application/wasm
curl -sI https://sweethome.asia/canvaskit/chromium/canvaskit.wasm | grep -i content-type

# 字体镜像，首次 MISS 之后应为 HIT
curl -sI https://sweethome.asia/gfonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2 | grep -i 'x-cache-status\|HTTP/'
```

浏览器 DevTools 的 Network 面板里**不应出现任何 gstatic.com 请求**。出现了就说明
构建时漏了 `--no-web-resources-cdn`，或者 `flutter_bootstrap.js` 被默认模板覆盖了。

## Service Worker 的注意事项

`web/flutter_bootstrap.js` 注册了 Flutter 生成的 Service Worker，重复访问因此
几乎零网络请求。但构建日志会提示它 **已废弃（deprecated）**，未来 Flutter 版本
会移除 —— 届时删掉 `serviceWorkerSettings` 那几行即可，上面的 HTTP 缓存配置
会接管（重复访问变成一串 304，比现在慢但仍可接受）。

如果某次发版后用户卡在旧版本：Service Worker 按 `serviceWorkerVersion` 判断更新，
而该值每次构建都会变，正常情况会自动升级。手动恢复的办法是让用户在
DevTools → Application → Service Workers 里 Unregister，或者临时把
`flutter_service_worker.js` 返回 404，浏览器会注销掉它。
