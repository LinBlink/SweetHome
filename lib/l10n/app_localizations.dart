import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_my.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('my'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sweet Home'**
  String get appTitle;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Sweet Home'**
  String get brandName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The warmth of family, one tap away'**
  String get appTagline;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navProfile;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPasswordLabel;

  /// No description provided for @commonPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get commonPasswordRequired;

  /// No description provided for @commonPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get commonPasswordTooShort;

  /// No description provided for @errorNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed, please try again later'**
  String get errorNetworkFailed;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get loginRegisterNow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get registerNicknameLabel;

  /// No description provided for @registerNicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get registerNicknameRequired;

  /// No description provided for @registerGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get registerGenderLabel;

  /// No description provided for @registerGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get registerGenderMale;

  /// No description provided for @registerGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get registerGenderFemale;

  /// No description provided for @registerGenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get registerGenderRequired;

  /// No description provided for @registerCreateFamilyTab.
  ///
  /// In en, this message translates to:
  /// **'Create a Family'**
  String get registerCreateFamilyTab;

  /// No description provided for @registerJoinFamilyTab.
  ///
  /// In en, this message translates to:
  /// **'Join a Family'**
  String get registerJoinFamilyTab;

  /// No description provided for @registerRequestJoinTab.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get registerRequestJoinTab;

  /// No description provided for @registerFamilyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name (e.g. The Wangs)'**
  String get registerFamilyNameLabel;

  /// No description provided for @registerFamilyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a family name'**
  String get registerFamilyNameRequired;

  /// No description provided for @registerFamilyNameHint.
  ///
  /// In en, this message translates to:
  /// **'* After registering, you can generate an invite code to invite family members'**
  String get registerFamilyNameHint;

  /// No description provided for @registerInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Family invite code'**
  String get registerInviteCodeLabel;

  /// No description provided for @registerInviteCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an invite code'**
  String get registerInviteCodeRequired;

  /// No description provided for @registerInviteCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code format'**
  String get registerInviteCodeInvalid;

  /// No description provided for @registerInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'* Invite codes are generated by the family admin and are valid for 48 hours'**
  String get registerInviteCodeHint;

  /// No description provided for @registerFindFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Find Family'**
  String get registerFindFamilyButton;

  /// No description provided for @registerFindFamilyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find a family for this invite code'**
  String get registerFindFamilyFailed;

  /// No description provided for @registerRelationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your relation to them'**
  String get registerRelationLabel;

  /// No description provided for @registerRelationChild.
  ///
  /// In en, this message translates to:
  /// **'Their child'**
  String get registerRelationChild;

  /// No description provided for @registerRelationParent.
  ///
  /// In en, this message translates to:
  /// **'Their parent'**
  String get registerRelationParent;

  /// No description provided for @registerRelationSpouse.
  ///
  /// In en, this message translates to:
  /// **'Their spouse'**
  String get registerRelationSpouse;

  /// No description provided for @registerRelationSibling.
  ///
  /// In en, this message translates to:
  /// **'Their sibling'**
  String get registerRelationSibling;

  /// No description provided for @registerRelationAnchorRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose which member you\'re related to'**
  String get registerRelationAnchorRequired;

  /// No description provided for @registerSubmitCreate.
  ///
  /// In en, this message translates to:
  /// **'Register & Create Family'**
  String get registerSubmitCreate;

  /// No description provided for @registerSubmitJoin.
  ///
  /// In en, this message translates to:
  /// **'Register & Join Family'**
  String get registerSubmitJoin;

  /// No description provided for @requestJoinTargetPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number of a family member you know'**
  String get requestJoinTargetPhoneLabel;

  /// No description provided for @requestJoinTargetPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter their phone number'**
  String get requestJoinTargetPhoneRequired;

  /// No description provided for @requestJoinTargetPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'* No invite code needed — just the phone number of someone already in that family. Their family admin will review your request.'**
  String get requestJoinTargetPhoneHint;

  /// No description provided for @requestJoinMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message to the admin (optional)'**
  String get requestJoinMessageLabel;

  /// No description provided for @requestJoinSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get requestJoinSubmit;

  /// No description provided for @requestJoinSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get requestJoinSubmittedTitle;

  /// No description provided for @requestJoinSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent to the family admin for review. Once approved, log in with the phone number and password you just entered.'**
  String get requestJoinSubmittedMessage;

  /// No description provided for @joinRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get joinRequestsTitle;

  /// No description provided for @joinRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get joinRequestsEmpty;

  /// No description provided for @joinRequestsRelationLine.
  ///
  /// In en, this message translates to:
  /// **'Wants to be {targetName}\'s {relation}'**
  String joinRequestsRelationLine(String relation, String targetName);

  /// No description provided for @relationNounChild.
  ///
  /// In en, this message translates to:
  /// **'child'**
  String get relationNounChild;

  /// No description provided for @relationNounParent.
  ///
  /// In en, this message translates to:
  /// **'parent'**
  String get relationNounParent;

  /// No description provided for @relationNounSpouse.
  ///
  /// In en, this message translates to:
  /// **'spouse'**
  String get relationNounSpouse;

  /// No description provided for @relationNounSibling.
  ///
  /// In en, this message translates to:
  /// **'sibling'**
  String get relationNounSibling;

  /// No description provided for @joinRequestsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get joinRequestsApprove;

  /// No description provided for @joinRequestsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get joinRequestsReject;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get phoneInvalid;

  /// No description provided for @countryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Country/Region'**
  String get countryPickerTitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @profileLanguageRow.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageRow;

  /// No description provided for @profileFamilyMembersRow.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get profileFamilyMembersRow;

  /// No description provided for @conversationsSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get conversationsSearchTooltip;

  /// No description provided for @conversationsNewTooltip.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get conversationsNewTooltip;

  /// No description provided for @conversationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get conversationsEmptyTitle;

  /// No description provided for @conversationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite family members to start chatting'**
  String get conversationsEmptySubtitle;

  /// No description provided for @connectionErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get connectionErrorRetry;

  /// No description provided for @newConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversationTitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get editProfileNicknameLabel;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSave;

  /// No description provided for @editProfileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get editProfileChangeAvatar;

  /// No description provided for @editProfileAvatarUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get editProfileAvatarUploading;

  /// No description provided for @editProfileAvatarFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed, please try again'**
  String get editProfileAvatarFailed;

  /// No description provided for @inviteGenerate.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteGenerate;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteExpiryDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String inviteExpiryDays(int days);

  /// No description provided for @inviteExpiryHours.
  ///
  /// In en, this message translates to:
  /// **'Expires in {hours} hours'**
  String inviteExpiryHours(int hours);

  /// No description provided for @inviteExpiryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes} minutes'**
  String inviteExpiryMinutes(int minutes);

  /// No description provided for @inviteExpiryLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'Expires in less than a minute'**
  String get inviteExpiryLessThanMinute;

  /// No description provided for @inviteExpiryExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get inviteExpiryExpired;

  /// No description provided for @inviteCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get inviteCopy;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get inviteCopied;

  /// No description provided for @joinFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Another Family'**
  String get joinFamilyTitle;

  /// No description provided for @joinFamilyConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Joining a new family will remove you from your current family. Continue?'**
  String get joinFamilyConfirmMessage;

  /// No description provided for @chatRoomMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String chatRoomMessageCount(int count);

  /// No description provided for @chatRoomDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Family chat room'**
  String get chatRoomDefaultSubtitle;

  /// No description provided for @chatRoomMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chatRoomMoreTooltip;

  /// No description provided for @chatRoomEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Send a message to say hello'**
  String get chatRoomEmptyHint;

  /// No description provided for @chatRoomInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type something...'**
  String get chatRoomInputHint;

  /// No description provided for @chatRoomMoreOption.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chatRoomMoreOption;

  /// No description provided for @familyMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembersTitle;

  /// No description provided for @familyMembersAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get familyMembersAdminBadge;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @countryChina.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get countryChina;

  /// No description provided for @countryUSA.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUSA;

  /// No description provided for @countryCanada.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get countryCanada;

  /// No description provided for @countryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get countryFrance;

  /// No description provided for @countryUK.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get countryUK;

  /// No description provided for @countryGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get countryGermany;

  /// No description provided for @countryMalaysia.
  ///
  /// In en, this message translates to:
  /// **'Malaysia'**
  String get countryMalaysia;

  /// No description provided for @countryAustralia.
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get countryAustralia;

  /// No description provided for @countryIndonesia.
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get countryIndonesia;

  /// No description provided for @countryPhilippines.
  ///
  /// In en, this message translates to:
  /// **'Philippines'**
  String get countryPhilippines;

  /// No description provided for @countryNewZealand.
  ///
  /// In en, this message translates to:
  /// **'New Zealand'**
  String get countryNewZealand;

  /// No description provided for @countrySingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get countrySingapore;

  /// No description provided for @countryThailand.
  ///
  /// In en, this message translates to:
  /// **'Thailand'**
  String get countryThailand;

  /// No description provided for @countryJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get countryJapan;

  /// No description provided for @countryKorea.
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get countryKorea;

  /// No description provided for @countryVietnam.
  ///
  /// In en, this message translates to:
  /// **'Vietnam'**
  String get countryVietnam;

  /// No description provided for @countryIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get countryIndia;

  /// No description provided for @countryMyanmar.
  ///
  /// In en, this message translates to:
  /// **'Myanmar'**
  String get countryMyanmar;

  /// No description provided for @countryHongKong.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong SAR'**
  String get countryHongKong;

  /// No description provided for @countryMacau.
  ///
  /// In en, this message translates to:
  /// **'Macau SAR'**
  String get countryMacau;

  /// No description provided for @countryTaiwan.
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get countryTaiwan;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'my', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'my':
      return AppLocalizationsMy();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
