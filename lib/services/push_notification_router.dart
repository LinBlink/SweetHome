import 'dart:async';

import 'package:flutter/material.dart';

import '../core/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../services/location_service.dart';
import '../main.dart';
import '../screens/fence_alarm_screen.dart';

/// Deep-link router for JPush notification taps. Server-side
/// fence-alarm pushes (see `docs/api.md` §6.7) carry `extras` like:
///
/// ```json
/// {"type": "fence_alarm", "alarmId": 123}
/// ```
///
/// The [PushService.onTap] stream feeds this router from outside the
/// widget tree (the JPush callback fires before any BuildContext is
/// available). Holds the tap until authentication is confirmed, then
/// navigates with the [rootNavigatorKey].
///
/// Single-fire router: each tap pushes a fresh [FenceAlarmScreen] and
/// exits — re-tapping the same notification deep-links again rather
/// than de-duplicating, matching the user expectation that a tap
/// should always go "to the thing the notification was about".
class PushNotificationRouter {
  PushNotificationRouter({
    required this.onTap,
    required this.tokenProvider,
    required this.isAuthenticated,
  });

  /// JPush tap stream — emits the `extras` map of the tapped
  /// notification. See [PushService.onTap].
  final Stream<Map<String, dynamic>> onTap;

  /// Resolves the current user's JWT at tap time. Returns null when
  /// the user has logged out between the notification's arrival and
  /// the tap (the JWT is no longer valid; the router drops the tap
  /// silently).
  final String? Function() tokenProvider;

  /// True when the user is currently authenticated. Taps arriving
  /// before login completes are queued and dispatched once the user
  /// signs in — covers the cold-launch case where the notification
  /// that opened the app is fired before [AuthGate] finishes its
  /// restore-from-cache.
  final bool Function() isAuthenticated;

  StreamSubscription<Map<String, dynamic>>? _sub;
  Map<String, dynamic>? _pendingTap;

  void start() {
    _sub ??= onTap.listen(_handleTap);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// Called by `AuthGate` once a restored session is confirmed so
  /// any cold-launch tap that arrived before auth was decided can
  /// finally route. Idempotent — safe to call multiple times.
  void flushPending() {
    final tap = _pendingTap;
    if (tap == null) return;
    _pendingTap = null;
    _dispatch(tap);
  }

  void _handleTap(Map<String, dynamic> extras) {
    if (!isAuthenticated()) {
      // Park the tap until auth resolves. Cold-launch from a
      // tapped notification goes through here: the notification
      // fires before `AuthGate` finishes its `restoreSession()`
      // round-trip, so `isAuthenticated()` is briefly false even
      // though we have a valid persisted session.
      _pendingTap = extras;
      return;
    }
    _dispatch(extras);
  }

  Future<void> _dispatch(Map<String, dynamic> extras) async {
    final type = extras['type'] as String?;
    if (type != 'fence_alarm') {
      // Unknown payload shape — future server-side notification
      // types (chat mentions, family invite) will land here.
      return;
    }
    final token = tokenProvider();
    if (token == null || token.isEmpty) return;
    final navigator = rootNavigatorKey.currentState;
    final context = navigator?.context;
    if (navigator == null || context == null || !context.mounted) {
      // Push notification arrived but the app isn't fully mounted
      // yet (extremely rare on cold launch). Park and let
      // `flushPending` retry on the next auth-state change.
      _pendingTap = extras;
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    // Refresh the alarm list before navigating so the screen opens
    // to the latest server-side state instead of a stale snapshot
    // — the push tells us "something happened" but the alarm
    // detail screen reads from the server.
    try {
      await LocationService(() => token).listFenceAlarms();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeErrorMessage(e.message, l10n))),
        );
      }
    } catch (_) {
      // best-effort — the alarm screen will re-fetch on its own
    }
    if (!context.mounted) return;
    await navigator.push(
      MaterialPageRoute(builder: (_) => const FenceAlarmScreen()),
    );
  }
}