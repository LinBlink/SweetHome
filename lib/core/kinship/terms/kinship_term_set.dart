import '../kinship_engine.dart';

/// One language's kinship term data. See docs/api.md §七 for the algorithm
/// this feeds into.
///
/// [table] covers the canonical depth<=2 relationCodes from §7.5. A handful
/// of codes are ambiguous without extra context and use a `#male`/`#female`
/// suffixed key:
/// - `S.F`, `S.M`, `S.eB`, `S.yB`, `S.eZ`, `S.yZ` — in-law terms that in some
///   languages (Chinese, Korean) depend on the *viewer's own* gender (e.g.
///   Chinese distinguishes 岳父 vs 公公 for "spouse's father" depending on
///   whether the viewer is the son-in-law or daughter-in-law). Suffix keyed
///   by viewer gender.
/// - `eB`, `eZ` — in Korean, addressing one's own older brother/sister
///   depends on the *speaker's* gender (형/오빠, 누나/언니). Suffix keyed by
///   viewer gender. Languages without this distinction just repeat the same
///   value for both suffixes.
///
/// Bare spouse (`S`) is handled separately via [spouseOfMale]/[spouseOfFemale]
/// since it depends on the *target's* gender, not the viewer's.
///
/// For depth-3+ ancestor chains the localizer first checks
/// [greatGrandfatherPat] / [greatGrandmotherPat] / [greatGrandfatherMat] /
/// [greatGrandmotherMat] / [ggGrandfatherPat] / etc., which cover
/// `F.F.F`/`F.F.M`/`M.F.F`/`M.F.M`/… in the canonical same-direction shape
/// (e.g. `F.F.F` for great-grandfather on the father's side, `M.F.F` for
/// great-grandfather on the mother's side). These return short idiomatic
/// terms like 曾祖父 / 外曾祖父 so the UI doesn't have to render the literal
/// "父亲的父亲的父亲" fallback. Locales that don't have a confident term for
/// a given depth+side leave the field `null` and the localizer falls
/// through to the generic [baseTerms]+[connective] composition.
///
/// Codes not present in [table] (and not matched by the depth-3+ chain
/// rules above) fall back to composing [baseTerms] joined by [connective] —
/// see `kinship_localizer.dart`.
class KinshipTermSet {
  final String selfTerm;
  final String spouseOfMale;
  final String spouseOfFemale;
  final Map<String, String> table;
  final Map<RelToken, String> baseTerms;
  final String connective;

  /// Short idiomatic terms for depth-3 (great-grandparent) ancestor chains.
  /// Paternal side (`F.F.F` / `F.F.M`); maternal side (`M.F.F` / `M.F.M`).
  /// `null` means the locale has no confident term — fall through to
  /// generic composition. See class doc above.
  final String? greatGrandfatherPat;
  final String? greatGrandmotherPat;
  final String? greatGrandfatherMat;
  final String? greatGrandmotherMat;

  /// Short idiomatic terms for depth-4 (great-great-grandparent) ancestor
  /// chains. Same null-means-fall-through convention as the depth-3 fields.
  final String? ggGrandfatherPat;
  final String? ggGrandmotherPat;
  final String? ggGrandfatherMat;
  final String? ggGrandmotherMat;

  /// Short idiomatic terms for depth-3 (great-grandchild) descendant
  /// chains — the Son/Dau mirror of [greatGrandfatherPat] etc. "Pat"
  /// (son-line) vs "Mat" (daughter-line) mirrors how [greatGrandfatherPat]
  /// vs [greatGrandfatherMat] mirrors paternal vs maternal ancestry.
  /// `null` means the locale has no confident term — fall through to
  /// the next fallback. See `_descendantChainTerm` in kinship_localizer.dart.
  final String? greatGrandsonPat;
  final String? greatGranddaughterPat;
  final String? greatGrandsonMat;
  final String? greatGranddaughterMat;

  /// Short idiomatic terms for depth-4 (great-great-grandchild)
  /// descendant chains. Same null-means-fall-through convention.
  final String? ggGrandsonPat;
  final String? ggGranddaughterPat;
  final String? ggGrandsonMat;
  final String? ggGranddaughterMat;

  const KinshipTermSet({
    required this.selfTerm,
    required this.spouseOfMale,
    required this.spouseOfFemale,
    required this.table,
    required this.baseTerms,
    required this.connective,
    this.greatGrandfatherPat,
    this.greatGrandmotherPat,
    this.greatGrandfatherMat,
    this.greatGrandmotherMat,
    this.ggGrandfatherPat,
    this.ggGrandmotherPat,
    this.ggGrandfatherMat,
    this.ggGrandmotherMat,
    this.greatGrandsonPat,
    this.greatGranddaughterPat,
    this.greatGrandsonMat,
    this.greatGranddaughterMat,
    this.ggGrandsonPat,
    this.ggGranddaughterPat,
    this.ggGrandsonMat,
    this.ggGranddaughterMat,
  });
}

/// relationCodes whose term depends on the *viewer's* own gender rather than
/// being fully determined by the path tokens.
const Set<String> viewerGenderDependentCodes = {
  'eB', 'eZ', //
  'S.F', 'S.M', 'S.eB', 'S.yB', 'S.eZ', 'S.yZ',
};
