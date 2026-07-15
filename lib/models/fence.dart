import '../core/time/backend_time.dart';

/// Geofence model — docs/api.md §6.4/§6.5/§6.6. The "setter" is the
/// family member who created the fence (the one who gets the
/// notification); "target" is the person whose location the fence
/// watches. From the API spec: a fence is a circle (center +
/// radius), so there are no polygon fields here.
class Fence {
  final int id;
  final String? name;
  final int setterUserId;
  final int targetUserId;
  final double fenceLng;
  final double fenceLat;
  final double fenceRange;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fence({
    required this.id,
    required this.name,
    required this.setterUserId,
    required this.targetUserId,
    required this.fenceLng,
    required this.fenceLat,
    required this.fenceRange,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Fence.fromJson(Map<String, dynamic> json) {
    return Fence(
      id: json['id'] as int,
      name: json['name'] as String?,
      setterUserId: json['setterUserId'] as int,
      targetUserId: json['targetUserId'] as int,
      fenceLng: (json['fenceLng'] as num).toDouble(),
      fenceLat: (json['fenceLat'] as num).toDouble(),
      fenceRange: (json['fenceRange'] as num).toDouble(),
      createdAt: parseBackendTime(json['createdAt'] as String),
      updatedAt: parseBackendTime(json['updatedAt'] as String),
    );
  }
}

/// One fence-alarm entry — docs/api.md §6.7. `fenceName` may be
/// `null` if the underlying fence has since been soft-deleted (per
/// the spec: "围栏之后被删除也不影响这条历史记录，只是 fenceName 会变成
/// null"). `targetUserId` / `targetUsername` / `targetUserAvatarUrl`
/// were snapshotted at alarm time so they survive the watched
/// person's avatar change too.
class FenceAlarm {
  final int id;
  final int fenceId;
  final String? fenceName;
  final String alarmType; // 'STEPPED_INSIDE' / 'STEPPED_OUTSIDE'
  final DateTime alarmedAt;
  final int targetUserId;
  final String targetUsername;
  final String? targetUserAvatarUrl;

  const FenceAlarm({
    required this.id,
    required this.fenceId,
    required this.fenceName,
    required this.alarmType,
    required this.alarmedAt,
    required this.targetUserId,
    required this.targetUsername,
    required this.targetUserAvatarUrl,
  });

  factory FenceAlarm.fromJson(Map<String, dynamic> json) {
    return FenceAlarm(
      id: json['id'] as int,
      fenceId: json['fenceId'] as int,
      fenceName: json['fenceName'] as String?,
      alarmType: json['alarmType'] as String? ?? 'STEPPED_OUTSIDE',
      alarmedAt: parseBackendTime(json['alarmedAt'] as String),
      targetUserId: json['targetUserId'] as int,
      targetUsername: json['targetUsername'] as String,
      targetUserAvatarUrl: json['targetUserAvatarUrl'] as String?,
    );
  }

  bool get isInside => alarmType == 'STEPPED_INSIDE';
}