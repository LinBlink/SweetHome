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

/// The upward (parent) token for a member of the given gender.
RelToken parentTokenFor(Gender? gender) => switch (gender) {
      Gender.male => RelToken.father,
      Gender.female => RelToken.mother,
      null => RelToken.parent,
    };

/// The downward (child) token for a member of the given gender.
RelToken childTokenFor(Gender? gender) => switch (gender) {
      Gender.male => RelToken.son,
      Gender.female => RelToken.daughter,
      null => RelToken.child,
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

/// A candidate path under construction. [affinalHops] counts marriage steps,
/// which is how "blood relations win" is expressed as a sort key.
class _Candidate {
  final List<int> nodes;
  final List<RelToken> tokens;
  final int affinalHops;
  const _Candidate(this.nodes, this.tokens, this.affinalHops);

  int get last => nodes.last;
}

/// The canonical total order over paths — **must stay byte-identical to
/// `KinshipEngine.PATH_ORDER` on the backend**, or the two engines will pick
/// different paths for the same family and render different kinship terms for
/// the same pair of people.
///
/// Compares, in order: hop count → affinal hop count (blood wins) → token
/// spelling → member ids. Nothing in that list depends on the order the
/// relations arrived in, so the winner is unique and reproducible.
int _comparePaths(_Candidate a, _Candidate b) {
  final byLength = a.tokens.length.compareTo(b.tokens.length);
  if (byLength != 0) return byLength;

  final byAffinal = a.affinalHops.compareTo(b.affinalHops);
  if (byAffinal != 0) return byAffinal;

  for (var i = 0; i < a.tokens.length && i < b.tokens.length; i++) {
    final byToken = a.tokens[i].code.compareTo(b.tokens[i].code);
    if (byToken != 0) return byToken;
  }

  for (var i = 0; i < a.nodes.length && i < b.nodes.length; i++) {
    final byNode = a.nodes[i].compareTo(b.nodes[i]);
    if (byNode != 0) return byNode;
  }
  return a.nodes.length.compareTo(b.nodes.length);
}

/// Canonical shortest path from [viewerId] to [targetId].
///
/// This is Dijkstra ordered by [_comparePaths] rather than a plain FIFO BFS.
/// The old BFS marked nodes visited on *enqueue*, so whichever neighbour
/// happened to be reached first won permanently — and since neighbours were
/// emitted in relation-list order, reordering the relations (or the database
/// returning rows in a different order, as it may: the query has no ORDER BY)
/// could change the resulting kinship term. Selecting the global minimum under
/// a total order removes that dependency entirely.
///
/// Only settled nodes are expanded, and only into unsettled ones, so every
/// path stays simple (no node repeats) — which is what lets [_reduce] assume
/// `nodes[i] != nodes[i + 2]`.
_NodePath? _bfsPath(FamilyGraph graph, int viewerId, int targetId) {
  final settled = <int>{viewerId};
  final queue = <_Candidate>[];

  void pushNeighbours(_Candidate base) {
    for (final step in _neighbors(graph, base.last)) {
      if (settled.contains(step.toId)) continue;
      queue.add(_Candidate(
        [...base.nodes, step.toId],
        [...base.tokens, step.token],
        base.affinalHops + (step.token.isSpouse ? 1 : 0),
      ));
    }
  }

  pushNeighbours(_Candidate([viewerId], const [], 0));

  while (queue.isNotEmpty) {
    // Take the global minimum. Family graphs are small, so a linear scan is
    // cheaper and far clearer than maintaining a heap.
    var bestIndex = 0;
    for (var i = 1; i < queue.length; i++) {
      if (_comparePaths(queue[i], queue[bestIndex]) < 0) bestIndex = i;
    }
    final best = queue.removeAt(bestIndex);

    if (!settled.add(best.last)) continue; // already reached by a better path
    if (best.last == targetId) return _NodePath(best.nodes, best.tokens);

    pushNeighbours(best);
  }
  return null;
}

/// One graph edge per relation row, mirroring `KinshipEngine.buildGraph`.
/// Emission order is irrelevant to the result — [_comparePaths] is a total
/// order — but it mirrors the backend anyway to keep the two readable side by
/// side.
List<_Step> _neighbors(FamilyGraph graph, int id) {
  final steps = <_Step>[];
  for (final parentId in graph.parentsOf(id)) {
    steps.add(_Step(parentTokenFor(graph.memberById(parentId)?.gender), parentId));
  }
  for (final childId in graph.childrenOf(id)) {
    final child = graph.memberById(childId);
    if (child == null) continue;
    steps.add(_Step(childTokenFor(child.gender), childId));
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
  final siblingIsElder = _isElder(self, sibling);
  final isMale = sibling?.gender == Gender.male;
  if (isMale) {
    return siblingIsElder ? RelToken.elderBrother : RelToken.youngerBrother;
  }
  return siblingIsElder ? RelToken.elderSister : RelToken.youngerSister;
}

/// Whether [sibling] is older than [self], with three levels of fallback —
/// must stay identical to `KinshipEngine.endIsElder` on the backend:
///  1. birth date (earlier = older) — the reliable signal;
///  2. birthOrder (lower = older) — needs hand entry, so usually null;
///  3. default to treating the sibling as elder (docs/api.md §11.4). This is
///     not a rare edge case: until birth dates are populated it covers nearly
///     all traffic, i.e. nearly every sibling shows up as 哥/姐.
///
/// Both sides need a value for a level to decide anything — one sibling's
/// birthday alone says nothing about who's older.
bool _isElder(FamilyMember? self, FamilyMember? sibling) {
  final selfBirth = self?.birthDate;
  final siblingBirth = sibling?.birthDate;
  if (selfBirth != null && siblingBirth != null && !selfBirth.isAtSameMomentAs(siblingBirth)) {
    return siblingBirth.isBefore(selfBirth);
  }

  final selfOrder = self?.birthOrder;
  final siblingOrder = sibling?.birthOrder;
  if (selfOrder != null && siblingOrder != null && selfOrder != siblingOrder) {
    return siblingOrder < selfOrder;
  }

  return true;
}
