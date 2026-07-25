import '../kinship_engine.dart';
import 'kinship_term_set.dart';

/// Burmese kinship terminology is intricate (it distinguishes far more than
/// this model captures) and this translator has lower confidence here than
/// for the other five locales. To avoid asserting a wrong idiom, only the
/// core relations we're fairly confident about are hardcoded; everything
/// else (aunts/uncles, cousins, in-laws) intentionally falls through to the
/// generic composed fallback (baseTerms + connective) instead of guessing a
/// single-word term. Recommend native-speaker review before shipping.
///
/// The gender-unknown base terms ([RelToken.parent], [RelToken.child],
/// [RelToken.elderSibling], [RelToken.youngerSibling]) are compound//generic
/// forms added alongside the gendered-spouse token split. They exist so the UI
/// never prints a raw code like "eX" at a user, but they carry the same
/// low-confidence caveat as the rest of this file and are a prime candidate for
/// that native-speaker review.
final KinshipTermSet myKinshipTerms = KinshipTermSet(
  selfTerm: 'ကျွန်တော်/ကျွန်မ',
  spouseOfMale: 'ခင်ပွန်း',
  spouseOfFemale: 'ဇနီး',
  connective: ' ရဲ့ ',
  baseTerms: const {
    RelToken.father: 'အဖေ',
    RelToken.mother: 'အမေ',
    RelToken.parent: 'မိဘ',
    RelToken.husband: 'ခင်ပွန်း',
    RelToken.wife: 'ဇနီး',
    RelToken.spouse: 'အိမ်ထောင်ဖက်',
    RelToken.son: 'သား',
    RelToken.daughter: 'သမီး',
    RelToken.child: 'ကလေး',
    RelToken.elderBrother: 'အစ်ကို',
    RelToken.youngerBrother: 'မောင်',
    RelToken.elderSister: 'အစ်မ',
    RelToken.youngerSister: 'နှမ',
    RelToken.elderSibling: 'အစ်ကိုအစ်မ',
    RelToken.youngerSibling: 'မောင်နှမ',
  },
  table: const {
    'F': 'အဖေ',
    'M': 'အမေ',
    'Son': 'သား',
    'Dau': 'သမီး',
    'F.F': 'အဖိုး',
    'F.M': 'အဖွား',
    'M.F': 'အဖိုး',
    'M.M': 'အဖွား',
    'Son.Son': 'မြေး',
    'Son.Dau': 'မြေး',
    'Dau.Son': 'မြေး',
    'Dau.Dau': 'မြေး',
    'yB': 'မောင်',
    'yZ': 'နှမ',
    'eB#male': 'အစ်ကို',
    'eB#female': 'အစ်ကို',
    'eZ#male': 'အစ်မ',
    'eZ#female': 'အစ်မ',
    'Hu': 'ခင်ပွန်း',
    'Wi': 'ဇနီး',
  },
  // Burmese kinship has many fine distinctions (see class doc), but
  // for great-grandparent depth we're not confident enough to guess
  // a single term. Leave all the depth-3 / depth-4 chain fields null
  // so the localizer falls through to the generic base-terms
  // composition ("အဖေ၏ အဖေ၏ အဖေ" etc.) — which is honest at
  // least.
);
