import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/kinship/kinship_engine.dart';
import '../core/kinship/kinship_graph.dart';
import '../models/auth_models.dart';
import '../models/chat_models.dart';
import '../models/family_member_vm.dart';
import '../models/fence.dart';
import '../models/location.dart';

class MockDataSource {
  MockDataSource._();

  static final AuthUser mockUser = AuthUser(
    token: 'mock_token_abc123',
    refreshToken: 'mock_refresh_xyz789',
    userId: 1,
    name: '王建国',
    phone: '+8613800138000',
    familyId: 1,
    familyName: '王家',
    role: 'admin',
    gender: 'male',
  );

  /// The mock family's relation graph — the sole source of truth for
  /// relative kinship labels (see docs/api.md §七 / lib/core/kinship/).
  /// 王爷爷 is 王建国's father; 王建国+张美玲 are spouses and are jointly the
  /// parents of 王小明(哥哥) and 王小雨(妹妹, younger — see birthOrder).
  static final FamilyGraph familyGraph = FamilyGraph(
    members: const [
      FamilyMember(id: 1, name: '王建国', gender: Gender.male),
      FamilyMember(id: 2, name: '张美玲', gender: Gender.female),
      FamilyMember(id: 3, name: '王爷爷', gender: Gender.male),
      FamilyMember(id: 4, name: '王小明', gender: Gender.male, birthOrder: 1),
      FamilyMember(id: 5, name: '王小雨', gender: Gender.female, birthOrder: 2),
    ],
    relations: const [
      FamilyRelation(
        subjectId: 3,
        type: RelationEdgeType.parentOf,
        objectId: 1,
      ),
      FamilyRelation(
        subjectId: 1,
        type: RelationEdgeType.spouseOf,
        objectId: 2,
      ),
      FamilyRelation(
        subjectId: 1,
        type: RelationEdgeType.parentOf,
        objectId: 4,
      ),
      FamilyRelation(
        subjectId: 1,
        type: RelationEdgeType.parentOf,
        objectId: 5,
      ),
      FamilyRelation(
        subjectId: 2,
        type: RelationEdgeType.parentOf,
        objectId: 4,
      ),
      FamilyRelation(
        subjectId: 2,
        type: RelationEdgeType.parentOf,
        objectId: 5,
      ),
    ],
  );

  static final Map<int, Color> _avatarColorByMemberId = {
    1: AppColors.primary,
    2: AppColors.avatarColorFor(2),
    3: AppColors.avatarColorFor(3),
    4: AppColors.avatarColorFor(4),
    5: AppColors.avatarColorFor(5),
  };

  static Color avatarColorFor(int memberId) =>
      _avatarColorByMemberId[memberId] ?? AppColors.primary;

  /// Avatar circle content is always a name initial — purely visual, never a
  /// kinship term (avatar circles only render a single character; see
  /// docs/api.md §4.1 note on `avatarLabel`).
  static String avatarInitialFor(int memberId) {
    final member = familyGraph.memberById(memberId);
    if (member == null || member.name.isEmpty) return '?';
    return member.name.substring(0, 1);
  }

  /// The language-neutral relation code for [memberId] as seen by [viewerId]
  /// (defaults to the mock logged-in user) — mirrors what a real backend
  /// would put in `relationCode`. Localize with `relationLabelFor()` at
  /// display time; mock mode follows the same client-owns-translation rule
  /// as real mode (see docs/api.md §七), it just computes the code locally
  /// instead of receiving it from a server.
  static String relationCodeFor(int memberId, {int? viewerId}) {
    final viewer = viewerId ?? mockUser.userId;
    final path = computeRelationPath(familyGraph, viewer, memberId);
    return relationCode(path);
  }

  static List<FamilyMemberVm> membersFor({required int viewerId}) {
    return familyGraph.members.map((m) {
      return FamilyMemberVm(
        userId: m.id,
        name: m.name,
        gender: m.gender,
        relationCode: relationCodeFor(m.id, viewerId: viewerId),
        role: m.id == mockUser.userId ? 'admin' : 'member',
      );
    }).toList();
  }

  static const String _inviteCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Mock mode has nothing to persist an invite code against, so this just
  /// returns a plausible-looking random 8-char code each call.
  static String randomInviteCode() {
    final rand = Random();
    return List.generate(
      8,
      (_) => _inviteCodeAlphabet[rand.nextInt(_inviteCodeAlphabet.length)],
    ).join();
  }

  /// Mock mode doesn't validate the invite code — any code previews the
  /// single mock family, so the "join family" flow can be exercised
  /// end-to-end without a backend.
  static FamilyPreview lookupByInviteCode(String code) {
    return FamilyPreview(
      familyId: 1,
      familyName: '王家',
      members: familyGraph.members
          .map(
            (m) => FamilyMemberPreview(
              memberId: m.id,
              name: m.name,
              gender: m.gender,
            ),
          )
          .toList(),
    );
  }

