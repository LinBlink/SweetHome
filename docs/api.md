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

**Request Body：**
```json
{
  "name": "王建国",
  "phone": "13800138000",
  "password": "password123",
  "familyName": "王家",
  "inviteCode": "ABCD1234"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ✅ | 昵称，1-50字 |
| phone | string | ✅ | 手机号，11位 |
| password | string | ✅ | 密码，6-20位 |
| familyName | string | 条件必填 | 创建新家庭时必填 |
| inviteCode | string | 条件必填 | 加入已有家庭时必填；与 familyName 二选一 |

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
      "phone": "13800138000",
      "familyId": 1,
      "familyName": "王家",
      "role": "admin"
    }
  }
}
```

**业务逻辑：**
- 提供 `familyName`：创建家庭，当前用户为管理员（role=admin）
- 提供 `inviteCode`：查找对应家庭并加入，role=member
- 注册成功后自动为家庭创建群聊会话（type=group）
- 密码使用 BCrypt 加密存储

---

### 1.2 登录

**POST** `/auth/login`

**Request Body：**
```json
{
  "phone": "13800138000",
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
      "phone": "13800138000",
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
    "phone": "13800138000",
    "avatarUrl": "https://oss.example.com/avatars/1.jpg",
    "familyId": 1,
    "familyName": "王家",
    "role": "admin",
    "displayRole": "爸"
  }
}
```

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

## 三、家庭服务（Family Service）

**微服务端口：** 8083  
**网关路由：** `/api/v1/families/**` → Family Service

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
      "name": "王建国",
      "displayRole": "爸",
      "avatarUrl": null,
      "avatarLabel": "爸",
      "isOnline": true,
      "role": "admin"
    },
    {
      "userId": 2,
      "name": "张美玲",
      "displayRole": "妈",
      "avatarUrl": null,
      "avatarLabel": "妈",
      "isOnline": false,
      "role": "member"
    }
  ]
}
```

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

**Request Body：**
```json
{
  "inviteCode": "ABCD1234"
}
```

**Response：** 返回加入的家庭信息（同 3.1 格式）

**业务逻辑：**
- 验证邀请码有效性和时效
- 将用户加入家庭（family_members）
- 将用户加入家庭群聊（conversation_members）

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
      "lastMessage": "晚饭准备好了，快回家吃饭！",
      "lastMessageAt": "2026-06-29T18:30:00.000Z",
      "unreadCount": 5,
      "memberCount": 6
    },
    {
      "id": 2,
      "type": "direct",
      "name": "张美玲",
      "familyId": 1,
      "avatarLabel": "妈",
      "avatarColor": "FFF4A261",
      "lastMessage": "今天超市打折，我去买点菜",
      "lastMessageAt": "2026-06-29T17:00:00.000Z",
      "unreadCount": 1,
      "memberCount": 2
    }
  ]
}
```

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
        "senderAvatarLabel": "妈",
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

---

### 4.4 发送消息（HTTP 兜底接口）

**POST** `/conversations/{conversationId}/messages`  
🔒 需要认证，且当前用户必须是该会话成员

> 正常情况下消息通过 WebSocket 发送；此接口作为 WebSocket 断线时的降级兜底。

**Request Body：**
```json
{
  "content": "晚饭好了！",
  "type": "text",
  "clientId": "550e8400-e29b-41d4-a716-446655440000"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | ✅ | 消息内容；图片/语音为 OSS URL |
| type | string | ✅ | text / image / voice |
| clientId | string | ✅ | 客户端生成的 UUID，用于去重 |

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

**发送消息**
```json
{
  "type": "SEND_MESSAGE",
  "conversationId": 1,
  "content": "晚饭好了！",
  "messageType": "TEXT",
  "clientId": "550e8400-e29b-41d4-a716-446655440000"
}
```

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
    "senderAvatarLabel": "妈",
    "content": "晚饭好了！",
    "messageType": "TEXT",
    "sentAt": "2026-06-29T18:30:00.000Z"
  }
}
```

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

## 六、微服务架构总览

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
         │
  ┌──────▼──────────┐  ┌────────────────────┐
  │   MySQL 8.0     │  │    Redis 7          │
  │   主数据库       │  │  缓存/状态/Pub-Sub  │
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
