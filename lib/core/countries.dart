import '../l10n/app_localizations.dart';

class Country {
  /// Language-neutral key into AppLocalizations (see [countryDisplayName]) —
  /// country names are no longer stored as fixed Chinese text.
  final String nameKey;
  final String dialCode;
  final String flag;

  const Country({required this.nameKey, required this.dialCode, required this.flag});
}

String countryDisplayName(Country c, AppLocalizations l10n) {
  switch (c.nameKey) {
    case 'China': return l10n.countryChina;
    case 'USA': return l10n.countryUSA;
    case 'Canada': return l10n.countryCanada;
    case 'France': return l10n.countryFrance;
    case 'UK': return l10n.countryUK;
    case 'Germany': return l10n.countryGermany;
    case 'Malaysia': return l10n.countryMalaysia;
    case 'Australia': return l10n.countryAustralia;
    case 'Indonesia': return l10n.countryIndonesia;
    case 'Philippines': return l10n.countryPhilippines;
    case 'NewZealand': return l10n.countryNewZealand;
    case 'Singapore': return l10n.countrySingapore;
    case 'Thailand': return l10n.countryThailand;
    case 'Japan': return l10n.countryJapan;
    case 'Korea': return l10n.countryKorea;
    case 'Vietnam': return l10n.countryVietnam;
    case 'India': return l10n.countryIndia;
    case 'Myanmar': return l10n.countryMyanmar;
    case 'HongKong': return l10n.countryHongKong;
    case 'Macau': return l10n.countryMacau;
    case 'Taiwan': return l10n.countryTaiwan;
    default: return c.nameKey;
  }
}

class Countries {
  Countries._();

  static const Country defaultCountry = Country(nameKey: 'China', dialCode: '+86', flag: '🇨🇳');

  // 按 +区号 数值升序排列
  static const List<Country> all = [
    Country(nameKey: 'USA', dialCode: '+1', flag: '🇺🇸'),
    Country(nameKey: 'Canada', dialCode: '+1', flag: '🇨🇦'),
    Country(nameKey: 'France', dialCode: '+33', flag: '🇫🇷'),
    Country(nameKey: 'UK', dialCode: '+44', flag: '🇬🇧'),
    Country(nameKey: 'Germany', dialCode: '+49', flag: '🇩🇪'),
    Country(nameKey: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
    Country(nameKey: 'Australia', dialCode: '+61', flag: '🇦🇺'),
    Country(nameKey: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
    Country(nameKey: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
    Country(nameKey: 'NewZealand', dialCode: '+64', flag: '🇳🇿'),
    Country(nameKey: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
    Country(nameKey: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
    Country(nameKey: 'Japan', dialCode: '+81', flag: '🇯🇵'),
    Country(nameKey: 'Korea', dialCode: '+82', flag: '🇰🇷'),
    Country(nameKey: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
    defaultCountry,
    Country(nameKey: 'India', dialCode: '+91', flag: '🇮🇳'),
    Country(nameKey: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
    Country(nameKey: 'HongKong', dialCode: '+852', flag: '🇭🇰'),
    Country(nameKey: 'Macau', dialCode: '+853', flag: '🇲🇴'),
    Country(nameKey: 'Taiwan', dialCode: '+886', flag: '🇹🇼'),
  ];
}
