# AGENTS.md

Guidance for AI coding agents working in this repo.

## What this repo is

Flutter frontend for 过家家 · Sweet Home, a family-centric chat app (Web/iOS/Android).
The backend (Spring Boot microservices, MySQL, Redis, RocketMQ) lives in a separate
repo — its contract here is `docs/api.md` (REST + WebSocket spec) and `docs/schema.sql`
(MySQL DDL). Treat those two files as the source of truth when wiring up real API calls.

`TIP.md` and `docs/bugs_to_fix.md` are working notes — read them when touching the
relevant feature, otherwise ignore. The authoritative source for the backend contract
is the backend repo at `C:\Users\wangb\Developer\GitProjects\SweetHome_backend\sh\doc\` —
particularly `API.md` and `BUGS_TO_FIX.md` (treat those as the truth, not the local
`docs/api.md` / `docs/bugs_to_fix.md` mirrors).

## Commands

```bash
flutter pub get
flutter run -d chrome --dart-define=MOCK_MODE=true                 # mock, no backend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
flutter build web --dart-define=API_BASE_URL=https://api.sweethome.example.com/api/v1
flutter analyze                                                   # static analysis (flutter_lints)
flutter test test/widget_test.dart                                 # single file
flutter test                                                      # all tests
```

`AppConfig.apiBaseUrl` defaults to `http://192.168.2.114:8080/api/v1` — override with
`--dart-define=API_BASE_URL=...`. The WebSocket URL is auto-derived as
`{apiBaseUrl with ws/wss}/ws`.

## Codebase conventions that will bite you

- **Hand-written models, no codegen.** No `json_serializable` / `freezed` /
  `build_runner`. Every model in `lib/models/` maintains its own `fromJson` /
  `toJson` / `copyWith` by hand — update them in lockstep when changing shape.
- **Runtime mode switch on `AppConfig.mockMode`.** Almost every provider method
  branches `if (AppConfig.mockMode) { ... } else { ... }`. When adding a feature,
  mirror both paths — `AuthProvider` and `ChatProvider` are the two main ones.
- **Optimistic send uses a client-generated UUID `clientId`.** `ChatProvider.sendMessage`
  inserts a pending message immediately, then reconciles against the server
  reply matched by `clientId` (not by server `id`/`serverId`). Keep `clientId`
  flowing end-to-end through the WS frame, the REST fallback, and `Message`.
- **401 → refresh → retry → logout.** JWT TTL is 15 min (see `docs/api.md` §1.3).
  `ApiClient` / providers call `AuthProvider.refreshSession()` on 401; if the
  refresh fails, the user is logged out. Use `_handleApiException(e)` in
  `ChatProvider` rather than hand-rolling this.
- **Localization uses `.arb` files** in `lib/l10n/` with `flutter: generate: true`
  in `pubspec.yaml` — `AppLocalizations` is generated, do not edit
  `lib/l10n/app_localizations*.dart` by hand. Use `AppLocalizations.of(context)!`
  in widgets. Some legacy screens still inline Chinese strings — match the
  surrounding style, but prefer adding to `app_en.arb` and friends for new copy.
- **Colors live in `lib/core/app_colors.dart`.** Don't hardcode `Color(0x...)`
  in widgets; add/reuse an `AppColors` constant. Theme setup is in
  `lib/core/app_theme.dart`.
- **`relationCode` on members/conversations is language-neutral.** Localize at
  display time with `relationLabelFor()` from `lib/core/kinship/kinship_localizer.dart`,
  reactively on the current `LocaleProvider` locale — don't bake a locale into
  the fetch or the label goes stale on language switch.

## Architecture quick map

- `lib/main.dart` — `AuthGate` is the top-level router: watches `AuthProvider`
  and switches between `_SplashScreen` / `LoginScreen` / `MainShell` (5-tab
  bottom nav with a raised center FAB — see "Bottom nav layout" below).
- `lib/providers/auth_provider.dart` — created once at root; owns session, login,
  register (create-family / join-by-invite-code / join-by-phone), family
  lookup/join, profile update, invite-code generation, avatar upload.
- `lib/providers/chat_provider.dart` — created lazily inside `AuthGate` only
  after auth succeeds; receives the current `AuthUser`, a `ChatService`, and a
  `WebSocketService` or `MockWebSocketService`. Tearing down on logout
  closes the WS — do not let `ChatProvider` outlive `AuthGate`'s authenticated
  subtree.
- `lib/providers/location_provider.dart` — drives the §6.1 upload loop
  (1-minute `Timer.periodic` + first-fix-mandatory + last-gasp on
  AppLifecycleState.paused/detached + distance gate so "didn't move" samples
  are dropped). The `LocationScreen` is a separate consumer; the
  `LocationService.fetchFamilyLocations()` call goes through HTTP,
  not this provider.
- `lib/services/chat_service.dart` — REST: conversations, cursor-paginated
  message history (`before`/`nextCursor`), POST send-as-fallback.
- `lib/services/family_service.dart` — REST for §3.0/3.1/3.2/3.3/3.4 + §3.5.1
  (public `static submitJoinRequest` — no auth) / §3.5.2-3.5.3 (admin).
