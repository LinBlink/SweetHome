import 'kinship_graph.dart';

/// Primitive/composite relation step. Keep in sync with docs/api.md §七
/// (亲属称谓计算算法) — this is the direct Dart implementation of that
/// algorithm, used client-side in mock mode.
enum RelToken {
  father, // F
  mother, // M
  spouse, // S
  son, // Son
  daughter, // Dau
  elderBrother, // eB
  youngerBrother, // yB
  elderSister, // eZ
  youngerSister, // yZ
  ;

  String get code {
    switch (this) {
      case RelToken.father:
        return 'F';
      case RelToken.mother:
        return 'M';
      case RelToken.spouse:
        return 'S';
      case RelToken.son:
        return 'Son';
      case RelToken.daughter:
        return 'Dau';
      case RelToken.elderBrother:
        return 'eB';
      case RelToken.youngerBrother:
        return 'yB';
      case RelToken.elderSister:
        return 'eZ';
      case RelToken.youngerSister:
        return 'yZ';
    }
  }

  bool get isBlood => this != RelToken.spouse;
}

const String kSelfRelationCode = 'SELF';

/// BFS shortest path from [viewerId] to [targetId] over the family graph,
/// followed by a sibling-reduction pass. Returns an empty list if
/// viewer == target (caller should render that as "SELF"/"我").
///
/// Algorithm — see docs/api.md §七 for the full written spec:
/// 1. BFS over primitive steps {F, M, S, Son, Dau}, blood edges enqueued
///    before spouse edges so equal-length paths prefer blood relations.
/// 2. Reduce adjacent (F|M) followed by (Son|Dau) — "parent's other child"
///    — into a single sibling token (eB/yB/eZ/yZ), repeating to a fixpoint
///    so multi-hop chains cascade correctly.
List<RelToken> computeRelationPath(FamilyGraph graph, int viewerId, int targetId) {
  if (viewerId == targetId) return const [];

  final path = _bfsPath(graph, viewerId, targetId);
  if (path == null) return const [];

  return _reduce(graph, path);
}

String relationCode(List<RelToken> tokens) {
  if (tokens.isEmpty) return kSelfRelationCode;
  return tokens.map((t) => t.code).join('.');
}

class _Step {
  final RelToken token;
  final int toId;
  const _Step(this.token, this.toId);
}

/// Node sequence + connecting tokens: nodes[i] --tokens[i]--> nodes[i+1].
class _NodePath {
  final List<int> nodes;
  final List<RelToken> tokens;
  const _NodePath(this.nodes, this.tokens);
}

_NodePath? _bfsPath(FamilyGraph graph, int viewerId, int targetId) {
  final visited = <int>{viewerId};
  final queue = <List<int>>[
    [viewerId]
  ];
  final tokenTrail = <int, List<RelToken>>{viewerId: const []};

  while (queue.isNotEmpty) {
    final nodePath = queue.removeAt(0);
    final current = nodePath.last;
    if (current == targetId) {
      return _NodePath(nodePath, tokenTrail[current]!);
    }
    for (final step in _neighbors(graph, current)) {
      if (visited.contains(step.toId)) continue;
      visited.add(step.toId);
      tokenTrail[step.toId] = [...tokenTrail[current]!, step.token];
      queue.add([...nodePath, step.toId]);
    }
  }
  return null;
}

/// Blood edges (F/M/Son/Dau) before marriage edges (S) — tie-break rule
/// from docs/api.md §7.3.
List<_Step> _neighbors(FamilyGraph graph, int id) {
  final steps = <_Step>[];
  final father = graph.fatherOf(id);
  if (father != null) steps.add(_Step(RelToken.father, father));
  final mother = graph.motherOf(id);
  if (mother != null) steps.add(_Step(RelToken.mother, mother));
  for (final childId in graph.childrenOf(id)) {
    final child = graph.memberById(childId);
    if (child == null) continue;
    steps.add(_Step(child.gender == Gender.male ? RelToken.son : RelToken.daughter, childId));
  }
  for (final spouseId in graph.spousesOf(id)) {
    steps.add(_Step(RelToken.spouse, spouseId));
  }
  return steps;
}

List<RelToken> _reduce(FamilyGraph graph, _NodePath path) {
  var nodes = List<int>.from(path.nodes);
  var tokens = List<RelToken>.from(path.tokens);

  var reducedAny = true;
  while (reducedAny) {
    reducedAny = false;
    for (var i = 0; i + 1 < tokens.length; i++) {
      final isParentStep = tokens[i] == RelToken.father || tokens[i] == RelToken.mother;
      final isChildStep = tokens[i + 1] == RelToken.son || tokens[i + 1] == RelToken.daughter;
      if (!isParentStep || !isChildStep) continue;
      if (nodes[i] == nodes[i + 2]) continue;

      final sibling = _siblingToken(graph, fromId: nodes[i], siblingId: nodes[i + 2]);
      tokens = [...tokens.sublist(0, i), sibling, ...tokens.sublist(i + 2)];
      nodes = [...nodes.sublist(0, i + 1), ...nodes.sublist(i + 2)];
      reducedAny = true;
      break;
    }
  }
  return tokens;
}

RelToken _siblingToken(FamilyGraph graph, {required int fromId, required int siblingId}) {
  final sibling = graph.memberById(siblingId);
  final self = graph.memberById(fromId);
  final siblingIsElder = _isElder(self?.birthOrder, sibling?.birthOrder);
  final isMale = sibling?.gender == Gender.male;
  if (isMale) {
    return siblingIsElder ? RelToken.elderBrother : RelToken.youngerBrother;
  }
  return siblingIsElder ? RelToken.elderSister : RelToken.youngerSister;
}

/// Lower birthOrder = older. Unknown birthOrder defaults to treating the
/// sibling as elder (documented precision trade-off, docs/api.md §7.4).
bool _isElder(int? selfBirthOrder, int? siblingBirthOrder) {
  if (selfBirthOrder == null || siblingBirthOrder == null) return true;
  return siblingBirthOrder < selfBirthOrder;
}
