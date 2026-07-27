# 给一个名为“过家家”的APP设计应用图标。该应用是一个基于家庭的垂直领域社交应用。

# 自定义图标规范

每个 `.svg` 都对应 `lib/core/app_icons.dart` 里的一个 `AppIconSpec`，由
`lib/widgets/app_icon.dart` 的 `AppIcon` 渲染。

**有两套图标（icon pack），用户在「我的 → 图标风格」里切换**：

| pack | 目录 | 名字 | 特点 |
|---|---|---|---|
| `AppIconPack.standard` | `assets/icons/svg/` | 默认图标 | 线性、单色，跟随主题色 |
| `AppIconPack.playful` | `assets/icons/svg_playful/` | 减龄图标 | 圆润、多彩，自带颜色 |

**两套目录里的文件名必须完全一致**——同一个 spec 在每个 pack 里都要有文件，
少一个，用户切到那个 pack 时这个图标就退回 Material 兜底了。测试会拦。

## 先看这三条

**1. 空文件不会白屏。** 每个 spec 都绑了一个 Material 兜底图标。文件是 0 字节时
`AppIcon` 画 Material 图标，尺寸和颜色完全一致；你往文件里画上东西，下次启动就自动
切成你的 SVG。所以**不用一次画完，一个一个填即可**，中途 app 始终能跑。

判定发生在启动时（`main()` 里 `await AppIconAssets.warmUp()`），不是每帧，而且
**两个 pack 一起探测**（所以切换是同步重绘，不会闪一下兜底）。所以
**填完文件要重启 app（hot reload 不够，需要 hot restart 或重跑）**。debug 模式下
控制台会每个 pack 打印一行 `AppIcons[standard]: 12/35 custom icons drawn, ...`。

**2. 全部画在 24×24 画布上。** 不管代码里渲染成 12 还是 48，源文件统一
`viewBox="0 0 24 24"`。运行时等比缩放。

**3. 两种上色方式，二选一，不能混。** 启动探测时按文件内容判定：

- **可染色（单色）**：文件里出现 `currentColor`。`AppIcon` 用
  `ColorFilter.mode(color, BlendMode.srcIn)` 把整张图涂成调用方给的颜色，
  SVG 里写的其它颜色**全部丢掉**。描边式用 `stroke="currentColor"`，填充式用
  `fill="currentColor"`。不透明度会保留（`srcIn` 只换色相），想做浅色细节就用
  `fill-opacity="0.4"`，不要用浅灰色。
- **多彩（`svg_playful/` 这一套）**：文件里没有 `currentColor`，颜色写死成 `#RRGGBB`。
  这时不套滤镜，画什么色就是什么色。调用方传的 `color` 只剩 alpha 生效
  （导航栏未选中态的 `0xCCEFE0D0` → 80% 不透明度），色相被忽略。

**混着写会静默丢色**——只要文件里有一个 `currentColor`，整张图就走染色分支，
写死的颜色会被一起涂掉。`test/app_icons_test.dart` 会拦这种文件。

判定和「是否已画」一起在 `AppIconAssets.warmUp()` 里完成，是**按文件**判的，不是
按 pack——所以理论上一个 pack 里可以两种混着放。但 `svg/`（默认）必须整套都是
可染色的，否则跟不上主题色，测试里有一条专门守这个。

多彩图标仍然不能用渐变/滤镜/蒙版（flutter_svg 支持不全，测试里也禁了）。

### 推荐的模板

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <path d="..." stroke="currentColor" stroke-width="1.8"
        stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