  static final List<Conversation> conversations = [
    Conversation(
      id: 1,
      name: '王家群聊',
      isGroup: true,
      avatarLabel: '家',
      avatarColor: AppColors.primary,
      lastMessage: '晚饭准备好了，快回家吃饭！',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 3)),
      unreadCount: 5,
      memberCount: 6,
    ),
    Conversation(
      id: 2,
      name: '张美玲',
      isGroup: false,
      avatarLabel: avatarInitialFor(2),
      avatarColor: avatarColorFor(2),
      relationCode: relationCodeFor(2),
      otherUserGender: Gender.female,
      otherUserId: 2,
      lastMessage: '今天超市打折，我去买点菜',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 1,
      memberCount: 2,
    ),
    Conversation(
      id: 3,
      name: '王小明',
      isGroup: false,
      avatarLabel: avatarInitialFor(4),
      avatarColor: avatarColorFor(4),
      relationCode: relationCodeFor(4),
      otherUserGender: Gender.male,
      otherUserId: 4,
      lastMessage: '爸，作业做完了！',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      memberCount: 2,
    ),
  ];

  static final Map<int, List<Message>> _messages = {
    1: _buildGroupMessages(),
    2: _buildDirectMessages(),
    3: _buildSonMessages(),
  };

  static List<Message> messagesFor(int convId) =>
      List.from(_messages[convId] ?? []);

  static List<Message> _buildGroupMessages() {
    final now = DateTime.now();
    return [
      _msg(
        id: 'g1',
        convId: 1,
        senderId: 2,
        name: '张美玲',
        content: '早上好大家！今天天气不错',
        time: now.subtract(const Duration(hours: 8)),
      ),
      _msg(
        id: 'g2',
        convId: 1,
        senderId: 3,
        name: '王爷爷',
        content: '早，我去公园打太极了',
        time: now.subtract(const Duration(hours: 7, minutes: 50)),
      ),
      _msg(
        id: 'g3',
        convId: 1,
        senderId: 4,
        name: '王小明',
        content: '爸爸妈妈早安！我去上学了',
        time: now.subtract(const Duration(hours: 7, minutes: 30)),
      ),
      _msg(
        id: 'g4',
        convId: 1,
        senderId: 1,
        name: '王建国',
        isMe: true,
        content: '小明上学路上注意安全！',
        time: now.subtract(const Duration(hours: 7, minutes: 28)),
      ),
      _msg(
        id: 'g5',
        convId: 1,
        senderId: 5,
        name: '王小雨',
        content: '哥哥等等我一起走！',
        time: now.subtract(const Duration(hours: 7, minutes: 25)),
      ),
      _msg(
        id: 'g6',
        convId: 1,
        senderId: 2,
        name: '张美玲',
        content: '中午我做红烧肉，大家早点回来',
        time: now.subtract(const Duration(hours: 4)),
      ),
      _msg(
        id: 'g7',
        convId: 1,
        senderId: 3,
        name: '王爷爷',
        content: '好好好，我最爱吃红烧肉了',
        time: now.subtract(const Duration(hours: 3, minutes: 58)),
      ),
      _msg(
        id: 'g8',
        convId: 1,
        senderId: 1,
        name: '王建国',
        isMe: true,
        content: '妈做饭辛苦了！我五点钟到家',
        time: now.subtract(const Duration(hours: 3, minutes: 55)),
      ),
      _msg(
        id: 'g9',
        convId: 1,
        senderId: 2,
        name: '张美玲',
        content: '晚饭准备好了，快回家吃饭！',
        time: now.subtract(const Duration(minutes: 3)),
      ),
    ];
  }

  static List<Message> _buildDirectMessages() {
    final now = DateTime.now();
    return [
      _msg(
        id: 'd1',
        convId: 2,
        senderId: 2,
        name: '张美玲',
        content: '老公，下班别忘了买酱油',
        time: now.subtract(const Duration(hours: 2)),
      ),
      _msg(
        id: 'd2',
        convId: 2,
        senderId: 1,
        name: '王建国',
        isMe: true,
        content: '好的，还需要别的吗？',
        time: now.subtract(const Duration(hours: 1, minutes: 58)),
      ),
      _msg(
        id: 'd3',
        convId: 2,
        senderId: 2,
        name: '张美玲',
        content: '今天超市打折，我去买点菜',
        time: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  static List<Message> _buildSonMessages() {
    final now = DateTime.now();
    return [
      _msg(
        id: 's1',
        convId: 3,
        senderId: 4,
        name: '王小明',
        content: '爸，今天数学考了98分！',
        time: now.subtract(const Duration(hours: 5)),
      ),
      _msg(
        id: 's2',
        convId: 3,
        senderId: 1,
        name: '王建国',
        isMe: true,
        content: '厉害！继续加油，晚上奖励你打游戏一小时',
        time: now.subtract(const Duration(hours: 4, minutes: 55)),
      ),
      _msg(
        id: 's3',
        convId: 3,
        senderId: 4,
        name: '王小明',
        content: '爸，作业做完了！',
        time: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  static Message _msg({
    required String id,
    required int convId,
    required int senderId,
    required String name,
    required String content,
    required DateTime time,
    bool isMe = false,
  }) {
    return Message(
      clientId: id,
      serverId: int.tryParse(id.replaceAll(RegExp(r'[a-z]'), '')),
      conversationId: convId,
      senderId: senderId,
      senderName: name,
      senderAvatarLabel: avatarInitialFor(senderId),
      senderAvatarColor: avatarColorFor(senderId),
      content: content,
      type: MessageType.text,
      sentAt: time,
      isMe: isMe,
      senderRelationCode: isMe ? null : relationCodeFor(senderId),
      senderGender: familyGraph.memberById(senderId)?.gender,
    );
  }

  static final List<String> _incomingTexts = [
    '你们在聊什么呢？',
    '今天天气真好，出去走走吧！',
    '晚上吃什么？',
    '我到家了，大家放心',
    '小明，作业做完了吗？',
    '爸，我想吃妈妈做的饺子',
    '周末我们去公园野餐好不好？',
    '爷爷，您身体最近怎么样？',
    '妈，超市酸奶打折了，我买了几盒',
    '今天好累啊，早点休息吧',
    '周末谁有空？一起看电影',
    '孩子们要多喝水，天热了',
  ];

  static int _incomingIndex = 0;

  static Message randomIncomingMessage(int convId) {
    final text = _incomingTexts[_incomingIndex % _incomingTexts.length];
    _incomingIndex++;
    return Message(
      clientId: 'mock_in_$_incomingIndex',
      conversationId: convId,
      senderId: 2,
      senderName: '张美玲',
      senderAvatarLabel: avatarInitialFor(2),
      senderAvatarColor: avatarColorFor(2),
      content: text,
      type: MessageType.text,
      sentAt: DateTime.now(),
      isMe: false,
      senderRelationCode: relationCodeFor(2),
      senderGender: familyGraph.memberById(2)?.gender,
    );
  }

  // -- §6 mock location fixtures -------------------------------------
  // Five family members anchored around Beijing with offsets chosen
  // so the map auto-fits to a single viewport. `updatedAt` varies
  // across members so the freshness badge ("Online" / "Updated Xm
  // ago") shows a non-uniform mix on the LocationScreen.

  static FamilyLocations _familyLocationsFixture() {
    final now = DateTime.now();
    final List<_MockMemberLocation> mocks = [
      _MockMemberLocation(
        userId: 1,
        username: '王建国',
        lng: 116.3975,
        lat: 39.9087,
        battery: 78,
        minutesAgo: 0,
      ),
      _MockMemberLocation(
        userId: 2,
        username: '张美玲',
        lng: 116.4125,
        lat: 39.9045,
        battery: 64,
        minutesAgo: 2,
      ),
      _MockMemberLocation(
        userId: 3,
        username: '王爷爷',
        lng: 116.3855,
        lat: 39.9213,
        battery: 42,
        minutesAgo: 5,
      ),
      _MockMemberLocation(
        userId: 4,
        username: '王小明',
        lng: 116.4310,
        lat: 39.9012,
        battery: 91,
        minutesAgo: 8,
      ),
      _MockMemberLocation(
        userId: 5,
        username: '王小雨',
        lng: 116.4310,
        lat: 39.9012,
        battery: 88,
        minutesAgo: 12, // intentionally past the 10-min freshness window
      ),
    ];
    return FamilyLocations(
      familyId: 1,
      familyName: '王家',
      onlineMemberCount: 4, // 王小雨 is past the 10-min window
      totalMemberCount: 5,
      familyMemberLocations: [
        for (final m in mocks)
          MemberLocation(
            userId: m.userId,
            username: m.username,
            userAvatarUrl: null,
            lng: m.lng,
            lat: m.lat,
            battery: m.battery,
            updatedAt: now.subtract(Duration(minutes: m.minutesAgo)),
          ),
      ],
    );
  }

  /// Mock-mode stub for `LocationService.fetchFamilyLocations`. The
  /// screen should branch on `AppConfig.mockMode` and call this
  /// instead of going through the HTTP client.
  static FamilyLocations mockFamilyLocations() => _familyLocationsFixture();

  // -- §6.3 mock trajectory history ---------------------------------
  // Synthesizes a believable ~30-point trail for 王小明 between
  // 08:00 and 13:00 on the queried day (school → lunch → back
  // home) so the new LocationHistoryScreen has a non-empty default
  // state in mock mode.

  static LocationHistory _historyFixture(int targetUserId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final member = familyGraph.memberById(targetUserId);
    final name = member?.name ?? 'Member $targetUserId';
    // Anchor near 116.4310,39.9012 (王小明's "school" base in the
    // §6.2 fixture). Walk out to lunch and back.
    final base = const _LngLat(116.4310, 39.9012);
    final lunch = const _LngLat(116.4125, 39.9045);
    final List<_LngLat> trail = [];
    for (int i = 0; i < 10; i++) {
      final t = i / 9;
      trail.add(_LngLat(
        base.lng + (lunch.lng - base.lng) * t,
        base.lat + (lunch.lat - base.lat) * t,
      ));
    }
    for (int i = 1; i < 10; i++) {
      final t = i / 9;
      trail.add(_LngLat(
        lunch.lng + (base.lng - lunch.lng) * t,
        lunch.lat + (base.lat - lunch.lat) * t,
      ));
    }
    // Sample every ~10 minutes from 08:00 to 13:00 → 31 points.
    return LocationHistory(
      familyId: 1,
      familyName: '王家',
      userId: targetUserId,
      username: name,
      userAvatarUrl: null,
      locations: List.generate(trail.length, (i) {
        final hour = 8 + (i * 10) ~/ 60;
        final minute = (i * 10) % 60;
        return LocationHistoryPoint(
          lng: trail[i].lng,
          lat: trail[i].lat,
          battery: 92 - (i ~/ 4),
          updatedAt: today.add(Duration(hours: hour, minutes: minute)),
        );
      }),
    );
  }

  /// Mock-mode stub for `LocationService.fetchLocationHistory`.
  static LocationHistory mockLocationHistory({required int targetUserId}) =>
      _historyFixture(targetUserId);

  // -- §6.6 mock fence fixtures -------------------------------------
  // Two pre-set fences for the family: one set by the admin (王建国)
  // for 王小明 around his school, another by 王建国 for 王爷爷 around
  // his usual park. Exercised by MyHomeScreen → FenceListScreen.

  static List<Fence> _fenceFixture() {
    final now = DateTime.now();
    return [
      Fence(
        id: 1,
        name: '学校',
        setterUserId: 1,
        targetUserId: 4,
        fenceLng: 116.4310,
        fenceLat: 39.9012,
        fenceRange: 200,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Fence(
        id: 2,
        name: '公园',
        setterUserId: 1,
        targetUserId: 3,
        fenceLng: 116.3855,
        fenceLat: 39.9213,
        fenceRange: 300,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<Fence> mockFences() => List.unmodifiable(_fenceFixture());

  // -- §6.7 mock fence-alarm fixtures -------------------------------
  // Three recent alarms: one entry (school), one exit (school),
  // one exit (park — 王爷爷 went for a walk outside his usual
  // spot).

  static List<FenceAlarm> _fenceAlarmFixture() {
    final now = DateTime.now();
    return [
      FenceAlarm(
        id: 10,
        fenceId: 1,
        fenceName: '学校',
        alarmType: 'STEPPED_OUTSIDE',
        alarmedAt: now.subtract(const Duration(minutes: 25)),
        targetUserId: 4,
        targetUsername: '王小明',
        targetUserAvatarUrl: null,
      ),
      FenceAlarm(
        id: 9,
        fenceId: 1,
        fenceName: '学校',
        alarmType: 'STEPPED_INSIDE',
        alarmedAt: now.subtract(const Duration(hours: 2, minutes: 10)),
        targetUserId: 4,
        targetUsername: '王小明',
        targetUserAvatarUrl: null,
      ),
      FenceAlarm(
        id: 8,
        fenceId: 2,
        fenceName: '公园',
        alarmType: 'STEPPED_OUTSIDE',
        alarmedAt: now.subtract(const Duration(hours: 5)),
        targetUserId: 3,
        targetUsername: '王爷爷',
        targetUserAvatarUrl: null,
      ),
    ];
  }

  static List<FenceAlarm> mockFenceAlarms() =>
      List.unmodifiable(_fenceAlarmFixture());

}

/// Internal struct used only by the mock location fixture above —
/// keeps the inline list tidy without polluting the public model
/// surface.
class _LngLat {
  final double lng;
  final double lat;
  const _LngLat(this.lng, this.lat);
}

/// Internal struct used only by the mock location fixture above —
/// keeps the inline list tidy without polluting the public model
/// surface.
class _MockMemberLocation {
  final int userId;
  final String username;
  final double lng;
  final double lat;
  final int battery;
  final int minutesAgo;

  const _MockMemberLocation({
    required this.userId,
    required this.username,
    required this.lng,
    required this.lat,
    required this.battery,
    required this.minutesAgo,
  });
}
