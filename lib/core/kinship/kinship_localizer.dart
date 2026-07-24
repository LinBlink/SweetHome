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

  // Ancestor/descendant-chain collapse: codes like F.F.F
  // (great-grandfather, paternal), M.F.M (great-grandmother,
  // maternal), or Son.Dau.Son (great-grandson, via a daughter)
  // would otherwise fall through to the base-terms composition and
  // render the literal "父亲的父亲的父亲" / "儿子的女儿的儿子",
  // which reads as an unreadable run-on chain. When the run of
  // same-direction parent (F/M) or child (Son/Dau) tokens is 2, 3,
  // or 4 deep, look up a short idiomatic term in the locale's
  // [KinshipTermSet] and prefix it with whatever comes before the
  // run (e.g. M.F.F → "母亲的爷爷" or "外曾祖父", depending on
  // locale preference). The pure-chain case with no prefix (just
  // F.F.F) yields the bare short term ("曾祖父").
  final chainTerm = _ancestorChainTerm(code, terms) ?? _descendantChainTerm(code, terms);
  if (chainTerm != null) return chainTerm;

  // Nothing above matched the *whole* code. Rather than decomposing
  // it into every individual one-hop token and joining them all
  // with [connective] — which is what produces the "儿子的女儿的
  // 配偶"-style chains this whole cascade exists to avoid — greedily
  // segment the code into the fewest possible chunks, preferring the
  // longest sub-chain at each step that already has a term (a direct
  // [KinshipTermSet.table] entry or an ancestor/descendant chain
  // collapse). See [_composeFallback].
  return _composeFallback(code, terms, targetGender: targetGender);
}

/// Greedily segments [code] into the fewest possible chunks and
/// composes them with [terms.connective]. At each position, tries
/// the longest remaining sub-chain first (a relationCode names a
/// chain of hops starting from SELF, so any prefix of it is itself a
/// meaningful sub-relation) via [_lookupChainTerm]; only when no
/// sub-chain at all matches does a single hop fall back to its bare
/// [KinshipTermSet.baseTerms] entry. This guarantees the result is
/// never longer than the old one-token-at-a-time join and is usually
/// much shorter, since it prefers whatever compound terms the
/// locale's table/chain functions already define.
///
/// [targetGender] — when known and the trailing hop is the bare
/// spouse marker `S` — picks [KinshipTermSet.spouseOfMale] /
/// [spouseOfFemale] for that chunk instead of the gender-neutral
/// base "spouse" term, so e.g. `Son.Son.Son.S` reads "曾孙的妻子"
/// rather than the more generic "曾孙的配偶".
String _composeFallback(
  String code,
  KinshipTermSet terms, {
  Gender? targetGender,
}) {
  final segments = code.split('.');
  final chunks = <String>[];
  var start = 0;
  while (start < segments.length) {
    String? matched;
    var consumed = 1;
    for (var end = segments.length; end > start; end--) {
      final term = _lookupChainTerm(segments.sublist(start, end).join('.'), terms);
      if (term != null) {
        matched = term;
        consumed = end - start;
        break;
      }
    }
    if (matched == null) {
      final segment = segments[start];
      if (segment == 'S' && start == segments.length - 1 && targetGender != null) {
        matched = targetGender == Gender.male ? terms.spouseOfMale : terms.spouseOfFemale;
      } else {
        final token = _tokenForCode(segment);
        matched = token != null ? terms.baseTerms[token] : null;
      }
      matched ??= segment;
    }
    chunks.add(matched);
    start += consumed;
  }
  return chunks.join(terms.connective);
}

/// Direct table lookup + ancestor/descendant chain collapse for a
/// sub-chain [code] — used by [_composeFallback] to find the longest
/// matching prefix at each step. Doesn't consider the `#male`/
/// `#female` gender-suffix keys, which only apply to a handful of
/// top-level in-law codes already handled earlier in
/// [localizeRelationCode], not to interior sub-chains.
String? _lookupChainTerm(String code, KinshipTermSet terms) {
  final direct = terms.table[code];
  if (direct != null) return direct;
  return _ancestorChainTerm(code, terms) ?? _descendantChainTerm(code, terms);
}