填充式：

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="..." fill="currentColor"/>
</svg>
```

### 画的时候注意

- **留白**：主体控制在中间 20×20 内（四周各留 2px）。Material 就是这个规格，
  混排时才不会一大一小。
- **描边粗细**：全套统一 1.8（或全套统一 2.0），不要一个图标一个粗细——这是
  一套图标看起来"是一套"的最主要因素。
- **小尺寸克制细节**：下表里 12/13/16 那几个，缩到 12px 时 1.8 的描边只剩不到
  1px。这几个图标要么画成填充式，要么把细节砍到只剩轮廓。
- **导出前清理**：Figma/Illustrator 导出的 SVG 常带 `width`/`height`、`<defs>`、
  `clip-path`、`<style>`、id。flutter_svg 支持得不全，能删就删，只留 `viewBox` +
  `<path>`。渐变、滤镜、蒙版、`<text>`、位图 `<image>` 一律不要用。
- **成对的图标要像同一个东西**：底部导航 4 组 outline/filled 是同一物体的两个
  状态，形状轮廓必须对齐，不能一个圆一个方——否则切 tab 时会"跳"。

---

## 图标清单（35 个）

「渲染尺寸」是代码里实际用到的尺寸，只影响你画细节时的克制程度，不影响画布大小。
「兜底」是还没画时显示的 Material 图标，也是这个图标当前的样子，可以直接照着改。

### 底部导航栏

选中态填充、未选中态描边，由 `main.dart` 的 `_buildNavItem` 切换。颜色固定：
选中纯白，未选中 `0xCCEFE0D0`（半透明米色）。

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `nav_messages.svg` | 消息 tab，未选中 | 23 | `chat_bubble_outline` |
| `nav_messages_active.svg` | 消息 tab，选中 | 23 | `chat_bubble_rounded` |
| `nav_contacts.svg` | 联系人 tab，未选中 | 23 | `people_alt_outlined` |
| `nav_contacts_active.svg` | 联系人 tab，选中 | 23 | `people_alt_rounded` |
| `nav_feed.svg` | 家庭动态 tab，未选中 | 23 | `timeline_outlined` |
| `nav_feed_active.svg` | 家庭动态 tab，选中 | 23 | `timeline_rounded` |
| `nav_profile.svg` | 我的 tab，未选中 | 23 | `person_outline` |
| `nav_profile_active.svg` | 我的 tab，选中 | 23 | `person_rounded` |

### 品牌标记

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `nav_home.svg` | 品牌符号：两个大人 + 中间抱着心的孩子。三处复用：导航栏中间凸起的圆形主按钮(28)、启动闪屏(48)、"我的"页家庭名前的小标(13) | 28 / 48 / 13 | `cottage_rounded` |

> **必须和 `app_icon.png`（启动图标）是同一个标记**，形状直接取自
> `family_icon.svg`（同目录，单色矢量源），只是按启动图重新上了色：
> 大人 `#FDF3E7`，孩子 `#F0A94E` + `#C9563B` 描边，心 `#C0424A`。
>
> 孩子那圈赤陶描边不是装饰——它压在两个大人身上，启动图里靠背景色留出的
> 那道缝，在这里只能靠描边做，去掉就糊成一块。
>
> 跨度 13→48 都要认得出来。13px 下三个人形会并成一团，只剩「白-橙-白 + 一点红」
> 的色块印象，这是可以接受的下限；再加细节就没了。兜底的 `cottage_rounded`
> 还是个房子，和这个标记对不上，但只在 svg 缺失时才会出现。

### 通用操作（全 app 复用）

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `action_back.svg` | 返回箭头，出现在聊天室和搜索页的 AppBar 左侧 | 24 | `arrow_back_ios_new_rounded` |
| `action_search.svg` | 放大镜。三种场景：会话列表 AppBar 按钮(24)、搜索输入框前缀(22)、搜索页空状态大图(44) | 24 / 22 / 44 | `search_rounded` |
| `action_close.svg` | 叉号，用于清空输入框、关掉横幅提示 | 16 / 18 | `close_rounded` |
| `row_chevron.svg` | 「我的」页每个可点行右侧的箭头（7 处复用） | 20 | `chevron_right` |

### 聊天

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `chat_send.svg` | 发送。画在实心圆形按钮里 | 20 | `send_rounded` |
| `chat_attach.svg` | 输入框左侧「+」，点开图片/视频/语音/红包面板 | 24 | `add_circle_outline` |
| `chat_emoji.svg` | 切到表情面板（当前是键盘态） | 24 | `emoji_emotions_outlined` |
| `chat_keyboard.svg` | 切回键盘（当前是表情态）。和上一个是一对，互斥出现 | 24 | `keyboard_alt_outlined` |
| `chat_more.svg` | 聊天室 AppBar 右侧「更多」 | 24 | `more_horiz_rounded` |

### 空状态与状态提示

空状态图标渲染在 44，并且会被降到 0.5~0.6 透明度，所以可以比别的图标画得更饱满些。

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `empty_conversations.svg` | 一条会话都没有时的大图标 | 44 | `forum_rounded` |
| `empty_search.svg` | 搜索无结果 | 44 | `search_off_rounded` |
| `status_offline.svg` | 断网横幅左侧的小标（多彩版自带警告黄/橙） | 16 | `wifi_off` |
| `state_selected.svg` | 选中打勾，用在主题色和深浅模式选择列表 | 22 | `check_circle_rounded` |

### 「我的」页面

除 `profile_wallet` / `profile_edit` 外，其余都画在 38×38 的圆角色块里、渲染 20，
色块底色是图标色的 10% 透明度。

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `profile_members.svg` | 家庭成员列表入口 | 20 | `people_alt_rounded` |
| `profile_join_family.svg` | 加入家庭（邀请码/二维码） | 20 | `qr_code_2_rounded` |
| `profile_theme.svg` | 主题配色 | 20 | `palette_rounded` |
| `profile_appearance.svg` | 深浅模式 | 20 | `dark_mode_rounded` |
| `profile_icon_pack.svg` | 图标风格（切换这两套图标本身） | 20 | `auto_awesome_rounded` |
| `profile_language.svg` | 语言切换 | 20 | `translate_rounded` |
| `profile_storage.svg` | 存储管理/清缓存（多彩版自带危险红） | 20 | `delete_sweep_rounded` |
| `profile_export.svg` | 导出聊天记录 | 20 | `ios_share_rounded` |
| `profile_edit.svg` | 顶部资料卡右侧的编辑提示 | 20 | `edit_outlined` |
| `profile_wallet.svg` | 顶部资料卡里的余额小标 | **12** | `account_balance_wallet_rounded` |

