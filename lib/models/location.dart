import '../core/time/backend_time.dart';

/// API §6 payload shapes — see docs/api.md §6.1 (`POST /location/report`)
/// and §6.2 (`GET /location/family`). The response includes a
/// pre-bucketed online/total pair (10-minute Redis-TTL count) plus a
/// member list; long-term history / trajectory replay is out of
/// scope for the current API.
class FamilyLocations {
  final int familyId;
  final String familyName;
  final int onlineMemberCount;
  final int totalMemberCount;
  final List<MemberLocation> familyMemberLocations;

  const FamilyLocations({
    required this.familyId,
    required this.familyName,
    required this.onlineMemberCount,
    required this.totalMemberCount,
    required this.familyMemberLocations,
  });

  factory FamilyLocations.fromJson(Map<String, dynamic> json) {
    final list = (json['familyMemberLocations'] as List? ?? const [])
        .map((e) => MemberLocation.fromJson(e as Map<String, dynamic>))
        .toList();
    return FamilyLocations(
      familyId: json['familyId'] as int,
      familyName: json['familyName'] as String,
      onlineMemberCount: json['onlineMemberCount'] as int,
      totalMemberCount: json['totalMemberCount'] as int,
      familyMemberLocations: list,
    );
  }
}

/// One member's last known location, as returned by §6.2.
/// `battery == -1` means the server's sentinel for "client didn't
/// report battery" (per §6.1 business logic).
class MemberLocation {
  final int userId;
  final String username;
  final String? userAvatarUrl;
  final double lng;
  final double lat;
  final int battery; // 0..100, or -1 for unknown
  final DateTime updatedAt;

  const MemberLocation({
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.lng,
    required this.lat,
    required this.battery,
    required this.updatedAt,
  });

  factory MemberLocation.fromJson(Map<String, dynamic> json) {
    return MemberLocation(
      userId: json['userId'] as int,
      username: json['username'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      battery: json['battery'] as int? ?? -1,
      updatedAt: parseBackendTime(json['updatedAt'] as String),
    );
  }

  /// "minutes since updatedAt", clamped at >= 0. Used by the
  /// "Updated Xm ago" label and the freshness badge.
  int get minutesAgo {
    final diff = DateTime.now().difference(updatedAt).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  /// True if the server-side 10-minute Redis TTL is still in effect
  /// (i.e. the position is fresh enough to show on the map).
  /// `onlineMemberCount` is the canonical source, but for individual
  /// rows we also want a per-member "is this dot green" hint — use
  /// the same 10-minute window.
  bool get isFresh =>
      DateTime.now().difference(updatedAt) <= const Duration(minutes: 10);
}

/// Body for `POST /location/report` (docs/api.md §6.1). `battery` is
/// optional — the server stores `-1` when null per the §6.1 business
/// rule. `updateTime` is the local time the GPS fix was captured, not
/// the time the HTTP request was sent — the server uses it for the
/// 120s/600s staleness checks.
///
/// Serialized as UTC+8 wall-clock without a timezone suffix to match
/// the backend's contract — see `parseBackendTime()` for the
/// symmetric reader.
class LocationReport {
  final double lng;
  final double lat;
  final int? battery;
  final DateTime updateTime;

  const LocationReport({
    required this.lng,
    required this.lat,
    required this.updateTime,
    this.battery,
  });

  Map<String, dynamic> toJson() => {
        'lng': lng,
        'lat': lat,
        if (battery != null) 'battery': battery,
        'updateTime': _formatBackendTime(updateTime),
      };

  /// Emits an ISO-8601 string in UTC+8 wall-clock time with no TZ
  /// suffix, matching the backend's contract (see `parseBackendTime`).
  /// Example: `2026-07-14T16:00:00.000` (was `2026-07-14T08:00:00.000Z`
  /// under the previous UTC contract).
  static String _formatBackendTime(DateTime dt) {
    final shifted = dt.toUtc().add(const Duration(hours: 8));
    final base = shifted.toIso8601String();
    // Strip trailing `Z` if present, then truncate to milliseconds.
    final noZ = base.endsWith('Z') ? base.substring(0, base.length - 1) : base;
    return noZ;
  }
}

/// One point in a member's trajectory history — docs/api.md §6.3.
/// `battery == -1` matches the §6.1 sentinel for "unknown".
class LocationHistoryPoint {
  final double lng;
  final double lat;
  final int battery;
  final DateTime updatedAt;

  const LocationHistoryPoint({
    required this.lng,
    required this.lat,
    required this.battery,
    required this.updatedAt,
  });

  factory LocationHistoryPoint.fromJson(Map<String, dynamic> json) {
    return LocationHistoryPoint(
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      battery: json['battery'] as int? ?? -1,
      updatedAt: parseBackendTime(json['updatedAt'] as String),
    );
  }
}

/// Response of `GET /location/{targetUserId}/history?date=YYYY-MM-DD`
/// (docs/api.md §6.3). The server returns `locations` sorted ASC by
/// `updatedAt` (oldest first) — the screen renders the polyline
/// directly in that order.
class LocationHistory {
  final int familyId;
  final String familyName;
  final int userId;
  final String username;
  final String? userAvatarUrl;
  final List<LocationHistoryPoint> locations;

  const LocationHistory({
    required this.familyId,
    required this.familyName,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.locations,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) {
    return LocationHistory(
      familyId: json['familyId'] as int,
      familyName: json['familyName'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      locations: (json['locations'] as List? ?? const [])
          .map((e) => LocationHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => locations.isEmpty;
}