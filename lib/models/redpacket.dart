import '../core/time/backend_time.dart';

/// Red packet status — docs/api.md §9.5.
enum RedpacketStatus {
  /// Still has shares left to grab.
  ongoing,

  /// All `totalCount` shares have been grabbed.
  finished,

  /// Reached the 24-hour expiry while shares were still ungrabbed.
  /// Per §9.5, a grab attempt that races the expiry flips the state
  /// here; the actual refund of remaining shares happens via the
  /// background scan and surfaces as [refunded].
  expired,

  /// Background scan ran; ungrabbed shares were refunded to the
  /// sender and this is the terminal state.
  refunded,
}

RedpacketStatus redpacketStatusFromString(String? raw) {
  switch (raw) {
    case 'ongoing':
      return RedpacketStatus.ongoing;
    case 'finished':
      return RedpacketStatus.finished;
    case 'expired':
      return RedpacketStatus.expired;
    case 'refunded':
      return RedpacketStatus.refunded;
  }
  return RedpacketStatus.ongoing;
}

/// Inverse of [redpacketStatusFromString] — wire value for §9.1
/// `POST /redpacket` request bodies. Not used in the current
/// frontend (the server doesn't accept a status on create), but
/// kept here for completeness in case future endpoints accept it.
String redpacketStatusToWire(RedpacketStatus s) {
  switch (s) {
    case RedpacketStatus.ongoing:
      return 'ongoing';
    case RedpacketStatus.finished:
      return 'finished';
    case RedpacketStatus.expired:
      return 'expired';
    case RedpacketStatus.refunded:
      return 'refunded';
  }
}

/// §9.1/§9.2 response payload — `RedpacketVO`. All money values are
/// in **分 (cents)** as documented in the §9 preamble ("金额单位统一
/// 为「分」（整数）"). Display layers divide by 100 and format with
/// two decimals — never use the raw int for display.
class Redpacket {
  final int id;
  final int userId;
  final int totalAmount;
  final int totalCount;
  final RedpacketStatus status;
  final DateTime expiredAt;
  final DateTime createdAt;

  const Redpacket({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.totalCount,
    required this.status,
    required this.expiredAt,
    required this.createdAt,
  });

  factory Redpacket.fromJson(Map<String, dynamic> json) {
    return Redpacket(
      id: json['id'] as int,
      userId: json['userId'] as int,
      totalAmount: json['totalAmount'] as int,
      totalCount: json['totalCount'] as int,
      status: redpacketStatusFromString(json['status'] as String?),
      // §9.1 timestamps come back as naive ISO-8601 in UTC+8 (per the
      // backend_time contract); fall back to now() if missing so a
      // future server change doesn't crash the parse.
      expiredAt: json['expiredAt'] != null
          ? parseBackendTime(json['expiredAt'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? parseBackendTime(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// §9.3 response payload + §9.4/§9.6 array element — `RedpacketGrabVO`.
/// `grabAmount` is the authoritative amount the user got from this
/// grab; per §9's preamble the client should display it *immediately*
/// rather than waiting for the grab-list endpoint to catch up.
///
/// [id] is **nullable**: per §9.3, the grab happens instantly in
/// Redis and the DB row is backfilled asynchronously, so the §9.3
/// response always carries `id: null` — the auto-increment id doesn't
/// exist yet at the moment the response is built. It's only populated
/// once fetched via §9.4/§9.6 after the async write lands. Never key
/// de-duplication or "have I already grabbed" checks off [id] for
/// that reason — use [userId] instead (each user can grab a given red
/// packet at most once).
///
/// The same `RedpacketGrabVO` shape is reused by three endpoints, but
/// each fills in a different subset of the two "extra user info"
/// groups — the other group is always `null`:
/// - §9.3 (grab): neither group filled — [username]/[userAvatarUrl]
///   and [redpacketOwnerId]/[redpacketOwnerUsername]/
///   [redpacketOwnerUserAvatarUrl] are all `null`.
/// - §9.4 (grab list for one red packet): [username]/[userAvatarUrl]
///   filled (who grabbed) — the owner-group stays `null`.
/// - §9.6 (my received red packets): [redpacketOwnerId]/
///   [redpacketOwnerUsername]/[redpacketOwnerUserAvatarUrl] filled
///   (who sent it) — the grabber-group stays `null` since the
///   grabber is always the caller themself.
class RedpacketGrab {
  final int? id;
  final int redpacketId;
  final int userId;
  final int grabAmount;
  final DateTime createdAt;

  /// §9.4-only: the grabber's nickname/avatar.
  final String? username;
  final String? userAvatarUrl;

  /// §9.6-only: the red packet sender's id/nickname/avatar.
  final int? redpacketOwnerId;
  final String? redpacketOwnerUsername;
  final String? redpacketOwnerUserAvatarUrl;

  const RedpacketGrab({
    required this.id,
    required this.redpacketId,
    required this.userId,
    required this.grabAmount,
    required this.createdAt,
    this.username,
    this.userAvatarUrl,
    this.redpacketOwnerId,
    this.redpacketOwnerUsername,
    this.redpacketOwnerUserAvatarUrl,
  });

  factory RedpacketGrab.fromJson(Map<String, dynamic> json) {
    return RedpacketGrab(
      id: json['id'] as int?,
      redpacketId: json['redpacketId'] as int,
      userId: json['userId'] as int,
      grabAmount: json['grabAmount'] as int,
      createdAt: json['createdAt'] != null
          ? parseBackendTime(json['createdAt'] as String)
          : DateTime.now(),
      username: json['username'] as String?,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      redpacketOwnerId: json['redpacketOwnerId'] as int?,
      redpacketOwnerUsername: json['redpacketOwnerUsername'] as String?,
      redpacketOwnerUserAvatarUrl:
          json['redpacketOwnerUserAvatarUrl'] as String?,
    );
  }
}