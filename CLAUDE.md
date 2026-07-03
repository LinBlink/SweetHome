# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

过家家 · Sweet Home is a family-centric chat app. This repo contains only the **Flutter frontend** (Web / iOS / Android). The backend (Spring Boot microservices, MySQL, Redis, RocketMQ, etc.) is not part of this repo — its contract is documented in `docs/api.md` (REST + WebSocket API spec) and `docs/schema.sql` (MySQL DDL: `users`, `families`, `family_members`, `conversations`, `conversation_members`, `messages`, `refresh_tokens`). Treat those two files as the source of truth for backend behavior/shape when wiring up real API calls.

## Commands

```bash
# Install dependencies
flutter pub get

# Run in mock mode — no backend needed, works in Chrome out of the box
flutter run -d chrome --dart-define=MOCK_MODE=true

# Run against a local backend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1

# Build production web bundle
flutter build web --dart-define=API_BASE_URL=https://api.sweethome.example.com/api/v1

# Static analysis (uses flutter_lints via analysis_options.yaml)
flutter analyze

# Run tests (single test file)
flutter test test/widget_test.dart

# Run all tests
flutter test
```

There is currently only a placeholder test in `test/widget_test.dart`.

## Architecture

**Runtime mode switch:** Almost everything branches on `AppConfig.mockMode` (`lib/core/app_config.dart`, set via `--dart-define=MOCK_MODE=true`). When true, providers read from `lib/data/mock_data.dart` (`MockDataSource`) and `WebSocketService` is swapped for `MockWebSocketService`, which periodically injects fake incoming messages instead of opening a real socket. When implementing a feature, mirror both the mock path and the real path — the two providers (`AuthProvider`, `ChatProvider`) each have an `if (AppConfig.mockMode) { ... } else { ... }` branch for every operation.

**State management:** `provider` package with `ChangeNotifier`. `AuthProvider` is created once at the app root in `lib/main.dart`. `ChatProvider` is created lazily inside `AuthGate` only after authentication succeeds, and is handed the current `AuthUser`, a `ChatService`, and a `WebSocketService`/`MockWebSocketService` — so `ChatProvider` and its socket connection are torn down/recreated on every login/logout cycle.

**Auth flow:** `lib/main.dart`'s `AuthGate` widget is the top-level router: it watches `AuthProvider.isLoading`/`isAuthenticated` and switches between the splash screen, `LoginScreen`, and the authenticated `MainShell` (bottom-nav shell with conversations + profile tabs). Session persistence uses `shared_preferences` via `AuthService.persistUser`/`loadUser`/`clearUser` (`lib/services/auth_service.dart`), storing flattened string fields, not raw JSON.

**Chat data flow:**
- REST: `ChatService` (`lib/services/chat_service.dart`) — fetch conversations, paginated message history (cursor-based via `before`/`nextCursor`), and POST-send-as-fallback.
- Realtime: `WebSocketService` (`lib/services/websocket_service.dart`) — connects with the JWT as a query param, exponential-backoff reconnect (capped at 6 attempts, doubling up to 30s), and a 25s ping keepalive. Inbound/outbound messages are typed as `WsInboundMessage`/`WsOutboundMessage` (`lib/models/chat_models.dart`); outbound JSON is hand-serialized (no `dart:convert` encode) via `WsOutboundMessage.toJsonString()`.
- `ChatProvider.sendMessage` does optimistic UI updates: it inserts a pending `Message` (keyed by a client-generated UUID `clientId`) immediately, then reconciles it against the server-confirmed message (matched by `clientId`) when it arrives — either via the WebSocket `NEW_MESSAGE` event or, in non-mock mode, a REST fallback if the WS send fails.
- Message identity is `clientId` (UUID, client-generated) not the server `id`/`serverId` — this is what optimistic-update reconciliation matches on.

**Models are hand-written**, not code-generated (no `json_serializable`/`freezed`/build_runner). `fromJson`/`toJson`/`copyWith` are manually maintained on each model in `lib/models/`; keep them in sync by hand when changing shapes.

**Theming:** All colors live in `lib/core/app_colors.dart` (`AppColors`, warm/terracotta palette) and theme setup in `lib/core/app_theme.dart`. Don't hardcode `Color(0x...)` values in widgets — add/reuse an `AppColors` constant.

**Localization:** UI strings are Chinese and inlined directly in widgets (no `.arb`/`intl` message catalog in use despite the `intl` dependency).
