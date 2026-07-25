import 'kinship_graph.dart';

/// Primitive/composite relation step. Keep in sync with docs/api.md §七
/// (亲属称谓计算算法) — this is the direct Dart implementation of that
/// algorithm, used client-side in mock mode.
/// Primitive/composite relation step.
///
/// Spouse steps carry the spouse's gender ([husband]/[wife]) rather than being
/// a single neutral `S`. With a neutral token the spouse's gender was simply
/// absent from the code: `S` couldn't say husband vs wife, and `S.F` couldn't
/// say 岳父 (wife's father) vs 公公 (husband's father). The localizer worked
/// around that by taking the *viewer's* gender and assuming the marriage was
/// heterosexual — a workaround that breaks as soon as the spouse step is in the
/// middle of a path (`Wi.eB.Son`) and is simply wrong for same-sex marriages.
///
/// The neutral tokens ([parent], [child], [spouse], [elderSibling],
/// [youngerSibling]) are for members whose gender was never recorded. The
/// client engine (mock mode) always knows genders and won't emit them, but the
/// backend can, so the localizer must still be able to render them.
enum RelToken {
  father, // F
  mother, // M
  parent, // P  — gender unknown
  son, // Son
  daughter, // Dau
  child, // C  — gender unknown
  husband, // Hu
  wife, // Wi
  spouse, // S  — gender unknown
  elderBrother, // eB
  youngerBrother, // yB
  elderSister, // eZ
  youngerSister, // yZ
  elderSibling, // eX — gender unknown
  youngerSibling, // yX — gender unknown
  ;

  String get code {
    switch (this) {
      case RelToken.father:
        return 'F';
      case RelToken.mother:
        return 'M';
      case RelToken.parent:
        return 'P';
      case RelToken.son:
        return 'Son';
      case RelToken.daughter:
        return 'Dau';
      case RelToken.child:
        return 'C';
      case RelToken.husband:
        return 'Hu';
      case RelToken.wife:
        return 'Wi';
      case RelToken.spouse:
        return 'S';
      case RelToken.elderBrother:
        return 'eB';
      case RelToken.youngerBrother:
        return 'yB';
      case RelToken.elderSister:
        return 'eZ';
      case RelToken.youngerSister:
        return 'yZ';
      case RelToken.elderSibling:
        return 'eX';
      case RelToken.youngerSibling:
        return 'yX';
    }
  }

  bool get isBlood => !isSpouse;

  /// A marriage step (any gender). Used as the tie-break weight that makes
  /// blood paths win over affinal ones.
  bool get isSpouse =>
      this == RelToken.husband || this == RelToken.wife || this == RelToken.spouse;

  bool get isParentStep =>
      this == RelToken.father || this == RelToken.mother || this == RelToken.parent;

  bool get isChildStep =>
      this == RelToken.son || this == RelToken.daughter || this == RelToken.child;
}

/// The spouse token for a member of the given gender.
RelToken spouseTokenFor(Gender? gender) => switch (gender) {
      Gender.male => RelToken.husband,
      Gender.female => RelToken.wife,
      null => RelToken.spouse,
    };

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
    // The token depends on whose direction we're walking: stepping *to* the
    // spouse, so it's that person's gender that names the step.
    steps.add(_Step(spouseTokenFor(graph.memberById(spouseId)?.gender), spouseId));
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
      final RelToken folded;
      if (tokens[i].isParentStep && tokens[i + 1].isChildStep) {
        // "my parent's other child" is my sibling, not a two-hop path
        if (nodes[i] == nodes[i + 2]) continue;
        folded = _siblingToken(graph, fromId: nodes[i], siblingId: nodes[i + 2]);
      } else if (tokens[i].isChildStep && tokens[i + 1].isParentStep) {
        // "my child's other parent" is my spouse. Reachable when the couple
        // has no SPOUSE_OF row but both PARENT_OF rows exist — without this
        // the UI would literally read "my son's mother".
        if (nodes[i] == nodes[i + 2]) continue;
        folded = spouseTokenFor(graph.memberById(nodes[i + 2])?.gender);
      } else {
        continue;
      }

      tokens = [...tokens.sublist(0, i), folded, ...tokens.sublist(i + 2)];
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
