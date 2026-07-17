# 过家家 · Sweet Home

> 以家庭为核心的聊天应用。

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter（Web / iOS / Android） |
| API 网关 | Spring Cloud Gateway + Nacos |
| 后端服务 | Spring Boot 3（微服务架构） |
| 主数据库 | MySQL 8.0 |
| 缓存 / 状态 | Redis 7（在线状态、WebSocket 广播） |
| 消息队列 | RocketMQ |
| 文件存储 | MinIO / 阿里云 OSS |
| 监控 | Prometheus + Grafana + SkyWalking |
| 容器化 | Docker + Kubernetes |

---

## 已实现功能

- 用户注册 / 登录（手机号 + 密码）
- 家庭创建与邀请码加入
- 家庭群聊（实时 WebSocket）
- 家庭成员私聊
- 文字消息发送 / 接收
- 消息气泡（发送方 / 接收方区分）
- 会话列表（未读角标）
- 消息历史分页加载
- 乐观更新（发送即显示）
- WebSocket 断线自动重连（指数退避）
- Mock 模式（无需后端，Chrome 直接测试）

---

## 快速开始

```bash
# Mock 模式，无需后端，直接在 Chrome 测试
flutter run -d chrome --dart-define=MOCK_MODE=true

# 连接本地后端
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1

# 构建生产版本
flutter build web --dart-define=API_BASE_URL=https://api.sweethome.example.com/api/v1
```

## 后端文档

- API 接口规范：[docs/api.md](docs/api.md)