/// Tries to shorten a depth-2, depth-3, or depth-4 ancestor chain
/// into a natural-sounding kinship term. Returns `null` when the
/// code doesn't have a useful F/M chain to collapse, or when the
/// locale has no term registered for that depth+side — the caller
/// then falls back to the next fallback in the cascade.
///
/// The chain's *side* (paternal vs maternal) is decided by the run
/// of identical tokens immediately before the last one; the last
/// token's own F/M only picks father vs mother *within* that side.
/// That means `F.F.F` and `F.F.M` are both "paternal" (曾祖父 /
/// 曾祖母) even though their last hop differs, and `M.F.F` collapses
/// to a "mother" prefix + the `F.F` chain rather than requiring
/// every token to match.
///
/// Examples:
///   `F.F`         → "爷爷" (Chinese) / "Grandpa" (English)
///   `M.F.F`       → "母亲的爷爷" / "Mom's Grandpa"
///   `F.F.F`       → "曾祖父" / "Great-grandfather"
///   `F.F.M`       → "曾祖母" (paternal side, last hop is mother)
///   `M.M.F`       → "外曾祖父" (maternal side, last hop is father)
///   `F.M.F`       → "父亲的外公" (`F` prefix + `M.F` chain)
String? _ancestorChainTerm(String code, KinshipTermSet terms) {
  final parts = code.split('.');
  if (parts.length < 2) return null;
  final last = parts.last;
  if (last != 'F' && last != 'M') return null;
  final beforeLast = parts.sublist(0, parts.length - 1);
  // Find the longest trailing run of `beforeLast` that's homogeneous
  // in direction (all F or all M), walking right-to-left.
  int chainStart = beforeLast.length;
  String? direction; // 'F' or 'M'
  for (int i = beforeLast.length - 1; i >= 0; i--) {
    if (beforeLast[i] != 'F' && beforeLast[i] != 'M') break;
    if (direction == null) {
      direction = beforeLast[i];
      chainStart = i;
    } else if (beforeLast[i] == direction) {
      chainStart = i;
    } else {
      break;
    }
  }
  if (direction == null) return null;
  final prefix = parts.sublist(0, chainStart);
  // A prefix longer than one token (e.g. `F.M` in `F.M.F.F`) has no
  // single base term to render it as — bail rather than silently
  // dropping the extra token, and let the caller fall back to
  // composing shorter, still-accurate sub-chains instead.
  if (prefix.length > 1) return null;
  final chainLen = beforeLast.length - chainStart + 1; // + the final token
  final isPat = direction == 'F';
  // Look up the chain itself: length 2 reuses the existing 2-gen
  // table entries (爷爷 / 奶奶 / 外公 / 外婆 / Grandpa / Grandma
  // etc.); length 3+ uses the depth-specific fields on
  // [KinshipTermSet].
  String? bare;
  if (chainLen == 2) {
    bare = terms.table['$direction.$last'];
  } else if (chainLen == 3) {
    if (isPat) {
      bare = last == 'F' ? terms.greatGrandfatherPat : terms.greatGrandmotherPat;
    } else {
      bare = last == 'F' ? terms.greatGrandfatherMat : terms.greatGrandmotherMat;
    }
  } else if (chainLen == 4) {
    if (isPat) {
      bare = last == 'F' ? terms.ggGrandfatherPat : terms.ggGrandmotherPat;
    } else {
      bare = last == 'F' ? terms.ggGrandfatherMat : terms.ggGrandmotherMat;
    }
  } else {
    return null;
  }
  if (bare == null) return null;
  if (prefix.isEmpty) return bare;
  final head = _tokenForCode(prefix.first);
  if (head == null) return null;
  final headTerm = terms.baseTerms[head];
  if (headTerm == null) return null;
  return '$headTerm${terms.connective}$bare';
}

/// Mirrors [_ancestorChainTerm] for descendant chains — collapses a
/// depth-2/3/4 Son/Dau run into a short idiomatic term (孙 / 曾孙 /
/// 玄孙 family), with the same "the run before the last token
/// decides the side; the last token decides the gender" rule, e.g.
/// `Son.Son.Dau` is still "son-line" (曾孙女) even though its last
/// hop is `Dau`.
///
/// Examples:
///   `Son.Son`     → "孙子" (already in [KinshipTermSet.table]
///                    directly, but this function also covers it)
///   `Son.Son.Son` → "曾孙" (depth-3, son line)
///   `Son.Son.Dau` → "曾孙女" (depth-3, son line, female)
///   `Dau.Dau.Son` → "外曾孙" (depth-3, daughter line)
///   `Dau.Son.Son` → "女儿的孙子" (`Dau` prefix + `Son.Son` chain)
String? _descendantChainTerm(String code, KinshipTermSet terms) {
  final parts = code.split('.');
  if (parts.length < 2) return null;
  final last = parts.last;
  if (last != 'Son' && last != 'Dau') return null;
  final beforeLast = parts.sublist(0, parts.length - 1);
  int chainStart = beforeLast.length;
  String? direction; // 'Son' or 'Dau'
  for (int i = beforeLast.length - 1; i >= 0; i--) {
    if (beforeLast[i] != 'Son' && beforeLast[i] != 'Dau') break;
    if (direction == null) {
      direction = beforeLast[i];
      chainStart = i;
    } else if (beforeLast[i] == direction) {
      chainStart = i;
    } else {
      break;
    }
  }
  if (direction == null) return null;
  final prefix = parts.sublist(0, chainStart);
  if (prefix.length > 1) return null;
  final chainLen = beforeLast.length - chainStart + 1;
  final isPat = direction == 'Son';
  String? bare;
  if (chainLen == 2) {
    bare = terms.table['$direction.$last'];
  } else if (chainLen == 3) {
    if (isPat) {
      bare = last == 'Son' ? terms.greatGrandsonPat : terms.greatGranddaughterPat;
    } else {
      bare = last == 'Son' ? terms.greatGrandsonMat : terms.greatGranddaughterMat;
    }
  } else if (chainLen == 4) {
    if (isPat) {
      bare = last == 'Son' ? terms.ggGrandsonPat : terms.ggGranddaughterPat;
    } else {
      bare = last == 'Son' ? terms.ggGrandsonMat : terms.ggGranddaughterMat;
    }
  } else {
    return null;
  }
  if (bare == null) return null;
  if (prefix.isEmpty) return bare;
  final head = _tokenForCode(prefix.first);
  if (head == null) return null;
  final headTerm = terms.baseTerms[head];
  if (headTerm == null) return null;
  return '$headTerm${terms.connective}$bare';
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
