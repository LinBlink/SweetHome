import 'package:flutter/widgets.dart' show Locale;
import 'kinship_engine.dart';
import 'kinship_graph.dart';
import 'terms/kinship_term_set.dart';
import 'terms/terms_en.dart';
import 'terms/terms_ja.dart';
import 'terms/terms_ko.dart';
import 'terms/terms_my.dart';
import 'terms/terms_zh_hans.dart';
import 'terms/terms_zh_hant.dart';

const String kDefaultKinshipLocale = 'zh_Hans';

final Map<String, KinshipTermSet> _termSets = {
  'zh_Hans': zhHansKinshipTerms,
  'zh_Hant': zhHantKinshipTerms,
  'ko': koKinshipTerms,
  'my': myKinshipTerms,
  'en': enKinshipTerms,
  'ja': jaKinshipTerms,
};

KinshipTermSet termSetFor(String localeCode) =>
    _termSets[localeCode] ?? _termSets[kDefaultKinshipLocale]!;

/// Maps a Flutter [Locale] (as produced by `LocaleProvider`/`AppLocalizations`)
/// to the kinship engine's locale code (matches the ARB file naming
/// convention, e.g. `zh_Hans`).
String kinshipLocaleCodeFor(Locale? locale) {
  if (locale == null) return kDefaultKinshipLocale;
  if (locale.languageCode == 'zh') {
    return locale.scriptCode == 'Hant' ? 'zh_Hant' : 'zh_Hans';
  }
  return _termSets.containsKey(locale.languageCode) ? locale.languageCode : kDefaultKinshipLocale;
}

/// Localizes an already-computed relation path (see [computeRelationPath])
/// into display text. [targetGender] disambiguates the bare spouse relation
/// (`S` -> husband/wife); [viewerGender] disambiguates the handful of
/// viewer-gender-dependent terms in [viewerGenderDependentCodes] (falls back
/// to `male` if the viewer's gender isn't known).
///
/// Returns `null` when the relation can't be disambiguated at all (currently
/// only the `S` code with unknown `targetGender`) — callers should treat
/// that as "no label to show" rather than rendering a generic term.
///
/// This is a thin wrapper over [localizeRelationCode] for callers that
/// already have the token path (mock mode, which builds the graph locally).
/// For real-mode data, where only the backend-computed `relationCode`
/// string travels over the wire (see docs/api.md §七 — the backend only
/// ever produces the language-neutral code; all localization is a client
/// concern), call [localizeRelationCode] directly.
String? localizeRelation(
  List<RelToken> tokens, {
  Gender? targetGender,
  Gender? viewerGender,
  String localeCode = kDefaultKinshipLocale,
}) {
  if (tokens.isEmpty) return termSetFor(localeCode).selfTerm;
  return localizeRelationCode(
    relationCode(tokens),
    targetGender: targetGender,
    viewerGender: viewerGender,
    localeCode: localeCode,
  );
}

/// Localizes a language-neutral `relationCode` string (e.g. `"F.eB"`,
/// `"SELF"`) into display text for [localeCode]. This is the single source
/// of truth for kinship-term translation — the backend never localizes,
/// it only ever produces the code (see docs/api.md §七).
///
/// [targetGender] only matters for the bare spouse code `S`:
/// - `Gender.male`   → `spouseOfMale` (e.g. 丈夫 / Husband)
/// - `Gender.female` → `spouseOfFemale` (e.g. 妻子 / Wife)
/// - `null`          → `null` (no label — we refuse to print a neutral
///                    "配偶"/"Spouse" because the product rule is "show
///                    丈夫 or 妻子, nothing else")
/// Callers must pass the API's actual `senderGender` / `otherUserGender`
/// straight through — **do not fall back to `Gender.male` on null**, or
/// female spouses get rendered as "husband" (the old bug).
String? localizeRelationCode(
  String code, {
  Gender? targetGender,
  Gender? viewerGender,
  String localeCode = kDefaultKinshipLocale,
}) {
  final terms = termSetFor(localeCode);
  if (code == kSelfRelationCode) return terms.selfTerm;

  if (code == 'S') {
    if (targetGender == Gender.male) return terms.spouseOfMale;
    if (targetGender == Gender.female) return terms.spouseOfFemale;
    return null;
  }

  if (viewerGenderDependentCodes.contains(code)) {
    final gender = viewerGender ?? Gender.male;
    final key = '$code#${gender.name}';
    final match = terms.table[key];
    if (match != null) return match;
  }

  final direct = terms.table[code];
  if (direct != null) return direct;

  final tokens = code.split('.').map(_tokenForCode).whereType<RelToken>();
  if (tokens.isEmpty) return code;
  return tokens.map((t) => terms.baseTerms[t]!).join(terms.connective);
}

/// Convenience wrapper combining [kinshipLocaleCodeFor] + [localizeRelationCode]
/// for widget code — pass the raw `Locale?` from `LocaleProvider` directly.
String? relationLabelFor({
  required String relationCode,
  Gender? targetGender,
  Gender? viewerGender,
  required Locale? appLocale,
}) =>
    localizeRelationCode(
      relationCode,
      targetGender: targetGender,
      viewerGender: viewerGender,
      localeCode: kinshipLocaleCodeFor(appLocale),
    );

RelToken? _tokenForCode(String code) {
  for (final t in RelToken.values) {
    if (t.code == code) return t;
  }
  return null;
}