> `profile_wallet` 只有 12px，是全套最小的一个。别画钱包的搭扣和缝线，
> 缩下去只会变成一团。

### 深浅模式选择

三个一组，出现在同一个列表里，风格要一致（比如都用同一个"太阳"半径）。

| 文件 | 含义 | 尺寸 | 兜底 |
|---|---|---|---|
| `appearance_auto.svg` | 跟随系统 | 22 | `brightness_auto_rounded` |
| `appearance_light.svg` | 浅色 | 22 | `light_mode_rounded` |
| `appearance_dark.svg` | 深色 | 22 | `dark_mode_rounded` |

---

## 加新图标

1. `lib/core/app_icons.dart` 里加一个 `static const xxx = AppIconSpec('文件名',
   Icons.兜底图标)`，并把它加进末尾的 `all` 列表（`warmUp` 靠这个列表扫描，漏了
   就永远走兜底）。
2. **每个 pack 目录下都建一个**空文件：`assets/icons/svg/文件名.svg` 和
   `assets/icons/svg_playful/文件名.svg`。少建一个测试会红。
3. 调用处把 `Icon(Icons.x, ...)` 换成 `AppIcon(AppIcons.xxx, ...)`——两者参数
   同名同义（`size` / `color` / `semanticLabel`），也同样继承 `IconTheme`。
4. `flutter test test/app_icons_test.dart` 会校验 spec 和文件一一对应。

新增 svg 文件**不需要**改 `pubspec.yaml`——那里注册的是目录，不是单个文件。但
新建文件后要跑一次 `flutter pub get` 让它进 asset manifest。

## 还没接入的部分

这一轮只接了上面 35 个（导航栏、聊天输入、通用操作、「我的」页）。剩下约 110 个
Material 图标仍在直接使用，主要是：家庭动态/发布、定位与围栏、健康、红包、导出。

其中一批卡在共享组件的参数类型上——`HomeSectionHeader.accentIcon`、
`HomePrimaryButton.leadingIcon`（`lib/core/home_widgets.dart`）等收的是
`IconData`，改成 `AppIconSpec` 会一次性影响所有调用方，所以留到下一轮统一改。

---

## 目录与文件

| 路径 | 内容 |
|---|---|
| `svg/` | 「默认图标」pack：单色可染色，跟随主题色。 |
| `svg_playful/` | 「减龄图标」pack：圆润多彩，自带颜色。 |
| `app_icon.png` | 启动图标（`flutter_launcher_icons` 的输入），也是多彩版配色的出处。 |
| `family_icon.svg` | 品牌标记的单色矢量源，两个 pack 的 `nav_home.svg` 形状都取自这里。 |

两个 `svg*/` 目录都注册在 `pubspec.yaml` 里、都会打进包（用户随时能切）；
`app_icon.png` 和 `family_icon.svg` 是设计源文件，不进 manifest。

### 切换是怎么实现的

- `AppIconPack`（`lib/core/app_icons.dart`）= id + 目录，id 是存进
  SharedPreferences 的值（`icon_pack`），**不能改名**，改了等于把所有选过它的
  用户重置回默认。
- 当前 pack 放在 `AppIconAssets.pack`（一个 `ValueNotifier`），每个 `AppIcon`
  直接监听它——所以切换只重绘图标，不需要整棵树重建。
- 写它的只有 `ThemeProvider`（`setIconPack` / `restore`），和主题色、深浅模式
  一样是设备级偏好，不跟账号走。
- 选择面板要预览**没被选中**的那套，不能用 `AppIcon`（它永远画当前 pack），
  用 `AppIconArtwork`（指定 pack 的那个版本）。

### 多彩版（减龄图标）用的色板

品牌标记（`nav_home`）用启动图标的原色，其余图标用下面这组：

| 用途 | 色值 |
|---|---|
| 珊瑚红（主角、强调、危险） | `#F4715C` |
| 琥珀橙（描边、次要主体） | `#F2A03D` |
| 蜜黄（高光、星点） | `#FFD75E` |
| 薄荷绿（确认、增加） | `#4FC8A0` / 深 `#2FA47E` |
| 天蓝（信息、发送） | `#57B7EC` / 浅 `#A9DEF9` |
| 薰衣草紫（个人、空状态） | `#A98BE8` / 深 `#6B57A8` |
| 粉（腮红、爱心） | `#FF8FB8` |
| 奶油白（底色、挖空） | `#FFF1DD` |
| 可可棕（五官） | `#7A4B32` |

都是中明度，深浅两种背景上都看得清——图标不再跟随主题色，所以颜色本身必须两边都成立。

启动图标那一组（只给 `nav_home` 用）：奶油白 `#FDF3E7`、琥珀 `#F0A94E`、
赤陶描边 `#C9563B`、心红 `#C0424A`、底色 `#D06A50`。
