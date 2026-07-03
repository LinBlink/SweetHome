enum Gender { male, female }

/// Parses the API's `gender` string (`'male'`/`'female'`) — see
/// docs/api.md §3.2/§4.1/§4.3. Defaults to [Gender.male] for null/unknown.
Gender genderFromString(String? s) => s == 'female' ? Gender.female : Gender.male;

enum RelationEdgeType { parentOf, spouseOf }

class FamilyMember {
  final int id;
  final String name;
  final Gender gender;

  /// Sibling age ranking within the same parents; lower = older. Null = unknown
  /// (the algorithm then defaults to treating the member as the elder side).
  final int? birthOrder;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.gender,
    this.birthOrder,
  });
}

class FamilyRelation {
  final int subjectId;
  final RelationEdgeType type;
  final int objectId;

  const FamilyRelation({
    required this.subjectId,
    required this.type,
    required this.objectId,
  });
}

/// A family's blood/marriage relation graph: PARENT_OF (directed) + SPOUSE_OF
/// (undirected) edges over a set of members. This is the sole data source the
/// kinship engine needs — no relation text is ever stored.
class FamilyGraph {
  final Map<int, FamilyMember> _members;
  final List<FamilyRelation> _relations;

  FamilyGraph({required List<FamilyMember> members, required List<FamilyRelation> relations})
      : _members = {for (final m in members) m.id: m},
        _relations = relations;

  FamilyMember? memberById(int id) => _members[id];

  Iterable<FamilyMember> get members => _members.values;

  int? fatherOf(int id) => _parentOf(id, Gender.male);

  int? motherOf(int id) => _parentOf(id, Gender.female);

  int? _parentOf(int id, Gender gender) {
    for (final r in _relations) {
      if (r.type == RelationEdgeType.parentOf && r.objectId == id) {
        final parent = _members[r.subjectId];
        if (parent != null && parent.gender == gender) return parent.id;
      }
    }
    return null;
  }

  List<int> childrenOf(int id) => [
        for (final r in _relations)
          if (r.type == RelationEdgeType.parentOf && r.subjectId == id) r.objectId,
      ];

  List<int> spousesOf(int id) => [
        for (final r in _relations)
          if (r.type == RelationEdgeType.spouseOf)
            if (r.subjectId == id)
              r.objectId
            else if (r.objectId == id)
              r.subjectId,
      ];
}
