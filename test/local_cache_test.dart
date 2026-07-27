import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweethome_flutter/core/kinship/kinship_graph.dart';
import 'package:sweethome_flutter/models/auth_models.dart';
import 'package:sweethome_flutter/models/family_member_vm.dart';
import 'package:sweethome_flutter/providers/auth_provider.dart';
import 'package:sweethome_flutter/services/local_cache_store.dart';

/// The "show what we had, check the server behind it" path that the
/// contacts / family-tree / message screens all sit on. These are the
/// behaviours that are invisible when they break — the app still
/// works, it just goes back to spinning on every entry — so they get
/// asserted rather than eyeballed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AuthUser userWith({int userId = 7, int familyId = 1}) => AuthUser(
        token: 't',
        refreshToken: 'r',
        userId: userId,
        name: 'Tester',
        phone: '13800000000',
        familyId: familyId,
        familyName: 'Home',
        role: 'member',
        gender: 'female',
      );

  FamilyMemberVm memberWith({
    int userId = 2,
    String name = 'Mum',
    String relationCode = 'M',
    DateTime? birthDate,
  }) =>
      FamilyMemberVm(
        userId: userId,
        name: name,
        gender: Gender.female,
        relationCode: relationCode,
        role: 'member',
        birthDate: birthDate,
      );

  group('LocalCacheStore', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('round-trips a payload', () async {
      const store = LocalCacheStore('things');
      expect(await store.read('1'), isNull);

      await store.write('1', [
        {'a': 1},
      ]);

      expect(await store.read('1'), [
        {'a': 1},
      ]);
      expect(await store.writtenAt('1'), isNotNull);
    });

    test('keeps scopes apart', () async {
      const store = LocalCacheStore('things');
      await store.write('1', 'one');
      await store.write('2', 'two');

      expect(await store.read('1'), 'one');
      expect(await store.read('2'), 'two');

      await store.clear('1');
      expect(await store.read('1'), isNull);
      expect(await store.read('2'), 'two',
          reason: 'clearing one user must not touch another');
    });

    test('a payload from another schema version is dropped, not parsed',
        () async {
      const v1 = LocalCacheStore('things');
      const v2 = LocalCacheStore('things', schemaVersion: 2);
      await v1.write('1', 'old shape');

      expect(await v2.read('1'), isNull);
      expect(await v1.read('1'), isNull,
          reason: 'the mismatched blob should have been deleted on read, '
              'not left behind to be re-read forever');
    });

    test('a corrupt blob reads as a miss instead of throwing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cache_v2_things_1': '{not json',
      });
      const store = LocalCacheStore('things');

      expect(await store.read('1'), isNull);
    });

    test('clearAll wipes every scope of the namespace', () async {
      const store = LocalCacheStore('things');
      const other = LocalCacheStore('unrelated');
      await store.write('1', 'a');
      await store.write('2', 'b');
      await other.write('1', 'keep me');

      await store.clearAll();

      expect(await store.read('1'), isNull);
      expect(await store.read('2'), isNull);
      expect(await other.read('1'), 'keep me');
    });
  });

  group('FamilyMemberVm', () {
    test('survives a trip through the cache unchanged', () {
      final original = memberWith(birthDate: DateTime(1968, 3, 4));
      final restored = FamilyMemberVm.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.birthDate, DateTime(1968, 3, 4));
    });
  });

  group('AuthProvider family members', () {
    late AuthProvider auth;
    late int fetches;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      fetches = 0;
      auth = AuthProvider();
      auth.debugSetSession(userWith());
    });

    tearDown(() => auth.dispose());

    test('concurrent callers share one request', () async {
      auth.debugFetchMembers = (_) async {
        fetches++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return [memberWith()];
      };

      // What actually happens on launch: the message list warms
      // genders while contacts and the tree both ask for the list.
      await Future.wait([
        auth.loadFamilyMembers(),
        auth.loadFamilyMembers(),
        auth.loadFamilyMembers(),
      ]);

      expect(fetches, 1,
          reason: 'three screens asking at once is still one round-trip');
    });

    test('a second session reads the list from disk before fetching',
        () async {
      auth.debugFetchMembers = (_) async {
        fetches++;
        return [memberWith()];
      };
      await auth.loadFamilyMembers();
      expect(fetches, 1);

      // Cold start: new provider, same device, same user. The refresh
      // is left hanging, standing in for a slow network — the whole
      // point is that the screen does not wait for it.
      final next = AuthProvider();
      addTearDown(next.dispose);
      next.debugSetSession(userWith());
      final slow = Completer<List<FamilyMemberVm>>();
      var started = 0;
      next.debugFetchMembers = (_) {
        started++;
        return slow.future;
      };

      final members = await next.loadFamilyMembers();

      expect(members.single.name, 'Mum',
          reason: 'served from disk while the network call is still open');
      expect(next.familyMembers, isNotNull,
          reason: 'the screen must have something to paint immediately');
      expect(started, 1, reason: 'and the check still went out behind it');

      slow.complete([memberWith()]);
    });

    test('an unchanged server response causes no rebuild', () async {
      auth.debugFetchMembers = (_) async => [memberWith()];
      await auth.loadFamilyMembers();

      var notifications = 0;
      auth.addListener(() => notifications++);
      await auth.loadFamilyMembers(force: true);

      expect(notifications, 0,
          reason: 'nothing moved, so no listener should have to repaint');
    });

    test('a changed server response updates and repaints', () async {
      auth.debugFetchMembers = (_) async => [memberWith(name: 'Mum')];
      await auth.loadFamilyMembers();

      var notifications = 0;
      auth.addListener(() => notifications++);
      auth.debugFetchMembers = (_) async => [
            memberWith(name: 'Mum'),
            memberWith(userId: 3, name: 'Dad', relationCode: 'F'),
          ];
      await auth.loadFamilyMembers(force: true);

      expect(notifications, greaterThan(0));
      expect(auth.familyMembers, hasLength(2));
    });

    test('a failed background refresh keeps the cached list', () async {
      auth.debugFetchMembers = (_) async => [memberWith()];
      await auth.loadFamilyMembers();

      auth.debugFetchMembers = (_) async => throw Exception('offline');
      final members = await auth.loadFamilyMembers();
      // Let the background revalidation fail.
      await Future<void>.delayed(Duration.zero);

      expect(members.single.name, 'Mum');
      expect(auth.familyMembers, hasLength(1),
          reason: 'an offline launch still shows the last known family');
    });

    test('logging out drops the list from memory and disk', () async {
      auth.debugFetchMembers = (_) async => [memberWith()];
      await auth.loadFamilyMembers();

      await auth.logout();

      expect(auth.familyMembers, isNull);
      const store = LocalCacheStore('family_members');
      expect(await store.read('7'), isNull,
          reason: "the next account on this device must not see the "
              'previous one’s family');
    });
  });
}
