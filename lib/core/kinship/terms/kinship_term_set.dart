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
/// Codes not present in [table] fall back to composing [baseTerms] joined by
/// [connective] — see `kinship_localizer.dart`.
class KinshipTermSet {
  final String selfTerm;
  final String spouseOfMale;
  final String spouseOfFemale;
  final Map<String, String> table;
  final Map<RelToken, String> baseTerms;
  final String connective;

  const KinshipTermSet({
    required this.selfTerm,
    required this.spouseOfMale,
    required this.spouseOfFemale,
    required this.table,
    required this.baseTerms,
    required this.connective,
  });
}

/// relationCodes whose term depends on the *viewer's* own gender rather than
/// being fully determined by the path tokens.
const Set<String> viewerGenderDependentCodes = {
  'eB', 'eZ', //
  'S.F', 'S.M', 'S.eB', 'S.yB', 'S.eZ', 'S.yZ',
};
