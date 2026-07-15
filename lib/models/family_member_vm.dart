import '../core/kinship/kinship_graph.dart';
import '../core/time/backend_time.dart';

/// A family member as shown to the current viewer — `relationCode` is
/// already relative to whoever requested this (see docs/api.md §3.2/§七).
/// The backend only ever produces the language-neutral code; localize it
/// with `relationLabelFor()` at display time (the client owns translation).
class FamilyMemberVm {
  final int userId;
  final String name;
  final Gender gender;
  final String relationCode;
  final String? avatarUrl;
  final bool isOnline;
  final String role;

  const FamilyMemberVm({
    required this.userId,
    required this.name,
    required this.gender,
    required this.relationCode,
    required this.role,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory FamilyMemberVm.fromJson(Map<String, dynamic> json) {
    return FamilyMemberVm(
      userId: json['userId'] as int,
      name: json['name'] as String,
      gender: genderFromString(json['gender'] as String?),
      relationCode: json['relationCode'] as String? ?? 'SELF',
      role: json['role'] as String? ?? 'member',
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}

/// A family member preview shown during the "join family" flow, before the
/// joiner has picked a relation anchor (GET /families/lookup).
class FamilyMemberPreview {
  final int memberId;
  final String name;
  final Gender gender;
  final String? avatarUrl;

  const FamilyMemberPreview({
    required this.memberId,
    required this.name,
    required this.gender,
    this.avatarUrl,
  });

  factory FamilyMemberPreview.fromJson(Map<String, dynamic> json) {
    return FamilyMemberPreview(
      memberId: json['memberId'] as int,
      name: json['name'] as String,
      gender: genderFromString(json['gender'] as String?),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class FamilyPreview {
  final int familyId;
  final String familyName;
  final List<FamilyMemberPreview> members;

  const FamilyPreview({
    required this.familyId,
    required this.familyName,
    required this.members,
  });

  factory FamilyPreview.fromJson(Map<String, dynamic> json) {
    return FamilyPreview(
      familyId: json['familyId'] as int,
      familyName: json['familyName'] as String,
      members: (json['members'] as List)
          .map((m) => FamilyMemberPreview.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A freshly generated (or still-valid existing) family invite code —
/// see docs/api.md §3.3.
class InviteCodeInfo {
  final String inviteCode;
  final DateTime expiresAt;

  const InviteCodeInfo({required this.inviteCode, required this.expiresAt});

  factory InviteCodeInfo.fromJson(Map<String, dynamic> json) {
    return InviteCodeInfo(
      inviteCode: json['inviteCode'] as String,
      expiresAt: parseBackendTime(json['expiresAt'] as String),
    );
  }
}

/// `CHILD_OF` / `PARENT_OF` / `SPOUSE_OF` / `SIBLING_OF` — see docs/api.md §1.1.
enum RelationType { childOf, parentOf, spouseOf, siblingOf }

extension RelationTypeJson on RelationType {
  String get apiValue {
    switch (this) {
      case RelationType.childOf:
        return 'CHILD_OF';
      case RelationType.parentOf:
        return 'PARENT_OF';
      case RelationType.spouseOf:
        return 'SPOUSE_OF';
      case RelationType.siblingOf:
        return 'SIBLING_OF';
    }
  }
}