- `lib/services/location_service.dart` — REST for §6.1 / §6.2.
- `lib/services/websocket_service.dart` — connects with JWT as a query param,
  exponential-backoff reconnect capped at 6 attempts (doubles up to 30s),
  25s ping keepalive. Outbound JSON is hand-serialized via
  `WsOutboundMessage.toJsonString()` — no `dart:convert`.
- `lib/data/mock_data.dart` + `MockWebSocketService` — drive the no-backend
  demo path. Includes §6 mock locations (5 family members around Beijing with
  staggered freshness to exercise the "Online" / "Updated Xm ago" badges) and
  §3.5.2 mock join requests (two pending).
- `lib/core/kinship/` — pure-Dart family-graph engine + per-locale term tables
  (`terms_zh_hans.dart`, `terms_zh_hant.dart`, `terms_en.dart`, `terms_ja.dart`,
  `terms_ko.dart`, `terms_my.dart`). Used by `relationLabelFor` and the
  family-members UI; has its own unit tests in `test/kinship_engine_test.dart`.
- `lib/core/avatar_label.dart` — `memberAvatarLabel(name)` returns a 1-2 char
  abbreviation for the avatar fallback ("王" / "JS" / "?"). The
  `AvatarWidget` renders the full label (font shrinks for 2-char to fit the
  circle).

### Bottom nav layout (5 tabs with raised center FAB)

`MainShell` is a `Scaffold` with `floatingActionButtonLocation.centerDocked` —
the 4 outer tabs are `Row` items in `bottomNavigationBar`, the center slot is
empty (a `SizedBox(width: 60)` notcher), and the raised FAB sits on top of the
notch. Tab indices:
- 0 = Messages (`ConversationListScreen`)
- 1 = Contacts (`ContactsScreen` — streamlined "find someone to chat")
- **2 = My Home (raised FAB, `MyHomeScreen` — feature hub)**
- 3 = Family Feed (`FamilyFeedScreen` — placeholder, BUGS_TO_FIX.md "Coming soon")
- 4 = Profile (`ProfileScreen`)

If you add a new tab, update both the `_screens` list and the `_buildNavBar`
method; the FAB owns index 2 and the surrounding `EmptySpace` notch must stay
symmetric.

### Pushed-route provider scope

Anything pushed via `Navigator.push` from a tab loses access to `ChatProvider`
(the provider is created inside `AuthGate`'s authenticated subtree only). When
the new screen needs the provider, wrap the pushed route in
`ChangeNotifierProvider.value(value: chat, child: ...)`. Pattern is used by
`NewConversationScreen`, `ChatRoomScreen`, `ContactsScreen`,
`FamilyMembersScreen._MemberTile._startChat`.

### "My Home" feature hub

`MyHomeScreen` is intentionally a thin container — it only renders tile entries
that route to actual feature screens. Two entries today:
- **Real-time Location** (everyone) → `LocationScreen` (flutter_map + OSM +
  geolocator + the §6.1 upload loop in `LocationProvider`)
- **Join Requests** (admin only) → `JoinRequestsScreen` (§3.5.2-3.5.3)

When adding new "过家家" sub-apps, add the model in `lib/models/`, the
service in `lib/services/`, the provider (if state is needed) in
`lib/providers/`, the screen in `lib/screens/`, mock fixtures in
`MockDataSource`, l10n keys in all 7 `.arb` files, and a `_HubTile` entry in
`MyHomeScreen` gated on the appropriate role/feature check.

## Testing notes

- `test/widget_test.dart` is a placeholder (1+1==2). Real tests:
  - `test/kinship_engine_test.dart` — kinship engine BFS + reduction
  - `test/new_conversation_flow_test.dart` — `ChatProvider.startDirectConversation`
    + `Conversation.fromJson` (2 pre-existing failures on HttpClient 400 mocks
    — unchanged, not your problem unless you're touching that file)
  - `test/image_mime_test.dart` — magic-byte MIME sniffer
  - `test/join_request_test.dart` — §3.5.2 model parse + relationNoun mapping
  - `test/location_test.dart` — §6 model parse, freshness window, report
    serialization
- Lints are stock `flutter_lints` with `prefer_initializing_formals: false`
  (`analysis_options.yaml`).
- `.claude/settings.local.json` pre-approves `flutter analyze` and `flutter test`
  for Claude Code sessions; that doesn't apply to OpenCode — just run them.

## When changing things

- Touching a model? Update `fromJson`/`toJson`/`copyWith` and grep for callers
  in `lib/providers/` and `lib/services/`.
- Adding an authenticated network call? Use `ApiClient` (it injects the JWT
  and routes 401 through `AuthProvider.refreshSession()`); don't hand-build
  `http.Request`.
- Adding a screen that needs the current user or chat state? Reach for
  `context.watch<AuthProvider>()` / `context.watch<ChatProvider>()` — both are
  `ChangeNotifier`s via `provider`.
- New UI string? Add to every `lib/l10n/app_*.arb` (en, zh, zh_Hans, zh_Hant,
  ja, ko, my) — `flutter pub get` regenerates `AppLocalizations`.