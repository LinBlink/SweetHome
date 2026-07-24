import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweethome_flutter/models/auth_models.dart';
import 'package:sweethome_flutter/providers/moment_provider.dart';
import 'package:sweethome_flutter/services/moment_service.dart';

/// Lightweight stubs — the provider ctor takes `service: dynamic` and
/// the `setActiveFeedScope` round-trip we want to exercise here
/// doesn't touch any of the service methods (only the SharedPreferences
/// read/write path). Tests that hit the service are kept out of scope
/// for this file; they're better exercised via widget/integration
/// tests that stub the HTTP layer properly.

AuthUser _user() => AuthUser(
      token: 't',
      refreshToken: 'r',
      userId: 1,
      name: 'me',
      phone: '+861234',
      familyId: 1,
      familyName: 'f',
      role: 'member',
      gender: 'male',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MomentProvider.activeFeedScope / setActiveFeedScope', () {
    setUp(() async {
      // Always start with a clean prefs store so leftover state from
      // another test group can't leak in.
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('defaults to family when SharedPreferences has no value', () async {
      // Hydration is async (kicked off in ctor); drain microtasks so
      // the disk read completes before we inspect the field.
      final provider = MomentProvider(
        currentUser: _user(),
        service: MomentService(() => 't'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.activeFeedScope, MomentFeedScope.family);
    });

    test('hydrates from SharedPreferences on construction', () async {
      // Pre-seed prefs so the hydrate() coroutine in the ctor reads
      // `public`. The async read may complete either before or after
      // the assertion below, so we drain microtasks until it
      // resolves (with a sane timeout).
      SharedPreferences.setMockInitialValues(<String, Object>{
        'moments_feed_scope_v1_1': 'public',
      });
      final provider = MomentProvider(
        currentUser: _user(),
        service: MomentService(() => 't'),
      );
      // Spin until the async hydration finishes — bound by a
      // generous iteration count to avoid hanging the test suite if
      // the read never settles.
      for (var i = 0; i < 50; i++) {
        if (provider.activeFeedScope == MomentFeedScope.public) break;
        await Future<void>.delayed(Duration.zero);
      }
      expect(provider.activeFeedScope, MomentFeedScope.public);
    });

    test('setActiveFeedScope is idempotent (no notify on unchanged)', () async {
      // The setter's no-op fast path is what keeps the
      // [FamilyFeedScreen]'s `_FeedScopeTabs` Builder from re-syncing
      // the TabController on every notify. Verify it by listening
      // for notifyListeners() and counting emissions across one
      // idempotent call + one real change.
      final provider = MomentProvider(
        currentUser: _user(),
        service: MomentService(() => 't'),
      );
      await Future<void>.delayed(Duration.zero);
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Same as current → no notify.
      final before = notifyCount;
      provider.setActiveFeedScope(MomentFeedScope.family);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, before);

      // Different → exactly one notify.
      provider.setActiveFeedScope(MomentFeedScope.public);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, before + 1);
      expect(provider.activeFeedScope, MomentFeedScope.public);
    });

    test('writes the new scope through to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = MomentProvider(
        currentUser: _user(),
        service: MomentService(() => 't'),
      );
      await Future<void>.delayed(Duration.zero);
      provider.setActiveFeedScope(MomentFeedScope.public);
      // Wait for the fire-and-forget prefs write to complete.
      var prefs = await SharedPreferences.getInstance();
      var stored = prefs.getString('moments_feed_scope_v1_1');
      for (var i = 0; i < 50 && stored != 'public'; i++) {
        await Future<void>.delayed(Duration.zero);
        prefs = await SharedPreferences.getInstance();
        stored = prefs.getString('moments_feed_scope_v1_1');
      }
      expect(stored, 'public');
    });
  });
}
