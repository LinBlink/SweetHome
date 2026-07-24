# 过家家 · Sweet Home — 后端接口文档

> 版本：v1.0  
> 基础路径：`/api/v1`  
> 协议：HTTP/1.1 + WebSocket

---

## 通用约定

### 请求规范

- Content-Type：`application/json`
- 字符集：`UTF-8`
- 受保护接口须携带请求头：`Authorization: Bearer <jwt_token>`

### 统一响应格式

```json
{
  "code": 200,
  "message": "ok",
  "data": {}
}
```

**错误码说明：**

| code | 说明 |
|------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证或 Token 过期 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 409 | 数据冲突（如手机号已注册） |
| 500 | 服务器内部错误 |

---

## 一、认证服务（Auth Service）

**微服务端口：** 8081  
**网关路由：** `/api/v1/auth/**` → Auth Service

---

### 1.1 注册

**POST** `/auth/register`

注册新用户并自动创建家庭（或通过邀请码加入已有家庭）。

**Request Body（创建新家庭）：**
```json
{
  "name": "王建国",
  "phone": "+8613800138000",
  "password": "password123",
  "gender": "male",
  "familyName": "王家"
}
```

**Request Body（加入已有家庭）：**
```json
{
  "name": "王小明",
  "phone": "+8613800138002",
  "password": "password123",
  "gender": "male",
  "inviteCode": "ABCD1234",
  "relationToMemberId": 1,
  "relationType": "CHILD_OF"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ✅ | 昵称，1-50字 |
| phone | string | ✅ | 手机号，含国家码（如 +8613800138000） |
| password | string | ✅ | 密码，6-20位 |
| gender | string | ✅ | `male` / `female`；亲属称谓计算的基础输入，写入 `family_members.gender` |
| familyName | string | 条件必填 | 创建新家庭时必填 |
| inviteCode | string | 条件必填 | 加入已有家庭时必填；与 familyName 二选一 |
| relationToMemberId | long | 加入家庭时必填 | 关系锚点：`family_members.id`，即"我和家庭里的哪个人有关系"，通常从 `GET /families/lookup` 的成员列表中选取 |
| relationType | string | 加入家庭时必填 | `CHILD_OF`（TA的孩子）/ `PARENT_OF`（TA的父母）/ `SPOUSE_OF`（TA的配偶）/ `SIBLING_OF`（TA的兄弟姐妹），描述新成员相对锚点成员的关系 |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
    "user": {
      "userId": 1,
      "name": "王建国",
      "phone": "+8613800138000",
      "familyId": 1,
      "familyName": "王家",
      "role": "admin"
    }
  }
}
```

**业务逻辑：**
- 提供 `familyName`：创建家庭，当前用户为管理员（role=admin），作为家庭关系图的根节点，不写入任何 `family_relations` 边
- 提供 `inviteCode`：查找对应家庭并加入，role=member；同时根据 `relationToMemberId` + `relationType` 在 `family_relations` 写入关系边：
    - `CHILD_OF` → 写入 `PARENT_OF(锚点, 新成员)`
    - `PARENT_OF` → 写入 `PARENT_OF(新成员, 锚点)`
    - `SPOUSE_OF` → 写入 `SPOUSE_OF(新成员, 锚点)`（规范化 subject/object 顺序）
    - `SIBLING_OF` → 复制锚点现有的全部 `PARENT_OF(父母, 锚点)` 边为 `PARENT_OF(父母, 新成员)`；若锚点当前没有任何已知父母，返回 `409 NO_KNOWN_PARENT`，提示前端引导用户改选其他锚点成员或关系类型
- 注册成功后自动为家庭创建群聊会话（type=group）
- 密码使用 BCrypt 加密存储

---

### 1.2 登录

**POST** `/auth/login`

**Request Body：**
```json
{
  "phone": "+8613800138000",
  "password": "password123"
}
```

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
    "user": {
      "userId": 1,
      "name": "王建国",
      "phone": "+8613800138000",
      "familyId": 1,
      "familyName": "王家",
      "role": "admin"
    }
  }
}
```

**业务逻辑：**
- JWT 有效期：15 分钟
- Refresh Token 有效期：30 天
- Refresh Token 以 SHA-256 哈希值存入 `refresh_tokens` 表

---

### 1.3 刷新 Token

**POST** `/auth/refresh`

**Request Body：**
```json
{
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9..."
  }
}
```

**业务逻辑：**
- 验证 Refresh Token 是否有效且未被吊销
- 返回新 JWT；Refresh Token 本身不轮换（可配置）

---

### 1.4 登出

**POST** `/auth/logout`  
🔒 需要认证

**Request Body：**
```json
{
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**
- 将 `refresh_tokens.revoked_at` 设为当前时间
- 客户端清除本地存储的 token

---

## 二、用户服务（User Service）

**微服务端口：** 8082  
**网关路由：** `/api/v1/users/**` → User Service

---

### 2.1 获取当前用户信息

**GET** `/users/me`  
🔒 需要认证

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "userId": 1,
    "name": "王建国",
    "phone": "+8613800138000",
    "avatarUrl": "https://oss.example.com/avatars/1.jpg",
    "familyId": 1,
    "familyName": "王家",
    "role": "admin",
    "gender": "male",
    "balance": 10000
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| userId | long | 用户 ID |
| name | string | 昵称 |
| phone | string | 手机号 |
| avatarUrl | string | 头像地址；未上传过为 `null` |
| familyId | long | 所在家庭 ID |
| familyName | string | 所在家庭名称 |
| role | string | 在家庭中的角色 `admin` / `member` |
| gender | string | 性别 `male` / `female` |
| balance | long | **用户钱包余额，单位「分」**（`10000` = 100.00 元），用于发红包扣款；前端展示时 `/100` 保留两位小数 |

> 不再返回固定的 `displayRole`；本人视角下的"自称"由客户端固定显示为"我"/"Me"等本地化文案，无需服务端计算（参见 3.2 中 `relationCode: "SELF"` 的约定）。

---

### 2.2 更新用户信息

**PUT** `/users/me`  
🔒 需要认证

**Request Body：**
```json
{
  "name": "王建国",
  "avatarUrl": "https://oss.example.com/avatars/1.jpg"
}
```

**Response：** 返回更新后的用户信息（同 2.1 格式）

---

### 2.3 上传头像

**POST** `/users/upload/avatar`  
🔒 需要认证

**Request：** `multipart/form-data`，字段名 `file`

> 前端需保证上传前已将头像压缩为 webp 等体积较小的格式。

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "addressReturn": "https://<r2-public-base-url>/users/avatars/1/3f2b1c1a-....webp"
  }
}
```

**业务逻辑：**
- 文件存储于 Cloudflare R2（S3 兼容对象存储），对象 key 格式为 `users/avatars/{userId}/{UUID}.{ext}`——每次上传都生成新 UUID，**不删除旧头像**，历史头像文件会残留在存储桶中（已知的空间换简单性权衡）
- 上传成功后同步更新 `users.avatar_url` 为新地址；`addressReturn` 与写入库的值一致
- 校验顺序：未认证 → `401 UNAUTHORIZED`；文件为空 → `400 EMPTY_FILE`；`Content-Type` 不以 `image/` 开头 → `400 FILE_TYPE_ILLEGAL`；文件大小超过 500KB → `400 FILE_SIZE_ILLEGAL`；上传对象存储失败 → `400 FILE_UPLOAD_ERROR`
- 更新后的 `avatarUrl` 会在下次请求会话列表（4.1）、消息历史（4.3）、WebSocket 消息推送（5.2）时体现在对应的 `avatarUrl`/`senderAvatarUrl` 字段里；已经拉取到客户端的旧数据不会被动更新，需要重新拉取

---

### 2.4 上传聊天图片

**POST** `/users/upload/image`
🔒 需要认证

**Request：** `multipart/form-data`，字段名 `file`

> 上传和发消息是两个独立步骤：客户端先调用本接口拿到图片 URL，再用这个 URL 作为 `content`、`type` 传 `"image"`，走 4.4（HTTP
> 兜底）或 5.2（WebSocket）已有的发消息接口，本接口本身**不会**创建任何消息记录。
>
> **前端必须保证上传前已将图片极致压缩为 `webp` 格式**（不是"建议"，是强制要求）——服务端不做任何转码/压缩，上传的是什么格式/体积就原样存到 R2、原样作为 URL 返回，压缩责任完全在客户端。

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "addressReturn": "https://<r2-public-base-url>/users/photos/1/3f2b1c1a-....jpg"
  }
}
```

**业务逻辑：**

- 和 2.3 共用同一个 Cloudflare R2 客户端配置，但对象 key 前缀不同（`users/photos/{userId}/{UUID}.{ext}`，2.3 是
  `users/avatars/...`），并且**不会**写入 `users.avatar_url`——这是一个通用图片上传接口，不是头像接口，上传聊天图片不会连带把用户头像换掉
- 文件大小上限 1MB（比头像的 500KB 宽松，但前端仍必须上传前压缩为 `webp`，不是靠这个上限兜底）
- 校验顺序、错误码与 2.3 一致：未认证 → `401 UNAUTHORIZED`；文件为空 → `400 EMPTY_FILE`；`Content-Type` 不以 `image/` 开头 →
  `400 FILE_TYPE_ILLEGAL`；超过大小上限 → `400 FILE_SIZE_ILLEGAL`；上传对象存储失败 → `400 FILE_UPLOAD_ERROR`

---

### 2.5 上传视频

**POST** `/users/upload/video`
🔒 需要认证

**Request：** `multipart/form-data`，字段名 `file`

> 供家庭动态（七、Moment Service）发布视频动态使用，用法同 2.4：先上传拿到 URL，再把 URL 作为 `moment_media` 里一项的 `content` 传给 7.1 发布动态接口。
>
> **前端必须保证上传前已将视频极致压缩为 `mp4` 格式**（强制要求，非建议）——服务端不做任何转码/压缩，原样存储、原样返回 URL。

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "addressReturn": "https://<r2-public-base-url>/users/videos/1/3f2b1c1a-....mp4"
  }
}
```

**业务逻辑：**

- 对象 key 格式 `users/videos/{userId}/{UUID}.{ext}`，不写入 `users.avatar_url`
- 文件大小上限 50MB
- 校验顺序、错误码同 2.4：未认证 → `401 UNAUTHORIZED`；文件为空 → `400 EMPTY_FILE`；`Content-Type` 不以 `video/` 开头 →
  `400 FILE_TYPE_ILLEGAL`；超过大小上限 → `400 FILE_SIZE_ILLEGAL`；上传对象存储失败 → `400 FILE_UPLOAD_ERROR`

---

### 2.6 上传语音

**POST** `/users/upload/audio`
🔒 需要认证

**Request：** `multipart/form-data`，字段名 `file`

> **前端必须保证上传前已将语音极致压缩为 `opus` 格式**（强制要求，非建议）——服务端不做任何转码/压缩，原样存储、原样返回 URL。

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "addressReturn": "https://<r2-public-base-url>/users/audios/1/3f2b1c1a-....opus"
  }
}
```

**业务逻辑：**

- 对象 key 格式 `users/audios/{userId}/{UUID}.{ext}`，不写入 `users.avatar_url`
- 文件大小上限 10MB
- 校验顺序、错误码同 2.4：未认证 → `401 UNAUTHORIZED`；文件为空 → `400 EMPTY_FILE`；`Content-Type` 不以 `audio/` 开头 →
  `400 FILE_TYPE_ILLEGAL`；超过大小上限 → `400 FILE_SIZE_ILLEGAL`；上传对象存储失败 → `400 FILE_UPLOAD_ERROR`

---

### 2.7 注册 / 注销推送 Token（极光推送）

