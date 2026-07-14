import '../core/kinship/kinship_graph.dart';

/// A pending "申请加入家庭" submission as seen by the family admin —
/// see docs/api.md §3.5.2. The `relationType` here is the *requester's*
/// intended relationship to the family anchor member, identical in
/// shape to the value the requester would pass to `/auth/register`
/// (§1.1) or `/families/join` (§3.4): `CHILD_OF` / `PARENT_OF` /
/// `SPOUSE_OF` / `SIBLING_OF`. The client must localize this for
/// display via `relationLabelFor()` (it is a language-neutral code,
/// not a pre-translated string).
class JoinRequest {
  final int requestId;
  final String requesterName;
  final String requesterPhone;
  final String requesterGender; // 'male' / 'female'
  final String relationType; // CHILD_OF / PARENT_OF / SPOUSE_OF / SIBLING_OF
  final String targetMemberName;
  final String? message; // optional 200-char note from the requester
  final DateTime createdAt;
  final String status; // 'pending' / 'approved' / 'rejected' — admin UI
                      // only ever sees 'pending' (filter is enforced
                      // server-side via `?status=pending`).

  const JoinRequest({
    required this.requestId,
    required this.requesterName,
    required this.requesterPhone,
    required this.requesterGender,
    required this.relationType,
    required this.targetMemberName,
    required this.createdAt,
    required this.status,
    this.message,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requestId: json['requestId'] as int,
      requesterName: json['requesterName'] as String,
      requesterPhone: json['requesterPhone'] as String,
      requesterGender: json['requesterGender'] as String,
      relationType: json['relationType'] as String,
      targetMemberName: json['targetMemberName'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Maps the backend's `CHILD_OF` / `PARENT_OF` / `SPOUSE_OF` /
  /// `SIBLING_OF` to the noun keys the admin UI passes to
  /// `joinRequestsRelationLine({relation})`. The l10n strings
  /// (`relationNounChild/Parent/Spouse/Sibling`) are already
  /// translated into 6 languages — the screen does
  /// `l10n.relationNounChild` (etc.) based on this index.
  RelationNoun get relationNoun {
    switch (relationType) {
      case 'CHILD_OF':
        return RelationNoun.child;
      case 'PARENT_OF':
        return RelationNoun.parent;
      case 'SPOUSE_OF':
        return RelationNoun.spouse;
      case 'SIBLING_OF':
        return RelationNoun.sibling;
      default:
        return RelationNoun.unknown;
    }
  }
}

/// Enum index used to pick the correct `relationNoun*` l10n string
/// from the admin join-requests screen. Decoupling this from the
/// raw API string keeps the model Flutter-agnostic.
enum RelationNoun { child, parent, spouse, sibling, unknown }

// Re-export `Gender` for callers that want to disambiguate spouse
// wording via the localizer.
typedef JoinRequestGender = Gender;