> 用途：让手机在 App 被杀死/后台时也能收到告警类通知（目前唯一的消费场景是 6.7 的电子围栏越界告警）。服务端集成的是**极光推送（JPush）**，走的是 JPush 官方 Java SDK 的服务端下发能力，不是自建的 FCM/APNs 直连——这意味着 Flutter 客户端也必须接极光的 `jpush_flutter` 官方插件，而不是 Firebase Messaging 之类的其他推送 SDK，两边的 `registrationId` 才能对上。

**接入顺序（客户端必须严格按这个顺序）：**
1. App 启动后调用 `jpush_flutter` 的 `JPush().setup(appKey: <极光 AppKey>, channel: ..., production: ...)` 初始化 SDK（`appKey` 需要和后端 `.env` 里的 `JPUSH_APP_KEY` 是**同一个** JPush 控制台应用，两边配的不是同一个 App 会导致推送完全发不到）
2. 监听 `JPush().getRegistrationID()` 拿到本机的 `registrationId`（这是 JPush SDK 生成的、标识"这台设备上的这次安装"的字符串，跟 userId 无关，App 卸载重装/清除数据后会变成一个新的值）
3. 用户登录成功后（此时已经有 JWT），调用下面的 **2.7.1** 把 `registrationId` 上报给后端存起来
4. 用户登出前，调用 **2.7.2** 把这条记录删掉，避免登出之后这台设备还继续收到"上一个登录用户"的告警通知

> ```
> JGTS_APP_KEY: fcc5dc2e3bbda150d02bdc26
> JGTS_MASTER_SECRET: 673899724cb553865ac09d29
> ```

#### 2.7.1 注册推送 Token

**POST** `/users/push-token`
🔒 需要认证

**Request Body：**
```json
{
  "registrationId": "1a0018970e70b6b1234",
  "platform": "android"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| registrationId | string | ✅ | `jpush_flutter` SDK 本机生成的推送标识，原样透传，不要自己拼接或截断 |
| platform | string | ✅ | `android` / `ios`，仅作记录用途，服务端当前推送时按 `Platform.all()` 全平台格式下发（因为已经是按单台设备的 `registrationId` 精确投递了，不需要用 `platform` 做二次筛选），暂不依赖这个字段做业务判断 |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**
- 幂等 + 设备换绑：`registrationId` 在 `push_tokens` 表里是唯一的业务键（同一台设备任意时刻只能属于一个用户）——
    - 这个 `registrationId` 从未出现过 → 新建一条记录，绑定到当前登录用户
    - 已存在（不管之前绑的是当前用户自己还是别的家庭成员）→ 直接把这条记录的 `userId` 更新为当前登录用户
- **典型场景**：家里的平板先后被爸爸、妈妈登录过，两次都调用过这个接口——数据库里这台设备的记录始终只有一条，`userId` 跟随"最后一次登录成功的人"，不会同一台设备被判定成"属于两个人"从而给不该收到通知的人推送
- 因此**客户端每次登录成功后都应该调用这个接口**（哪怕 `registrationId` 没变），而不是只在第一次安装时调用一次——这是保证换绑及时生效的关键

#### 2.7.2 注销推送 Token

**DELETE** `/users/push-token`
🔒 需要认证

**Request Body：**
```json
{
  "registrationId": "1a0018970e70b6b1234"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| registrationId | string | ✅ | 要注销的设备标识，同 2.7.1 |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**
- 只会删除**当前登录用户名下、且 `registrationId` 匹配**的那一条记录——不能删除不属于自己的记录（即便知道别人设备的 `registrationId` 也删不掉，服务端会按 `userId + registrationId` 一起校验，查不到就静默忽略，不报错）
- 客户端应在**用户主动登出**时调用（不是 App 被系统杀后台时调用——那种情况没有机会执行代码）；不调用也不是致命问题，最坏后果是登出后这台设备可能还会收到"上一个用户"的告警推送，直到有新用户在这台设备登录顶替掉这条记录（见 2.7.1 的换绑逻辑）

---

## 三、家庭服务（Family Service）

**微服务端口：** 8083  
**网关路由：** `/api/v1/families/**` → Family Service

---

### 3.0 通过邀请码预览家庭

**GET** `/families/lookup?inviteCode=XXX`

> 无需认证。用于"加入已有家庭"注册流程：用户输入邀请码后，先预览该家庭的成员列表，再选择自己与哪位成员存在何种关系（见 1.1 的 `relationToMemberId`/`relationType`），供 `POST /auth/register` 使用。

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "familyId": 1,
    "familyName": "王家",
    "members": [
      { "memberId": 1, "name": "王建国", "gender": "male", "avatarUrl": null },
      { "memberId": 2, "name": "张美玲", "gender": "female", "avatarUrl": null }
    ]
  }
}
```

**业务逻辑：**
- 邀请码不存在或已过期：返回 `404 INVITE_CODE_INVALID`
- 出于隐私考虑，此接口不返回手机号等敏感信息

---

### 3.1 获取家庭详情

**GET** `/families/{familyId}`  
🔒 需要认证，且当前用户必须是该家庭成员

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "familyId": 1,
    "name": "王家",
    "memberCount": 6,
    "createdAt": "2026-01-01T10:00:00.000Z"
  }
}
```

---

### 3.2 获取家庭成员列表

**GET** `/families/{familyId}/members`  
🔒 需要认证，且当前用户必须是该家庭成员

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "userId": 1,
      "memberId": 11,
      "name": "王建国",
      "gender": "male",
      "relationCode": "SELF",
      "avatarUrl": null,
      "isOnline": true,
      "role": "admin"
    },
    {
      "userId": 2,
      "memberId": 12,
      "name": "张美玲",
      "gender": "female",
      "relationCode": "S",
      "avatarUrl": null,
      "isOnline": false,
      "role": "member"
    }
  ]
}
```

| 字段 | 说明 |
|------|------|
| relationCode | 语言无关的规范亲属路径（如 `SELF`、`F`、`F.F`、`S.eB`），由「十、亲属称谓计算算法」推导 |

**业务逻辑：**
- `relationCode` 是**相对于当前请求用户**逐请求动态计算的，不存储、不缓存——同一个成员列表，不同用户请求会得到不同的 `relationCode`（如爷爷请求时儿子的 `relationCode` 是 `Son`，孙辈请求时同一个人是 `F`）
- **服务端只产出语言无关的 `relationCode`，不做任何本地化翻译**——把 `relationCode` 翻译成人类可读文案（"儿子""爸爸"……）完全是客户端职责，官方 Flutter 客户端在 `lib/core/kinship/terms/*.dart` 里维护 6 语言的称谓词表并在渲染时实时翻译，永远不依赖服务端返回的语言。这样后端不需要处理 `Accept-Language`、不需要维护多语言词表、也不用担心不同语言版本的算法实现不一致。算法本身（第十节）后端和客户端仍需各自实现一份、产出相同的 `relationCode`，只是"码→文案"这一步只在客户端做
- 不再返回固定的 `displayRole`/`avatarLabel`/`relationLabel` 字段（原设计为所有查看者返回相同文本、或由服务端本地化，均已废弃，见 docs/schema.sql 中 `family_members.display_role` 的移除说明）

---

### 3.3 生成邀请码

**POST** `/families/{familyId}/invite`  
🔒 需要认证，且当前用户必须是该家庭的管理员（role=admin）

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "inviteCode": "ABCD1234",
    "expiresAt": "2026-07-01T10:00:00.000Z"
  }
}
```

**业务逻辑：**
- 邀请码长度 8 位，大写字母 + 数字
- 有效期 48 小时
- 已存在未过期的邀请码时直接返回现有邀请码

---

### 3.4 通过邀请码加入家庭

**POST** `/families/join`  
🔒 需要认证

> 与 1.1 注册接口的"加入已有家庭"模式共用同一套关系写入逻辑（`FamiliesServiceImpl.joinFamily`）——区别只是这里的用户已经登录、`userId` 从 JWT 中取得，不需要再创建 `users` 记录。`gender`/`relationToMemberId`/`relationType` 语义与 1.1 完全一致，同样是必填字段：`family_members.gender`/关系锚点是按每次加入的家庭单独记录的，不能省略。
>
> **同一时刻只能属于一个家庭**：调用此接口成功后，用户会自动退出原来所在的家庭（若有），详见下方业务逻辑的"退出旧家庭"级联规则——不支持真正的多家庭并存。

**Request Body：**
```json
{
  "inviteCode": "ABCD1234",
  "gender": "male",
  "relationToMemberId": 1,
  "relationType": "CHILD_OF"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| inviteCode | string | ✅ | 家庭邀请码 |
| gender | string | ✅ | `male` / `female`；写入本次加入产生的 `family_members.gender` |
| relationToMemberId | long | ✅ | 关系锚点：`family_members.id`，通常从家庭成员列表或 `GET /families/lookup` 的结果中选取 |
| relationType | string | ✅ | `CHILD_OF`（TA的孩子）/ `PARENT_OF`（TA的父母）/ `SPOUSE_OF`（TA的配偶）/ `SIBLING_OF`（TA的兄弟姐妹） |

**Response：** 返回加入的家庭信息（同 3.1 格式）

**业务逻辑：**
- 验证邀请码有效性和时效
- **退出旧家庭（级联，先于加入新家庭执行，同一事务）**：一个用户同一时刻只能属于一个家庭。查询该用户当前未软删除的 `family_members` 记录（正常情况下至多一条）：
    1. 软删除该记录（`deleted_at = now`）
    2. 软删除该成员在旧家庭图中的全部 `family_relations` 边（作为 `subject_member_id` 或 `object_member_id` 出现的，均设 `deleted_at = now`），避免残留边污染其他成员之后的称谓计算
    3. 退出旧家庭的群聊：`conversations WHERE family_id=旧family_id AND type='group'` 对应的 `conversation_members` 记录设 `left_at = now`；不影响与旧家庭成员之间已存在的私聊（`type='direct'`）——聊天记录不因家庭归属变化而清空
    4. 若被软删除的记录 `role='admin'`：旧家庭剩余未软删除成员按 `joined_at` 升序取第一条自动转正为 `admin`；若已无任何活跃成员，连带软删除 `families` 记录本身（`created_by` 保持不变，仅作历史记录）
- 将用户加入新家庭（`family_members`，`role=member`）
- 根据 `relationToMemberId` + `relationType` 写入 `family_relations` 边，规则与 1.1 完全一致：
    - `CHILD_OF` → 写入 `PARENT_OF(锚点, 新成员)`；若锚点已有配偶（`SPOUSE_OF`），额外写入 `PARENT_OF(锚点的配偶, 新成员)`，避免配偶视角计算出的称谓退化成"配偶的儿子"
    - `PARENT_OF` → 写入 `PARENT_OF(新成员, 锚点)`
    - `SPOUSE_OF` → 写入 `SPOUSE_OF(新成员, 锚点)`（规范化 subject/object 顺序）；锚点已有配偶时返回 `409 SPOUSE_ALREADY_EXISTS`
    - `SIBLING_OF` → 复制锚点现有的全部 `PARENT_OF(父母, 锚点)` 边为 `PARENT_OF(父母, 新成员)`；锚点没有已知父母时返回 `409 NO_KNOWN_PARENT`
- `relationToMemberId` 必须属于邀请码对应的家庭，否则返回 `404 INVALID_RELATION_ANCHOR`
- 将用户加入新家庭群聊（conversation_members）

---

### 3.5 申请加入家庭（没有邀请码）

> 3.4 要求申请人已经拿到邀请码。如果申请人不知道邀请码、但知道自己想加入的家庭里某位成员的手机号（比如"我知道我爸的手机号，但没问他要邀请码"），可以走这套"申请—审批"流程：申请人提交申请，家庭管理员在 App 内查看待处理列表并批准/拒绝，批准后才真正创建账号并加入家庭。全程不需要邀请码。

#### 3.5.1 提交加入申请

**POST** `/families/join-requests`

> 公开接口，无需认证（申请人此时还没有账号）。

**Request Body：**
```json
{
  "name": "王小明",
  "phone": "+8613800138099",
  "password": "password123",
  "gender": "male",
  "targetMemberPhone": "+8613800138000",
  "relationType": "CHILD_OF",
  "message": "我是建国的儿子，想加入家庭群"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name / phone / password / gender | - | ✅ | 与 1.1 注册接口含义相同，审批通过后用于创建账号 |
| targetMemberPhone | string | ✅ | 申请人认识的、已在目标家庭里的成员手机号，用于定位家庭和关系锚点 |
| relationType | string | ✅ | `CHILD_OF`/`PARENT_OF`/`SPOUSE_OF`/`SIBLING_OF`，语义同 1.1，相对 `targetMemberPhone` 对应的成员而言 |
| message | string | 否 | 留言，供管理员审批参考，最长 200 字 |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": { "requestId": 1, "status": "pending" }
}
```

**业务逻辑：**
- 按 `targetMemberPhone` 查找对应用户及其未软删除的 `family_members` 记录，找不到返回 `404 TARGET_MEMBER_NOT_FOUND`
- `phone` 不能是已注册手机号，否则返回 `409 PHONE_ALREADY_REGISTERED`（这种情况下申请人应该直接登录，走 3.4「登录后加入其他家庭」）
- 写入 `family_join_requests`，`status=pending`；`family_id`/`target_member_id` 由 `targetMemberPhone` 反查得到
- 密码此时即按 BCrypt 加密存储在申请记录里，审批通过时直接复用，不要求申请人二次输入
- 通知家庭管理员有新申请待审批的具体机制（站内提醒/推送）超出本接口范围，客户端通过 3.5.2 轮询或登录时拉取

#### 3.5.2 查看待处理的加入申请

**GET** `/families/{familyId}/join-requests?status=pending`  
🔒 需要认证，且当前用户必须是该家庭的管理员（`role=admin`）

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "requestId": 1,
      "requesterName": "王小明",
      "requesterPhone": "+8613800138099",
      "requesterGender": "male",
      "relationType": "CHILD_OF",
      "targetMemberName": "王建国",
      "message": "我是建国的儿子，想加入家庭群",
      "createdAt": "2026-07-02T10:00:00.000Z"
    }
  ]
}
```

#### 3.5.3 批准 / 拒绝加入申请

**POST** `/families/join-requests/{requestId}/approve`  
**POST** `/families/join-requests/{requestId}/reject`  
🔒 均需要认证，且当前用户必须是该家庭的管理员

`reject` 的 **Request Body**（可选）：`{ "reason": "暂不确定身份" }`

**Response：** `{ "requestId": 1, "status": "approved" }` 或 `{ "requestId": 1, "status": "rejected" }`

**批准的业务逻辑：**
- 校验 `requestId` 存在且 `status=pending`，否则 `409 REQUEST_ALREADY_RESOLVED`
- 创建 `users` 记录（申请时提交的 name/phone/password_hash）
- 按申请里的 `relationType` 写 `family_relations`，规则与 3.4 完全一致（`CHILD_OF` 同样需要给 `target_member` 的配偶补边、`SIBLING_OF` 同样要求 `target_member` 有已知父母，否则 `409 NO_KNOWN_PARENT`）
- 写入 `family_members`（`role=member`），加入家庭群聊
- `family_join_requests.status='approved'`，`resolved_at`/`resolved_by` 写入
- 不直接返回申请人的登录态（token），申请人需要自己用刚提交的手机号+密码登录——审批操作发生在管理员的会话里，不应该把申请人的凭据/token 暴露给管理员

**拒绝的业务逻辑：**
- 仅更新 `family_join_requests.status='rejected'`，记录 `resolved_at`/`resolved_by`，不创建任何账号或家庭数据

---

## 四、聊天服务（Chat Service）

**微服务端口：** 8084  
**网关路由：** `/api/v1/conversations/**` → Chat Service

---

### 4.1 获取会话列表

**GET** `/conversations`  
🔒 需要认证

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 1,
      "type": "group",
      "name": "王家群聊",
      "familyId": 1,
      "avatarLabel": "家",
      "avatarColor": "FFBF5E3B",
      "avatarUrl": null,
      "lastMessage": "晚饭准备好了，快回家吃饭！",
      "lastMessageType": "text",
      "lastMessageAt": "2026-06-29T18:30:00.000Z",
      "unreadCount": 5,
      "memberCount": 6
    },
    {
      "id": 2,
      "type": "direct",
      "name": "张美玲",
      "familyId": 1,
      "avatarLabel": "张",
      "avatarColor": "FFF4A261",
      "avatarUrl": "https://<r2-public-base-url>/users/avatars/2/....webp",
      "relationCode": "S",
      "otherUserGender": "female",
      "otherUserId": 2,
      "lastMessage": "https://<r2-public-base-url>/users/photos/2/....jpg",
      "lastMessageType": "image",
      "lastMessageAt": "2026-06-29T17:00:00.000Z",
      "unreadCount": 1,
      "memberCount": 2
    }
  ]
}
```

| 字段              | 说明                                                                                                                                                                          |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| avatarLabel     | 纯视觉标识，取对方姓名首字，不再语义化为称谓（原先固定塞"妈"这种绝对称谓，容易和头像圆圈只能显示单字冲突，也不支持国际化）                                                                                                              |
| avatarUrl       | 用户上传过的头像图片地址（见 2.3）；未上传过头像时为 `null`，客户端应回退显示 `avatarLabel` + `avatarColor` 的文字头像。`type=group` 时目前恒为 `null`（群聊头像固定用"家"字占位，不取任何成员头像）                                          |
| relationCode    | 仅 `type=direct` 时返回：对方相对于当前请求用户的语言无关称谓码，语义/计算方式同 3.2。**服务端不返回本地化后的文案**——客户端拿到 `relationCode` + `otherUserGender` 后在渲染时自行翻译（如展示在会话标题旁"张美玲 · 妻子"），`name` 字段本身不再拼接"（妈妈）"这类固定后缀 |
| otherUserGender | 仅 `type=direct` 时返回：对方的性别，客户端本地化 `relationCode` 时用来判断裸配偶码（`"S"`）该显示"丈夫"还是"妻子"                                                                                               |
| otherUserId     | 仅 `type=direct` 时返回：对方的 `user_id`，供客户端将 §5.2 WS `USER_STATUS` 推送里的 `userId` 与具体会话对上号，渲染在线状态指示。`type=group` 时为 `null`（一个群聊对应多个成员，不存在单一"对方"）                                  |
| lastMessage     | 最后一条消息的原始 `content`——**图片/语音消息这里是原始 OSS URL，不是占位文案**。服务端不做"图片消息显示成 [图片]"这种转换（同 `relationCode` 的设计原则：服务端只给结构化数据，不做展示层加工），客户端要结合下面的 `lastMessageType` 自行决定怎么显示                |
| lastMessageType | 最后一条消息的类型：`text`/`image`/`voice`/`audio`/`video`/`system`/`redpacket`。客户端据此判断 `lastMessage` 是纯文本还是 URL/红包 id，`type != "text"` 时应显示本地化占位文案（如"[图片]"/"[Photo]"、`redpacket` 显示"[红包]"），而不是把 URL/红包 id 原样展示给用户                                 |

**业务逻辑：**
- 返回当前用户参与的所有会话
- 按 `lastMessageAt` 降序排列
- `unreadCount` = 当前会话中 `messages.id > conversation_members.last_read_message_id` 的数量

---

### 4.2 创建私聊会话

**POST** `/conversations`  
🔒 需要认证

**Request Body：**
```json
{
  "targetUserId": 2
}
```

**Response：** 返回会话信息（同 4.1 中单条格式）

**业务逻辑：**
- 幂等：若两人之间的私聊会话已存在，直接返回现有会话
- 创建时自动将双方加入 `conversation_members`

---

### 4.3 获取消息历史

**GET** `/conversations/{conversationId}/messages`  
🔒 需要认证，且当前用户必须是该会话成员

**Query Parameters：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 每页数量，默认 50，最大 100 |
| before | long | 否 | 游标：返回此消息 ID 之前的消息（不含此 ID） |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "messages": [
      {
        "id": 123,
        "clientId": "550e8400-e29b-41d4-a716-446655440000",
        "conversationId": 1,
        "senderId": 2,
        "senderName": "张美玲",
        "senderAvatarLabel": "张",
        "senderAvatarUrl": "https://<r2-public-base-url>/users/avatars/2/....webp",
        "senderRelationCode": "S",
        "senderGender": "female",
        "content": "晚饭准备好了，快回家吃饭！",
        "type": "text",
        "sentAt": "2026-06-29T18:30:00.000Z"
      }
    ],
    "hasMore": true,
    "nextCursor": 120
  }
}
```

**业务逻辑：**
- 查询条件：`conversation_id = ? AND id < before AND deleted_at IS NULL`
- 排序：`id DESC`（最新消息在前）
- 客户端以 `reverse: true` 列表展示，滚动到顶部时用 `nextCursor` 加载更多
- `senderAvatarLabel` 为发送者姓名首字（纯头像视觉标识）；`senderAvatarUrl` 为发送者上传过的头像图片地址（见 2.3），未上传过头像时为 `null`，客户端应回退显示 `senderAvatarLabel`；`senderRelationCode` 为发送者相对于当前请求用户（消息接收方）的语言无关称谓码，语义与 3.2 一致，逐请求动态计算，群聊中同一条消息返回给不同成员时 `senderRelationCode` 可能不同；`senderGender` 用于客户端本地化裸配偶码。**服务端不做任何本地化，只产出 code + gender，翻译成文案是客户端职责**

---

### 4.4 发送消息（HTTP 兜底接口）

**POST** `/conversations/{conversationId}/messages`  
🔒 需要认证，且当前用户必须是该会话成员

> 正常情况下消息通过 WebSocket 发送；此接口作为 WebSocket 断线时的降级兜底。

**Request Body（文本消息）：**
```json
{
  "content": "晚饭好了！",
  "type": "text",
  "clientId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Request Body（图片消息）：**

```json
{
  "content": "https://<r2-public-base-url>/users/photos/1/3f2b1c1a-....jpg",
  "type": "image",
  "clientId": "660e8400-e29b-41d4-a716-446655440001"
}
```

> `content` 直接就是 2.4 上传接口返回的 `addressReturn`，原样传过来，服务端不做二次处理、不重新上传、不校验这个 URL
> 是否真实可访问——发消息接口只是把这个字符串存进 `messages.content`。

**Request Body（红包消息）：**

```json
{
  "content": "1001",
  "type": "redpacket",
  "clientId": "770e8400-e29b-41d4-a716-446655440002"
}
```

> **发红包的完整流程（两步）：** ① 先调 `POST /redpacket`（见 9.1）创建红包，拿到红包 `id`；② 再走本接口（或 5.2 WebSocket）发一条 `type=redpacket`、`content=红包id` 的消息，会话成员即可在聊天流里看到红包卡片。收到 `type=redpacket` 的消息后，客户端用 `content`（红包 id）调 `GET /redpacket/{id}`（9.2）渲染红包状态、调「抢红包」（9.3）领取。服务端只把红包 id 当普通文本存进 `messages.content`，不做任何红包逻辑校验——真正的成员校验/状态判断在红包接口里做。

| 字段       | 类型     | 必填 | 说明                                                                                                            |
|----------|--------|----|---------------------------------------------------------------------------------------------------------------|
| content  | string | ✅  | `type=text` 时是消息文本；`type=image`/`voice` 时是一个完整的 OSS/R2 URL（图片先调 2.4 上传换到这个 URL，再作为 `content` 传到这里，两步是分开的两次请求）；**`type=redpacket` 时是红包 id（字符串形式）** |
| type     | string | ✅  | `text`/`image`/`voice`/`audio`/`video`/`system`/`redpacket` 之一，不在白名单内返回 `400 INVALID_MESSAGE_TYPE`（`redpacket` 用于发红包，见 9.1 说明） |
| clientId | string | ✅  | 客户端生成的 UUID，用于去重                                                                                              |

**Response：** 返回服务端确认后的消息对象（同 4.3 中单条格式）

**业务逻辑：**
- `clientId` 去重：若 `messages.client_id = ?` 已存在，返回已存在的消息（幂等）
- 消息写入后，通过 Redis Pub/Sub 通知所有订阅该会话 WebSocket 连接的服务实例推送给成员
- 更新 `conversations.last_message_id` 和 `conversations.last_message_at`

---

### 4.5 标记已读

**PUT** `/conversations/{conversationId}/read`  
🔒 需要认证

**Request Body：**
```json
{
  "lastReadMessageId": 123
}
```

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**
- 更新 `conversation_members.last_read_message_id` 和 `last_read_at`

---

## 五、WebSocket 接口

**连接地址：** `ws[s]://<gateway>/api/v1/ws?token=<jwt>`

**认证：** Token 通过 Query Parameter 传递（浏览器 WebSocket API 不支持自定义 Header）

**Spring Boot 实现：** 使用原始 `TextWebSocketHandler`（非 STOMP），路由 `/api/v1/ws`

---

### 5.1 多实例 WebSocket 架构

```
Flutter Client → API Gateway → Chat Service 实例 A
                             ↘ Chat Service 实例 B
                             ↘ Chat Service 实例 C
                                      ↕
                              Redis Pub/Sub
                         (Channel: conv:<conversationId>)
```

- 每个 Chat Service 实例在内存中维护 `Map<userId, WebSocketSession>`
- 收到消息后，向 Redis 发布 `conv:<conversationId>` 频道
- 所有实例订阅该频道，各自向本地持有该用户连接的 Session 推送

---

### 5.2 消息帧格式

所有帧均为 JSON 字符串。

#### 客户端 → 服务端（Outbound）

**发送消息（文本）**
```json
{
  "type": "SEND_MESSAGE",
  "conversationId": 1,
  "content": "晚饭好了！",
  "messageType": "TEXT",
  "clientId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**发送消息（图片）**

```json
{
  "type": "SEND_MESSAGE",
  "conversationId": 1,
  "content": "https://<r2-public-base-url>/users/photos/1/3f2b1c1a-....jpg",
  "messageType": "IMAGE",
  "clientId": "660e8400-e29b-41d4-a716-446655440001"
}
```

**发送消息（红包）**

```json
{
  "type": "SEND_MESSAGE",
  "conversationId": 1,
  "content": "1001",
  "messageType": "REDPACKET",
  "clientId": "770e8400-e29b-41d4-a716-446655440002"
}
```

> 语义同 4.4 的红包消息：先调 `POST /redpacket`（9.1）拿到红包 id，再发一条 `messageType=REDPACKET`、`content=红包id` 的消息。接收方按 `messageType` 分支，`REDPACKET` 时用 `content`（红包 id）调 9.2/9.3 渲染与领取。

> `content` 同样是先调 `POST /users/upload/image`（2.4）拿到的 URL，WebSocket 这条路径不接收/不处理图片二进制数据本身，只传字符串。
`messageType` 大小写不敏感，且服务端遇到无法识别的值目前会**静默**当作 `TEXT` 处理（不会报错拒绝，这点和 4.4 REST 接口的"
> 直接拒绝非法 type"行为不一致，是已知的待办事项）。

**进入会话（用于服务端计算活跃会话）**
```json
{
  "type": "JOIN_CONVERSATION",
  "conversationId": 1
}
```

**标记已读**
```json
{
  "type": "READ",
  "conversationId": 1,
  "lastReadMessageId": 123
}
```

**心跳**
```json
{
  "type": "PING"
}
```

#### 服务端 → 客户端（Inbound）

**新消息推送**
```json
{
  "type": "NEW_MESSAGE",
  "data": {
    "id": 124,
    "clientId": "550e8400-e29b-41d4-a716-446655440000",
    "conversationId": 1,
    "senderId": 2,
    "senderName": "张美玲",
    "senderAvatarLabel": "张",
    "senderAvatarUrl": "https://<r2-public-base-url>/users/avatars/2/....webp",
    "senderRelationCode": "S",
    "senderGender": "female",
    "content": "晚饭好了！",
    "messageType": "TEXT",
    "sentAt": "2026-06-29T18:30:00.000Z"
  }
}
```

`senderAvatarUrl`/`senderRelationCode`/`senderGender` 语义同 4.3；服务端向每个订阅该会话的连接推送时，`senderRelationCode`
需按各自连接所属用户分别计算（同一条消息推给不同成员时这个字段可能不同，不能只算一次广播）——但计算到 `relationCode`
为止即可，不需要本地化，本地化在客户端收到推送后渲染时进行。`messageType="IMAGE"` 时 `content` 同样是 R2 图片
URL（不是文本），客户端渲染这条推送时要按 `messageType` 分支处理，不能无脑当文本显示。

**用户在线状态变更**
```json
{
  "type": "USER_STATUS",
  "data": {
    "userId": 2,
    "status": "online"
  }
}
```

**心跳响应**
```json
{
  "type": "PONG"
}
```

**错误推送**
```json
{
  "type": "ERROR",
  "data": {
    "code": "TOKEN_EXPIRED",
    "message": "令牌已过期，请重新登录"
  }
}
```

**常见错误码：**

| code | 说明 |
|------|------|
| TOKEN_EXPIRED | JWT 已过期 |
| UNAUTHORIZED | 无权访问该会话 |
| CONNECTION_FAILED | 连接建立失败 |
| MESSAGE_TOO_LONG | 消息内容超长（上限 2000 字符） |

---

### 5.3 客户端重连策略

| 重试次数 | 等待时间 |
|---------|---------|
| 第 1 次 | 1 秒 |
| 第 2 次 | 2 秒 |
| 第 3 次 | 4 秒 |
| 第 4 次 | 8 秒 |
| 第 5 次 | 16 秒 |
| 第 6 次 | 30 秒 |
| 超过 6 次 | 停止重试，提示用户检查网络 |

---

## 六、位置共享服务（Location Service）

**微服务端口：** 8085
**网关路由：** `/api/v1/location/**` → Location Service

> 目的：家庭成员（尤其是老人、小孩）位置安全共享。当前实现覆盖"上报当前位置"和"查看家庭成员位置"两个核心接口；轨迹历史回放、电子围栏报警、步数统计等属于本模块的后续规划，暂未实现。

---

### 6.1 上报当前位置

**POST** `/location/report`
🔒 需要认证

**Request Body：**
```json
{
  "lng": 116.397128,
  "lat": 39.916527,
  "battery": 76,
  "updateTime": "2026-07-13T18:00:00.000Z"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| lng | double | ✅ | 经度 |
| lat | double | ✅ | 纬度 |
| battery | int | 否 | 手机电量百分比（0-100）；采集不到时不传，服务端记为 `-1` |
| updateTime | datetime | ✅ | 客户端采集该定位数据时的本地时间戳（不是请求到达服务端的时间），服务端用它判断数据是否过期 |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**
- 校验顺序：`lng`/`lat` 任一为空 → `400 LOCATION_COORDINATE_INVALID`；`battery` 超过 100 → `400 LOCATION_BATTERY_INVALID`；`updateTime` 为空 → `400 LOCATION_TIMESTAMP_MISSING`
- 时间戳偏差校验：`|服务端当前时间 - updateTime| > 120秒` 时记一条 `warn` 日志（疑似网络延迟或设备时钟不准，不阻断请求）；超过 600 秒（10 分钟）判定数据过期，拒绝写入并返回 `400 LOCATION_TIMESTAMP_STALE`
- `familyId` 不接受前端传入，服务端通过 Dubbo 调用 `FamilyApi.getFamilyByUserId(userId)` 反查，避免伪造；用户不属于任何家庭时该调用直接抛 `404 NO_SUCH_FAMILY_MEMBER`
- **双写**：先写 Redis（key: `location:current:<userId>`，TTL 10 分钟，值为当前位置 JSON），再写 MySQL `location` 表（一条落库记录，作为轨迹历史日志）。MySQL 写入失败仅记录日志、不回滚 Redis、不影响本次请求的成功响应——两份数据服务不同的读路径（Redis 服务"实时地图"，MySQL 服务未来的"历史轨迹回放"），MySQL 侧偶发丢失可接受，不做分布式事务保证
- 上报频率约定（客户端职责，服务端不强制校验）：约每分钟采集一次

---

### 6.2 获取家庭成员位置

**GET** `/location/family`
🔒 需要认证，返回当前用户所在家庭的所有成员位置信息

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "familyId": 1,
    "familyName": "王家",
    "onlineMemberCount": 2,
    "totalMemberCount": 3,
    "familyMemberLocations": [
      {
        "userId": 1,
        "username": "王建国",
        "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/1/....webp",
        "lng": 116.397128,
        "lat": 39.916527,
        "battery": 76,
        "updatedAt": "2026-07-13T18:00:00.000Z"
      }
    ]
  }
}
```

| 字段 | 说明 |
|------|------|
| onlineMemberCount | 10 分钟内上报过位置的成员数（即 Redis 中 `location:current:<userId>` 是否存在），**不是**设备/App 在线状态 |
| totalMemberCount | 家庭成员总数（不含已退出家庭的成员） |
| familyMemberLocations | 仅包含"当前有位置数据"（Redis 里存在对应 key）的成员；长期未上报位置的成员不会出现在这个列表里，客户端可用 `totalMemberCount - familyMemberLocations.length` 提示"N 位成员暂无位置数据" |

**业务逻辑：**
- `familyId` 同样通过 `FamilyApi.getFamilyByUserId(userId)` 反查
- 家庭成员名单通过 `FamilyApi.getFamilyMembersByFamilyId(familyId)` 获取（已自动过滤退出/被移除的软删除成员）
- 逐个成员查 Redis 判断是否有当前位置数据，没有则跳过（不计入返回列表，但仍计入 `totalMemberCount`）

---

### 6.3 获取某个成员某一天的历史轨迹

**GET** `/location/{targetUserId}/history?date=2026-07-14`
🔒 需要认证，且 `targetUserId` 必须和当前用户在同一家庭（家庭内任何成员都能查看其他成员的轨迹，不限管理员）

| 参数           | 类型     | 必填      | 说明                                   |
|--------------|--------|---------|--------------------------------------|
| targetUserId | long   | ✅（路径参数） | 要查询轨迹的用户 id，可以是自己，也可以是同一家庭的其他成员      |
| date         | string | ✅       | 查询日期，格式 `yyyy-MM-dd`，返回该用户这一天全部的定位记录 |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "familyId": 1,
    "familyName": "王家",
    "userId": 2,
    "username": "张美玲",
    "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/2/....webp",
    "locations": [
      { "lng": 116.397128, "lat": 39.916527, "battery": 82, "updatedAt": "2026-07-14T08:00:00.000Z" },
      { "lng": 116.398201, "lat": 39.917013, "battery": 80, "updatedAt": "2026-07-14T08:01:00.000Z" }
    ]
  }
}
```

**业务逻辑：**

- 数据来源为 MySQL `location` 日志表（按 60 秒固定频率上报落库的历史记录），**不是** Redis 里的当前位置——`locations` 按
  `updatedAt` 升序返回当天全部原始点，暂不做抽稀/降采样
- 权限校验：查询者与 `targetUserId` 必须属于同一家庭，否则返回 `403 LOCATION_TARGET_NOT_FAMILY_MEMBER`（防止任意用户跨家庭查询他人行踪）
- 当天没有任何上报记录时，`locations` 返回空数组，不是错误

---

### 6.4 创建电子围栏

**POST** `/location/fence`
🔒 需要认证，家庭内任何成员都能给同一家庭的任何成员（包括自己）设置围栏

> 目前只支持**圆形围栏**（中心点 + 半径），不支持自定义多边形。

**Request Body：**

```json
{
  "name": "学校",
  "targetUserId": 3,
  "fenceLng": 116.397128,
  "fenceLat": 39.916527,
  "fenceRange": 200
}
```

| 字段           | 类型     | 必填 | 说明                     |
|--------------|--------|----|------------------------|
| name         | string | 否  | 围栏名称，方便前端展示，如"学校""家附近" |
| targetUserId | long   | ✅  | 被监护人的用户 id，必须和设置者同一家庭  |
| fenceLng     | double | ✅  | 围栏中心点经度                |
| fenceLat     | double | ✅  | 围栏中心点纬度                |
| fenceRange   | double | ✅  | 围栏半径，单位米，必须大于 0        |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- `targetUserId` 必须是设置者同一家庭的成员，否则返回 `403 LOCATION_TARGET_NOT_FAMILY_MEMBER`
- `fenceRange` 为空或 ≤ 0 返回 `400 LOCATION_FENCE_RANGE_INVALID`
- **谁设置围栏，越界后就通知谁**（不是通知被监护的 `targetUserId` 本人）——围栏本质是监护关系的体现，设置者才是关心"
  有没有越界"这件事的人

---

### 6.5 删除电子围栏

**DELETE** `/location/fence/{fenceId}`
🔒 需要认证，且**只有该围栏的设置者本人**能删除（被监护人不能删除盯着自己的围栏）

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- `fenceId` 不存在返回 `404 NO_SUCH_FENCE`
- 当前用户不是该围栏的设置者，返回 `403 NOT_FENCE_SETTER`
- 逻辑删除（`deleted_at`），历史报警记录（见 6.7）不受影响，仍可查询

---

### 6.6 查看本家庭的所有围栏

**GET** `/location/fence`
🔒 需要认证，返回当前用户所在家庭的**全部**围栏（不限于自己设置的）

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 1,
      "name": "学校",
      "setterUserId": 1,
      "targetUserId": 3,
      "fenceLng": 116.397128,
      "fenceLat": 39.916527,
      "fenceRange": 200,
      "createdAt": "2026-07-14T10:00:00.000Z",
      "updatedAt": "2026-07-14T10:00:00.000Z"
    }
  ]
}
```

---

### 6.7 查看我收到的围栏报警历史

**GET** `/location/fence-alarm`
🔒 需要认证，只返回**通知对象是当前用户**的报警记录（即当前用户是设置者的那些围栏产生的报警），按触发时间倒序

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 10,
      "fenceId": 1,
      "fenceName": "学校",
      "alarmType": "STEPPED_OUTSIDE",
      "alarmedAt": "2026-07-14T15:30:00.000Z",
      "targetUserId": 3,
      "targetUsername": "王小明",
      "targetUserAvatarUrl": "https://<r2-public-base-url>/users/avatars/3/....webp"
    }
  ]
}
```

| 字段        | 说明                                                                                                                        |
|-----------|---------------------------------------------------------------------------------------------------------------------------|
| alarmType | `STEPPED_INSIDE`（进入围栏）/ `STEPPED_OUTSIDE`（离开围栏）；`INSIDE_TIMEOUT`/`OUTSIDE_TIMEOUT`（长时间停留报警）暂未实现                           |
| fenceName | 触发报警时所属围栏的名称；**围栏之后被删除也不影响这条历史记录**，只是 `fenceName` 会变成 `null`（`targetUserId`/`targetUsername` 等字段在报警产生时已经快照进记录本身，不受围栏删除影响） |

**业务逻辑：**

- 越界检测在每次 `POST /location/report` 上报时**同步**触发：拿本次上报前 Redis 中的"上一次位置"
  与本次上报的新位置，对该用户名下所有生效围栏分别判断是否穿越边界，状态变化才产生一条报警记录
- 首次上报（Redis 中还没有"上一次位置"）跳过围栏检测，不产生误报
- **这个接口是"翻历史记录"用的，不是实时通知通道**——触发告警时，服务端会异步（Kafka）通知 user-service 经极光推送把通知发到设置者手机上，实时性依赖 2.7 里注册的推送 Token；这个接口是给客户端做"告警列表页"用的兜底/回溯查询，即使推送因为设备没联网、Token 没注册等原因没送达，这里也能查到完整历史。换句话说：**前端要同时接入 2.7（保证能收到实时推送）和这个接口（保证列表页数据完整）**，两者不是二选一的关系

---

### 6.8 位置服务专属错误码

| code                              | HTTP 状态 | 说明                                       |
|-----------------------------------|---------|------------------------------------------|
| LOCATION_COORDINATE_INVALID       | 400     | 经纬度不能为空                                  |
| LOCATION_BATTERY_INVALID          | 400     | 电量数值不合法（超过 100）                          |
| LOCATION_TIMESTAMP_MISSING        | 400     | 定位时间戳不能为空                                |
| LOCATION_TIMESTAMP_STALE          | 400     | 定位数据已过期（客户端时间戳与服务端时间相差超过 10 分钟），请重新采集后上报 |
| LOCATION_TARGET_NOT_FAMILY_MEMBER | 403     | 目标用户不是同一家庭成员                             |
| LOCATION_FENCE_RANGE_INVALID      | 400     | 围栏半径不合法                                  |
| NO_SUCH_FENCE                     | 404     | 围栏不存在                                    |
| NOT_FENCE_SETTER                  | 403     | 仅围栏设置者可执行该操作                             |
| NO_SUCH_FAMILY_MEMBER             | 404     | 当前用户不是任何家庭的成员                            |

---

## 七、家庭动态服务（Moment Service）

**微服务端口：** 8086
**网关路由：** `/api/v1/moment/**` → Moment Service

> 类似朋友圈的家庭动态功能：家庭成员可以发布文字/图片/视频/语音混排的动态，默认仅同一家庭内可见，发布时也可以选择公开给其他家庭（`isPublic`），公开的动态和评论会出现在跨家庭的"动态广场"里；支持点赞（允许对同一条动态重复点赞表达热度）和评论。

---

### 7.1 发布动态

**POST** `/moment`
🔒 需要认证

**Request Body：**

```json
{
  "content": "今天天气真好",
  "media": [
    { "type": "image", "content": "https://<r2-public-base-url>/users/photos/1/....jpg" },
    { "type": "video", "content": "https://<r2-public-base-url>/users/videos/1/....mp4" }
  ],
  "isPublic": false
}
```

| 字段       | 类型      | 必填 | 说明                                                                                     |
|----------|---------|----|------------------------------------------------------------------------------------------|
| content  | string  | 否  | 动态文字说明；`content` 和 `media` 不能同时为空                                                       |
| media    | array   | 否  | 媒体列表，每项 `{ type, content }`；`type` 为 `image`/`video`/`audio` 之一，`content` 是对应的 R2 URL（先调 2.4/2.5/2.6 上传接口拿到 URL，再传到这里，和聊天图片消息是同一套"先上传拿 URL、再引用"的模式） |
| isPublic | boolean | 否  | 是否公开给其他家庭；缺省 `false`（仅本家庭可见）。公开后这条动态及其评论会出现在 7.3 的跨家庭动态广场里                                |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- `content` 和 `media` 同时为空 → `400 MOMENT_CONTENT_EMPTY`（不允许发完全空白的动态）
- `media[].type` 不在白名单（`image`/`video`/`audio`）内 → `400 INVALID_MOMENT_MEDIA_TYPE`
- `familyId` 不接受前端传入，服务端通过 `FamilyApi.getFamilyByUserId(userId)` 反查
- `moment` 主表和 `moment_media` 子表的插入在同一事务（`@Transactional`）内完成，`media` 批量插入（`saveBatch`），避免半吊子数据

---

### 7.2 查询本家庭的动态列表

**GET** `/moment/myfamily?page=1&pageSize=10&asc=false`
🔒 需要认证，返回当前用户所在家庭的动态

**Query Parameters：**

| 参数       | 类型      | 必填 | 说明                                        |
|----------|---------|----|-------------------------------------------|
| page     | int     | 否  | 页码，缺省或非法值取 1                              |
| pageSize | int     | 否  | 每页条数，缺省取 10，超过 50 截到 50                    |
| asc      | boolean | 否  | 缺省 `false`：按发布时间倒序（最新在前）；`true` 为正序（最早在前） |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "total": 23,
    "moments": [
      {
        "id": 1,
        "userId": 1,
        "username": "王建国",
        "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/1/....webp",
        "createdAt": "2026-07-15T16:00:00.000Z",
        "content": "今天天气真好",
        "mediaFiles": [
          { "type": "image", "content": "https://<r2-public-base-url>/users/photos/1/....jpg", "createdAt": "2026-07-15T16:00:00.000Z" }
        ]
      }
    ]
  }
}
```

**业务逻辑：**

- 只返回当前用户所在家庭的动态（`family_id` 过滤）
- 批量查询发布者用户信息、批量查询关联媒体（按这一页所有 `momentId` 一次性 `IN` 查询），避免循环内逐条查库（N+1）

---

### 7.3 查看动态广场（跨家庭公开动态）

**GET** `/moment/public?page=1&pageSize=10&asc=false`
🔒 需要认证，返回所有家庭里被标记为公开（`isPublic=true`）的动态，不限于当前用户所在家庭

**Query Parameters：**

| 参数       | 类型      | 必填 | 说明                                        |
|----------|---------|----|-------------------------------------------|
| page     | int     | 否  | 页码，缺省或非法值取 1                              |
| pageSize | int     | 否  | 每页条数，缺省取 10，超过 50 截到 50                    |
| asc      | boolean | 否  | 缺省 `false`：按发布时间倒序（最新在前）；`true` 为正序（最早在前） |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "total": 6,
    "moments": [
      {
        "id": 8,
        "userId": 5,
        "username": "李秀英",
        "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/5/....webp",
        "familyId": 3,
        "familyName": "李家",
        "createdAt": "2026-07-18T09:00:00.000Z",
        "content": "我们家今天包了饺子",
        "mediaFiles": [
          { "type": "image", "content": "https://<r2-public-base-url>/users/photos/5/....jpg", "createdAt": "2026-07-18T09:00:00.000Z" }
        ]
      }
    ]
  }
}
```

**业务逻辑：**

- 只按 `is_public = true` 过滤，不做家庭边界校验（这就是"公开"的意义），任何已登录用户都能看
- 相比 7.2 的响应多了 `familyId`/`familyName` 两个字段——同一家庭内浏览时"是谁的家庭"是废话，跨家庭广场里则是必要的上下文，否则分不清这条动态来自哪一家
- `familyName` 按这一页结果里出现的 `familyId` 批量反查（`FamilyApi.getFamiliesByIds`，新增的 Dubbo 接口），跟批量查用户信息一样避免循环内逐个查（N+1）
- 7.9 发表评论 / 7.10 查看评论 对公开动态和家庭内动态一视同仁，不额外区分（评论接口本来就不做家庭边界校验）

---

### 7.4 删除动态

**DELETE** `/moment/{momentId}`
🔒 需要认证，仅动态发布者本人可删除

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- `momentId` 不存在 → `404 NO_SUCH_MOMENT`
- 当前用户不是该动态的发布者 → `403 NOT_MOMENT_OWNER`
- 逻辑删除（`deleted_at`）

---

### 7.5 点赞动态

**POST** `/moment/liker/{momentId}`
🔒 需要认证

> 允许对同一条动态重复点赞表达热度，不做去重限制；点赞不校验点赞者和动态发布者是否同一家庭。

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- 每个用户对每条动态在 `moment_liker` 表里只有一行（`unique(moment_id, liker_user_id)`），字段 `like_count` 记录这个用户对这条动态点了多少次
- 用数据库原子的 `INSERT ... ON DUPLICATE KEY UPDATE like_count = like_count + 1` 实现"没记录就建、有记录就加一"，避免"先查后写"在并发下的竞态条件（更新丢失/唯一键冲突）

---

### 7.6 取消点赞

**DELETE** `/moment/liker/{momentId}`
🔒 需要认证

> 取消点赞是把这个用户在这条动态下的点赞记录整行删除（清零），不是把 `like_count` 减一。

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- 当前用户对这条动态没有点赞记录 → `404 NO_SUCH_LIKE_RECORD`

---

### 7.7 获取点赞总数

**GET** `/moment/liker/{momentId}/like-count`
🔒 需要认证

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": 15
}
```

**业务逻辑：**

- `SUM(like_count)`，这条动态一个赞都没有时返回 `0`（数据库层用 `COALESCE(SUM(like_count), 0)` 兜底，不返回 `null`）

---

### 7.8 获取点赞详情

**GET** `/moment/liker/{momentId}/like-detail`
🔒 需要认证

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "totalLikes": 15,
    "likers": [
      { "userId": 2, "username": "张美玲", "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/2/....webp", "likeCount": 10 },
      { "userId": 3, "username": "王小明", "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/3/....webp", "likeCount": 5 }
    ]
  }
}
```

**业务逻辑：**

- `totalLikes` 是这条动态所有点赞记录的 `like_count` 求和
- `likers` 按点赞者分组，每人一条，附带这个人对这条动态点了几次；批量查询点赞者的用户信息（避免循环内逐个查 `UserApi`）

---

### 7.9 发表评论

**POST** `/moment/comment/{momentId}`
🔒 需要认证

**Request Body：**

```json
{
  "content": "拍得真好看！"
}
```

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- `content` 为空 → `400 COMMENT_CONTENT_EMPTY`
- 评论不校验评论者和动态发布者是否同一家庭（跟点赞一致的宽松策略）

---

### 7.10 查看某条动态的所有评论

**GET** `/moment/comment/{momentId}`
🔒 需要认证

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 1,
      "userId": 2,
      "username": "张美玲",
      "userAvatarUrl": "https://<r2-public-base-url>/users/avatars/2/....webp",
      "content": "拍得真好看！",
      "createdAt": "2026-07-15T20:30:00.000Z"
    }
  ]
}
```

**业务逻辑：**

- 按 `created_at` 正序返回（从早到晚），跟动态 Feed 默认倒序相反
- 批量查询评论者的用户信息，避免循环内逐个查 `UserApi`
- 评论暂不支持"回复某条评论"（楼中楼），全部平级挂在动态下面，是已知的简化设计，以后有需要再加 `replyToCommentId` 升级

---

### 7.11 删除评论

**DELETE** `/moment/comment/{commentId}`
🔒 需要认证，仅评论作者本人可删除（动态发布者不能删除别人在自己动态下的评论，是已知的简化设计）

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": null
}
```

**业务逻辑：**

- `commentId` 不存在 → `404 NO_SUCH_COMMENT`
- 当前用户不是该评论的作者 → `403 NOT_COMMENT_OWNER`
- 逻辑删除（`deleted_at`）

---

### 7.12 动态服务专属错误码

| code                     | HTTP 状态 | 说明              |
|--------------------------|---------|-----------------|
| MOMENT_CONTENT_EMPTY     | 400     | 动态内容和媒体不能同时为空   |
| INVALID_MOMENT_MEDIA_TYPE| 400     | 媒体类型不正确         |
| NO_SUCH_MOMENT           | 404     | 动态不存在           |
| NOT_MOMENT_OWNER         | 403     | 仅动态发布者本人可执行该操作  |
| NO_SUCH_LIKE_RECORD      | 404     | 尚未点赞，无法取消       |
| COMMENT_CONTENT_EMPTY    | 400     | 评论内容不能为空        |
| NO_SUCH_COMMENT          | 404     | 评论不存在           |
| NOT_COMMENT_OWNER        | 403     | 仅评论作者本人可执行该操作   |

---

## 八、成员健康记录服务（Health Service）

**微服务端口：** 8087
**网关路由：** `/api/v1/health/**` → Health Service

> 家庭成员可以记录自己每天的身高、体重、血压，三项指标各自独立（比如今天只测了血压，没测身高体重）。每项指标是否对家庭成员公开是**按指标类型全局设置**的（比如"体重"永远私密、"血压"永远公开），不是每条记录单独设置。还可以设置一个每日提醒时间，到点了如果当天还没记录，会收到极光推送提醒（复用 2.7 注册的推送 Token，接入方式和实现原理跟 6.7 的围栏报警推送完全一致）。

---

### 8.1 提交一条健康记录

**POST** `/health/records`
🔒 需要认证

**Request Body：**

```json
{
  "metricType": "BLOOD_PRESSURE",
  "value": 120,
  "valueSecondary": 80,
  "recordedAt": "2026-07-19"
}
```

| 字段              | 类型      | 必填 | 说明                                                                 |
|-----------------|---------|----|--------------------------------------------------------------------|
| metricType      | string  | 是  | `HEIGHT`（身高）/ `WEIGHT`（体重）/ `BLOOD_PRESSURE`（血压）之一                    |
| value           | number  | 是  | 身高(cm)/体重(kg)时是本身的值；血压时是**收缩压**                                     |
| valueSecondary  | number  | 视情况 | 仅 `BLOOD_PRESSURE` 需要，填**舒张压**；`HEIGHT`/`WEIGHT` 不要传这个字段              |
| recordedAt      | string  | 否  | 记的是哪一天（`YYYY-MM-DD`），不传默认今天；用于补记之前忘记记录的日子                            |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "id": 1001,
    "userId": 3,
    "metricType": "BLOOD_PRESSURE",
    "value": 120,
    "valueSecondary": 80,
    "recordedAt": "2026-07-19"
  }
}
```

**业务逻辑：**

- **同一天同一指标重复提交是覆盖更新，不是新增一条**——前端如果想让用户"改一下今天填错的体重"，直接再调一次这个接口即可，不用先查 id 再传给别的接口
- `metricType` 不在三个合法值内 → `400 INVALID_HEALTH_METRIC_TYPE`
- `value` 为空，或者血压没同时给 `value`+`valueSecondary`，或者身高体重却带了 `valueSecondary` → `400 HEALTH_RECORD_VALUE_INVALID`
- `familyId` 不接受前端传入，服务端通过 `FamilyApi.getFamilyByUserId(userId)` 反查

---

### 8.2 查自己的健康记录历史

**GET** `/health/records?metricType=WEIGHT&from=2026-06-01&to=2026-07-19&page=1&pageSize=30`
🔒 需要认证

| 参数         | 必填 | 说明                                  |
|------------|----|-------------------------------------|
| metricType | 否  | 不传查全部三种指标                            |
| from / to  | 否  | 日期范围（`YYYY-MM-DD`），不传不限制             |
| page       | 否  | 默认第 1 页                              |
| pageSize   | 否  | 默认 30，最大 100                         |

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 1001,
      "userId": 3,
      "metricType": "BLOOD_PRESSURE",
      "value": 120,
      "valueSecondary": 80,
      "recordedAt": "2026-07-19"
    }
  ]
}
```

按 `recordedAt` 倒序（最新的在前）。返回的每条记录都带 `id`，用于 8.3 手动修改。

---

### 8.3 手动修改一条已有记录

**PUT** `/health/records/{recordId}`
🔒 需要认证，只能改自己的记录

在 8.2 的历史列表里选中一条（拿到它的 `id`）之后，可以直接改这条记录的数值或日期——不需要先删除再用 8.1 重新提交。

**Request Body：**

```json
{
  "value": 118,
  "valueSecondary": 78,
  "recordedAt": "2026-07-19"
}
```

| 字段              | 类型      | 必填 | 说明                                                     |
|-----------------|---------|----|--------------------------------------------------------|
| value           | number  | 是  | 同 8.1                                                   |
| valueSecondary  | number  | 视情况 | 同 8.1；是否需要由这条记录本身的 `metricType` 决定（血压要、身高体重不要）           |
| recordedAt      | string  | 否  | 不传就不改日期；传了会把这条记录挪到新的日期                                  |

**Response：** 同 8.1，返回修改后的记录。

**业务逻辑：**

- **`metricType` 不允许修改**——请求体里不接受这个字段，改类型等于把这条记录变成另一个指标序列的一部分，语义上应该是"删掉重记"而不是"编辑"；这条记录的校验规则（血压要不要 `valueSecondary`）始终按它原本的 `metricType` 判断，不受请求体影响
- 记录不存在 → `404 NO_SUCH_HEALTH_RECORD`
- 不是自己的记录 → `403 NOT_HEALTH_RECORD_OWNER`（无法修改家庭成员的记录，哪怕对方公开了）
- 把 `recordedAt` 改到自己另一条同指标记录已经占用的日期 → `409 HEALTH_RECORD_DATE_CONFLICT`（`(userId, metricType, recordedAt)` 唯一约束决定的）

---

### 8.4 查某个家庭成员公开的健康记录

**GET** `/health/records/family/{memberId}?metricType=WEIGHT&from=...&to=...&page=1&pageSize=30`
🔒 需要认证，只能查同一家庭的成员

参数同 8.2。响应结构同 8.2。

**业务逻辑（前端要理解这里的权限规则，不然会以为接口坏了）：**

- 服务端先校验发起查询者和 `memberId` 是否同一家庭，不是 → `403 NOT_SAME_FAMILY`
- 显式传了 `metricType`，但对方没把这项指标设为公开 → **返回空数组，不是报错**（如果报错等于告诉你"对方有这项记录只是不给你看"，反而泄露了一点信息，所以统一处理成"查不到"）
- 不传 `metricType` → 只返回对方已经公开的那些指标类型的记录，没公开的类型不会出现在结果里
- 换句话说：**这个接口永远不会主动告诉你对方隐藏了什么，只会告诉你能看到什么**

---

### 8.5 查自己的可见性设置

**GET** `/health/visibility`
🔒 需要认证

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": [
    { "metricType": "HEIGHT", "visible": true },
    { "metricType": "WEIGHT", "visible": false },
    { "metricType": "BLOOD_PRESSURE", "visible": true }
  ]
}
```

**业务逻辑：**

- 三种指标类型**永远补全返回**，哪怕用户从来没设置过某个类型的可见性，也会出现在列表里、`visible: false`（默认私密）——前端不用自己判断"这个类型没返回是不是等于隐藏"

---

### 8.6 修改某个指标的可见性

**PUT** `/health/visibility`
🔒 需要认证

**Request Body：**

```json
{ "metricType": "WEIGHT", "visible": true }
```

一次只改一个指标类型。`metricType` 不合法 → `400 INVALID_HEALTH_METRIC_TYPE`。

**Response：** `{ "code": 200, "message": "ok", "data": null }`

---

### 8.7 查自己的提醒设置

**GET** `/health/reminder`
🔒 需要认证

**Response：**

```json
{
  "code": 200,
  "message": "ok",
  "data": { "remindTime": "20:00:00", "enabled": true }
}
```

用户从没设置过提醒时，`remindTime` 返回 `null`、`enabled` 返回 `false`——这是合法状态，不是 404。

---

### 8.8 修改自己的提醒设置

**PUT** `/health/reminder`
🔒 需要认证

**Request Body：**

```json
{ "remindTime": "20:00:00", "enabled": true }
```

**Response：** `{ "code": 200, "message": "ok", "data": null }`

**业务逻辑（提醒是怎么真正推送到手机的，前端要接哪些环节）：**

1. health-service 内部有个定时任务，每分钟扫一次所有 `enabled=true` 的提醒设置，命中"当前时间等于 remindTime 且今天还没提醒过"的成员
2. 命中后发一个 Kafka 事件，user-service 消费后查该用户在 2.7 注册过的推送 Token，逐个调极光推送
3. **前端必须先完成 2.7 的推送 Token 注册流程，这个提醒才有渠道能送达**；如果用户没在 2.7 注册过任何设备，`enabled=true` 也不会报错，只是静默地推不出去（跟 6.7 围栏报警推送是同一个前提条件）
4. 目前提醒粒度是"一人一个每日提醒时间"，不区分身高/体重/血压——不是"提醒你测血压"，而是笼统的"该记录健康数据了"

---

### 8.9 健康服务专属错误码

| code                        | HTTP 状态 | 说明                                  |
|-----------------------------|---------|---------------------------------------|
| INVALID_HEALTH_METRIC_TYPE  | 400     | 健康指标类型不正确（不是 HEIGHT/WEIGHT/BLOOD_PRESSURE 之一） |
| HEALTH_RECORD_VALUE_INVALID | 400     | 健康记录数值不合法（缺值，或血压没同时给两个值，或身高体重多传了 valueSecondary） |
| NOT_SAME_FAMILY             | 403     | 目标用户不是同一家庭成员                          |
| INVALID_REMIND_TIME         | 400     | 提醒时间格式不正确                             |
| NO_SUCH_HEALTH_RECORD       | 404     | 健康记录不存在                               |
| NOT_HEALTH_RECORD_OWNER     | 403     | 仅本人可修改自己的健康记录                         |
| HEALTH_RECORD_DATE_CONFLICT | 409     | 该日期已存在同指标的记录                          |

---

## 九、红包服务（Redpacket Service）

**微服务端口：** 8088  
**网关路由：** `/api/v1/redpacket/**` → Redpacket Service；`/api/v1/redpacket-grabs/**` → Redpacket Service

> 💰 **金额单位统一为「分」（整数）**：所有 `*Amount` 字段都是 `long` 型的**分**，不是元。例如 `10000` = 100.00 元、`888` = 8.88 元。用 `long` 存分是为了避免浮点精度丢失，前端展示时自行 `/100` 并格式化两位小数。

> ⚡ **抢红包是高并发异步落库设计**：抢红包在 Redis 中原子完成瞬间返回结果，数据库记录由后台异步补齐（通常毫秒级）。因此**「抢红包」接口返回的 `grabAmount` 是权威结果，前端应以它为准立即展示**；而紧随其后调用「抢红包明细列表」时，刚抢的那条记录可能有极短暂延迟才出现——如需展示"我抢了多少"，请直接用抢红包接口的返回值，不要依赖立刻重查列表。

---

### 9.1 创建红包

**POST** `/redpacket`

在指定会话里发一个红包。发红包会**立即从发红包人的余额中扣除 `totalAmount`（分）**，红包金额由服务端用「二倍均值法」预先随机拆成 `totalCount` 份。

**Request Body：**
```json
{
  "totalAmount": 10000,
  "totalCount": 5,
  "conversationId": 12
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| totalAmount | long | ✅ | 红包总金额，单位**分**，须 > 0 |
| totalCount | int | ✅ | 红包个数，须 > 0；且不得超过该会话的成员数 |
| conversationId | long | ✅ | 红包发到哪个会话；发红包人必须是该会话成员 |

**约束：** `totalAmount >= totalCount`（每份至少 1 分，否则无法拆分）。

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "id": 1001,
    "userId": 1,
    "totalAmount": 10000,
    "totalCount": 5,
    "status": "ongoing",
    "expiredAt": "2026-07-25T14:30:00",
    "createdAt": "2026-07-24T14:30:00"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| id | long | 红包 ID，后续「抢红包」「查红包」都用它 |
| userId | long | 发红包人 ID |
| totalAmount | long | 总金额（分） |
| totalCount | int | 红包个数 |
| status | string | 红包状态，见下方「状态说明」 |
| expiredAt | datetime | 过期时间（当前为创建后 +1 天）；过期未抢完的份额自动退还发红包人 |
| createdAt | datetime | 创建时间 |

**业务逻辑：**
- 校验会话成员身份 → 校验 `totalCount` 不超过会话成员数 → 扣减余额 → 落库 → 预热到 Redis（拆好的份额 + 状态），之后所有「抢」都在 Redis 上完成。
- 创建成功后，**前端需再自行往该会话发一条 `type=REDPACKET`、`content=红包id` 的聊天消息**，会话成员据此看到红包卡片（复用现有聊天发消息接口，红包服务不主动推送）。

**错误码：**

| code | 业务码 | 场景 |
|------|--------|------|
| 400 | PARAM_ERROR | 参数缺失或 `totalAmount`/`totalCount` ≤ 0 |
| 400 | INVALID_REDPACKET_AMOUNT | `totalAmount < totalCount`，金额太小无法拆分 |
| 403 | NOT_CONVERSATION_MEMBER | 发红包人不是该会话成员 |
| 400 | REDPACKET_NUMBER_MORE_THAN_CONVERSATION_MEMBERS | 红包个数超过会话成员数 |
| 400 | INSUFFICIENT_FUND | 发红包人余额不足 |

---

### 9.2 查询红包详情

**GET** `/redpacket/{id}`

查询单个红包的基本信息（金额、个数、状态、过期时间等）。调用者必须是红包所在会话的成员。

| 路径参数 | 类型 | 必填 | 说明 |
|----------|------|------|------|
| id | long | ✅ | 红包 ID |

**Response：** 同 9.1 的 `data`（`RedpacketVO`）。

**错误码：**

| code | 业务码 | 场景 |
|------|--------|------|
| 404 | INVALID_REDPACKET | 红包不存在 |
| 403 | NOT_CONVERSATION_MEMBER | 调用者不是红包所在会话的成员 |

---

### 9.3 抢红包

**POST** `/redpacket-grabs`

抢一个红包，返回本次抢到的金额。每个用户对同一个红包**只能抢一次**。

**Request Body：**
```json
{
  "redpacketId": 1001
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| redpacketId | long | ✅ | 要抢的红包 ID |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": {
    "id": null,
    "redpacketId": 1001,
    "userId": 7,
    "grabAmount": 2333,
    "createdAt": "2026-07-24T14:31:05"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| id | long | 抢红包记录 ID。⚠️ **本接口返回时恒为 `null`** —— 抢红包在 Redis 中瞬间完成、数据库记录由后台异步补齐，返回这一刻记录尚未入库、自增主键还未生成。稍后可在 9.6「我收到的红包」列表里拿到带 `id` 的正式记录 |
| redpacketId | long | 所抢红包 ID |
| userId | long | 抢红包人 ID（即当前用户） |
| grabAmount | long | **本次抢到的金额（分）** —— 权威结果，前端以此展示 |
| createdAt | datetime | 抢到时间（服务端返回时按当前时刻生成，与最终入库时间基本一致） |

> ℹ️ 三个接口（9.3/9.4/9.6）都返回同一个 `RedpacketGrabVO`，但它还带 5 个**用户信息字段**（`username`/`userAvatarUrl` = 抢红包人，`redpacketOwnerId`/`redpacketOwnerUsername`/`redpacketOwnerUserAvatarUrl` = 发红包人）——**本接口(9.3)一个都不填，全为 `null`**；它们只在 9.4（填抢红包人）和 9.6（填发红包人）里有值。

> ⚠️ **前端注意**：本接口的返回值用于**立即告诉用户"你抢到了 X 元"**，`grabAmount` 是权威字段。**不要依赖返回的 `id`（为 null）**，也不要在抢到后立刻重查列表就期望看到这条记录——异步落库有极短延迟。需要展示带记录 id 的列表时，走 9.6。

**错误码：**

| code | 业务码 | 场景 |
|------|--------|------|
| 400 | PARAM_ERROR | `redpacketId` 缺失 |
| 404 | INVALID_REDPACKET | 红包不存在或不在进行中 |
| 400 | REDPACKET_EXPIRED | 红包已过期 |
| 403 | NOT_CONVERSATION_MEMBER | 调用者不是红包所在会话的成员 |
| 400 | REDPACKET_GRABBED_ALREADY | 该用户已抢过这个红包 |
| 400 | REDPACKET_EMPTY | 红包已被抢完 |

---

### 9.4 抢红包明细列表

**GET** `/redpacket-grabs?redpacketId={id}`

查询某个红包被哪些人抢了、各抢了多少（用于"红包已领取详情"页）。调用者必须是红包所在会话的成员。

| Query 参数 | 类型 | 必填 | 说明 |
|-----------|------|------|------|
| redpacketId | long | ✅ | 红包 ID |

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": [
    { "id": 50001, "redpacketId": 1001, "userId": 7, "username": "王小明", "userAvatarUrl": "https://oss.example.com/avatars/7.jpg", "grabAmount": 2333, "createdAt": "2026-07-24T14:31:05" },
    { "id": 50002, "redpacketId": 1001, "userId": 9, "username": "张丽", "userAvatarUrl": null, "grabAmount": 1500, "createdAt": "2026-07-24T14:31:07" }
  ]
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| id | long | 抢红包记录 ID |
| redpacketId | long | 红包 ID |
| userId | long | **抢红包人** ID |
| username | string | **抢红包人昵称**（本接口填充） |
| userAvatarUrl | string | **抢红包人头像**（本接口填充）；未上传过头像时为 `null` |
| grabAmount | long | 抢到金额（分） |
| createdAt | datetime | 抢到时间 |

> ℹ️ 本接口填充的是"抢红包人"信息（`username`/`userAvatarUrl`）；发红包人字段（`redpacketOwner*`）在本接口中为 `null`。列表按数据库返回顺序排列（未显式排序）。

**错误码：** 同 9.2（`INVALID_REDPACKET` / `NOT_CONVERSATION_MEMBER`）。

---

### 9.5 我发出的红包列表

**GET** `/redpacket/i-sent`  
🔒 需要认证

查询**当前登录用户发出的所有红包**（用于"我的红包 - 发出"页）。无需任何参数，用户身份取自 Token。

> ⚠️ **当前无分页、无排序**：一次性返回该用户历史上发出的全部红包，按数据库默认顺序（约等于创建时间正序）。数据量大时后续需补分页。

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 1001,
      "userId": 1,
      "totalAmount": 10000,
      "totalCount": 5,
      "status": "finished",
      "expiredAt": "2026-07-25T14:30:00",
      "createdAt": "2026-07-24T14:30:00"
    }
  ]
}
```

数组元素结构同 9.1 的 `data`（`RedpacketVO`）。用户没发过红包时返回空数组 `[]`。

---

### 9.6 我收到的红包列表

**GET** `/redpacket-grabs/i-received`  
🔒 需要认证

查询**当前登录用户抢到的所有红包记录**（用于"我的红包 - 收到"页）。无需任何参数，用户身份取自 Token。

> ⚠️ **当前无分页、无排序**，同 9.5。
>
> ℹ️ 本接口已**填充"发红包人"信息**（`redpacketOwnerId`/`redpacketOwnerUsername`/`redpacketOwnerUserAvatarUrl`），前端可直接展示"谁发的红包、我抢了多少"，无需再逐个调 9.2。（仍不含红包总额等字段，如需可另调 9.2。）

**Response：**
```json
{
  "code": 200,
  "message": "ok",
  "data": [
    {
      "id": 50001,
      "redpacketId": 1001,
      "userId": 7,
      "redpacketOwnerId": 1,
      "redpacketOwnerUsername": "王建国",
      "redpacketOwnerUserAvatarUrl": "https://oss.example.com/avatars/1.jpg",
      "grabAmount": 2333,
      "createdAt": "2026-07-24T14:31:05"
    }
  ]
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| id | long | 抢红包记录 ID |
| redpacketId | long | 红包 ID |
| userId | long | 抢红包人 ID（即当前用户自己） |
| redpacketOwnerId | long | **发红包人** ID（本接口填充） |
| redpacketOwnerUsername | string | **发红包人昵称**（本接口填充） |
| redpacketOwnerUserAvatarUrl | string | **发红包人头像**（本接口填充）；未上传过头像时为 `null` |
| grabAmount | long | 我抢到的金额（分） |
| createdAt | datetime | 抢到时间 |

> ℹ️ 本接口填充的是"发红包人"信息（`redpacketOwner*`）；抢红包人自身的 `username`/`userAvatarUrl` 在本接口中为 `null`（抢红包人就是你自己，前端已知）。没抢到过红包时返回空数组 `[]`。

---

### 9.7 红包状态说明

`status` 字段取值：

| 值 | 说明 |
|------|------|
| `ongoing` | 进行中，还有份额可抢 |
| `finished` | 已抢完（所有份额被领光） |
| `expired` | 已过期（有人来抢时发现已过期会置为此状态） |
| `refunded` | 已退款（过期扫描任务把未抢完的剩余金额退还发红包人后置为此状态） |

**过期与退款：** 红包创建后 +1 天过期。后台定时任务会扫描过期且未抢完的红包，把**剩余未被抢走的金额自动退还给发红包人**，并将状态置为 `refunded`。已经被抢走的份额不受影响。

---

## 十、微服务架构总览

```
Flutter Web/iOS/Android
         |
  ┌──────▼──────────────────────────────────┐
  │       API Gateway（Spring Cloud Gateway）│
  │       端口：8080 / Nacos 注册            │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼────────┐  ┌──────────────────────┐
  │ Auth Service  │  │  User Service         │
  │ 端口：8081    │  │  端口：8082           │
  └───────────────┘  └──────────────────────┘
  ┌──────────────────┐  ┌───────────────────┐
  │ Family Service   │  │  Chat Service      │
  │ 端口：8083       │  │  端口：8084        │
  └──────────────────┘  └───────────────────┘
  ┌──────────────────┐  ┌───────────────────┐
  │ Location Service │  │  Moment Service    │
  │ 端口：8085       │  │  端口：8086        │
  └──────────────────┘  └───────────────────┘
  ┌──────────────────┐  ┌───────────────────┐
  │ Health Service   │  │  Redpacket Service │
  │ 端口：8087       │  │  端口：8088        │
  └──────────────────┘  └───────────────────┘
         │
  ┌──────▼──────────┐  ┌────────────────────┐
  │   MySQL 8.0     │  │    Redis 7          │
  │   主数据库       │  │ 缓存/状态/Pub-Sub/  │
  │                 │  │ Lua抢红包/Stream    │
  └─────────────────┘  └────────────────────┘
```

**CORS 配置（Spring Boot）：**
```java
registry.addMapping("/api/**")
    .allowedOriginPatterns("http://localhost:*", "https://*.sweethome.example.com")
    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
    .allowedHeaders("*")
    .allowCredentials(true);
```

**WebSocket CORS：**
```java
registry.addHandler(chatHandler, "/api/v1/ws")
    .setAllowedOriginPatterns("http://localhost:*", "https://*.sweethome.example.com");
```

---

## 十一、亲属称谓计算算法（Kinship Relation Algorithm）

> 目标：任意两个家庭成员之间的称谓（如"儿子""伯伯""妻子"）不再是数据库里固定存储的一段文本，而是**相对于当前查看者、按需计算**得到的。同一个人，在不同请求者眼中显示的称谓可能完全不同（爷爷看儿子显示"儿子"，孙辈看同一个人显示"爸爸"）。本节定义的算法需要与前端 `lib/core/kinship/kinship_engine.dart`（mock 模式下使用）保持逻辑一致，便于后端团队复现相同结果。

### 11.1 输入数据

- `family_relations` 表中的边：`PARENT_OF`（有向，subject 是 object 的父/母）与 `SPOUSE_OF`（无向，已规范化为 `subject_member_id < object_member_id`）
- `family_members.gender`（`male`/`female`）
- `family_members.birth_order`（可为空，数值越小越年长）

### 11.2 基元步进 Token

沿关系图从查看者走到目标成员，每一步用以下 token 之一描述：

| Token | 含义 | 判定方式 |
|-------|------|---------|
| `F` | 父亲 | 沿 `PARENT_OF` 向上，父方 `gender = male` |
| `M` | 母亲 | 沿 `PARENT_OF` 向上，母方 `gender = female` |
| `S` | 配偶 | 沿 `SPOUSE_OF` |
| `Son` | 儿子 | 沿 `PARENT_OF` 向下，子方 `gender = male` |
| `Dau` | 女儿 | 沿 `PARENT_OF` 向下，子方 `gender = female` |

### 11.3 最短路径（BFS）

从查看者（viewer）对目标成员（target）做无权最短路径 BFS。同等长度的候选路径中，**血亲边（`F`/`M`/`Son`/`Dau`）优先于姻亲边（`S`）出队**，即算法优先给出血亲关系的表述。若 viewer == target，直接得到 `SELF`，跳过后续步骤。

### 11.4 化简（Reduction）

BFS 得到的原始路径可能出现"先向上一步到父母、再向下一步到父母的另一个孩子"这种模式——这实际是"我的兄弟姐妹"，而不该表述为两跳。化简规则：

反复扫描路径中相邻的 `(F 或 M)` 紧跟 `(Son 或 Dau)`，且这两步连接的两个成员不是同一个人（即目标不是回到查看者自己），将其折叠为一个同辈 token：

- 比较两端成员的 `birth_order`（数值小者年长）：
    - 目标为男性且年长于起点 → `eB`（哥哥）；年幼 → `yB`（弟弟）
    - 目标为女性且年长于起点 → `eZ`（姐姐）；年幼 → `yZ`（妹妹）
    - 若任一方 `birth_order` 为 `NULL`，无法判定年龄时**默认按年长处理**（`eB`/`eZ`）——这是已知精度局限，建议引导用户补全排行信息以提升准确度

折叠后重新从头扫描，直至一轮扫描无法再折叠为止（允许级联折叠，如 `F, F, Son` 会先后折叠两次：先把内层 `F, Son` 折成叔伯/姑姑类同辈 token，外层再视情况处理）。

### 11.5 规范 `relationCode`

化简后的 token 序列用 `.` 连接即为 `relationCode`，例如：

| relationCode | 关系 |
|---|---|
| `SELF` | 自己 |
| `F` / `M` | 父亲 / 母亲 |
| `S` | 配偶 |
| `Son` / `Dau` | 儿子 / 女儿 |
| `F.F` / `F.M` | 祖父 / 祖母（父系） |
| `M.F` / `M.M` | 外祖父 / 外祖母（母系） |
| `Son.Son` / `Son.Dau` / `Dau.Son` / `Dau.Dau` | 孙子 / 孙女 / 外孙 / 外孙女 |
| `eB` / `yB` / `eZ` / `yZ` | 哥哥 / 弟弟 / 姐姐 / 妹妹 |
| `F.eB` / `F.yB` | 伯伯 / 叔叔 |
| `F.eZ` / `F.yZ` | 姑姑（年长/年幼，部分语言不区分） |
| `M.eB` / `M.yB` / `M.eZ` / `M.yZ` | 舅舅 / 阿姨（多数语言不区分排行） |
| `eB.Son` / `eB.Dau` 等 | 侄子 / 侄女（经由兄弟）；`eZ.Son`/`eZ.Dau` 等为外甥/外甥女（经由姐妹） |
| `S.F` / `S.M` | 公公岳父 / 婆婆岳母 |
| `S.eB` / `S.yB` / `S.eZ` / `S.yZ` | 姻亲兄弟姐妹（大伯子/小舅子/大姑子/小姨子等，视语言而定） |
| `Son.S` / `Dau.S` | 儿媳 / 女婿 |

深度 3 及以上（如表/堂兄弟姐妹 `F.eB.Son`、曾祖父母 `F.F.F`）同样遵循此规则继续拼接，不需要新算法。

### 11.6 本地化——完全由客户端负责，服务端不做任何翻译

**服务端到 11.5 为止就结束了**：接口只返回语言无关的 `relationCode`（以及消歧所需的 `gender`），不接受也不处理 `Accept-Language`，不维护任何语言的称谓词表，不做本地化。这是有意的架构决定：

- **翻译压力交给前端，而不是后端**。官方 Flutter 客户端已经在 `lib/core/kinship/terms/*.dart` 里维护了 6 语言（简中/繁中/韩/缅/英/日）的完整称谓词表，并在 `lib/core/kinship/kinship_localizer.dart` 里实现了"`relationCode` → 本地化文案"的转换（`localizeRelationCode()`），没有理由在后端重复一遍同样的词表和逻辑。
- 客户端在**渲染时**（而不是拉取数据时）根据当前 App 内选择的语言（`LocaleProvider`，与登录页/我的页面的语言选择器共用同一个状态）实时翻译 `relationCode`。这带来两个直接好处：
    1. 用户切换 App 语言时，所有已经拉取到的 `relationCode` 无需重新请求接口就能立刻显示新语言的称谓——因为 `relationCode` 本身不随语言变化，重新渲染即可。
    2. 不会出现"页面语言跟登录页/我的页面选择的语言对不上"的问题——如果由服务端按 `Accept-Language` 提前烤入文案（旧设计），一旦请求发出后用户又切换了语言，或者某个页面缓存了旧请求的结果，界面上就会同时出现两种语言混杂、且不会随语言切换自动刷新，这正是实际发生过的 bug。语言无关的 `relationCode` + 渲染时翻译从根源上消除了这类"语言不同步"问题。
- 后端团队仍然需要按 11.1–11.5 的算法规格独立实现一份"图遍历 + 化简 → `relationCode`"的逻辑（这部分和语言无关，后端/客户端必须产出完全一致的 code），但**到此为止**，不需要再实现 11.6 这一步。
- 客户端侧的兜底规则（供后端团队理解客户端行为，非后端需要实现的内容）：`relationCode` 在客户端词表里查不到时，客户端用该语言的基础词表 + 连接词逐 token 拼接组合兜底，保证界面上永远有文案可显示，只是不够地道；客户端选择的 App 语言不在 6 语言之列（理论上不会发生，因为语言选择器本身只列出这 6 个）时回退到简体中文。

**⚠️ 已知局限**：客户端 6 语言的称谓词表由 AI 辅助生成，**未经母语者校对**，尤其韩语、缅甸语的姻亲与表亲称谓文化差异较大，建议正式上线前安排母语者复核。`birth_order` 缺失时的"默认按年长处理"也是已知的精度妥协，不是缺陷。
