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

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @navMyHome.
  ///
  /// In en, this message translates to:
  /// **'My Home'**
  String get navMyHome;

  /// No description provided for @navFamilyFeed.
  ///
  /// In en, this message translates to:
  /// **'Family Feed'**
  String get navFamilyFeed;

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

  /// No description provided for @myHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'My Home'**
  String get myHomeTitle;

  /// No description provided for @myHomeLocationEntry.
  ///
  /// In en, this message translates to:
  /// **'Real-time Location'**
  String get myHomeLocationEntry;

  /// No description provided for @myHomeLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'See where each family member is right now'**
  String get myHomeLocationDesc;

  /// No description provided for @myHomeJoinRequestsEntry.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get myHomeJoinRequestsEntry;

  /// No description provided for @myHomeJoinRequestsDesc.
  ///
  /// In en, this message translates to:
  /// **'Review and approve requests to join this family'**
  String get myHomeJoinRequestsDesc;

  /// No description provided for @myHomeJoinRequestsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pending} =1{1 pending} other{{count} pending}}'**
  String myHomeJoinRequestsBadge(int count);

  /// No description provided for @familyFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Feed'**
  String get familyFeedTitle;

  /// No description provided for @familyFeedComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get familyFeedComingSoon;

  /// No description provided for @familyFeedComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Family updates and milestones are on the way.'**
  String get familyFeedComingSoonDesc;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No family members yet'**
  String get contactsEmpty;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time Location'**
  String get locationTitle;

  /// No description provided for @locationOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get locationOnline;

  /// No description provided for @locationOffline.
  ///
  /// In en, this message translates to:
  /// **'No recent location'**
  String get locationOffline;

  /// No description provided for @locationUpdatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get locationUpdatedJustNow;

  /// No description provided for @locationUpdatedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {minutes}m ago'**
  String locationUpdatedMinutesAgo(Object minutes);

  /// No description provided for @locationBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery: {percent}%'**
  String locationBattery(Object percent);

  /// No description provided for @locationBatteryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Battery: unknown'**
  String get locationBatteryUnknown;

  /// No description provided for @locationCoordinates.
  ///
  /// In en, this message translates to:
  /// **'lng {lng}, lat {lat}'**
  String locationCoordinates(Object lat, Object lng);

  /// No description provided for @locationNoData.
  ///
  /// In en, this message translates to:
  /// **'No location data yet'**
  String get locationNoData;

  /// No description provided for @locationNoDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Family members need to enable location sharing for their position to show up here.'**
  String get locationNoDataDesc;

  /// No description provided for @locationTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'{total} family members'**
  String locationTotalMembers(Object total);

  /// No description provided for @locationOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'{online}/{total} sharing location'**
  String locationOnlineCount(Object online, Object total);

  /// No description provided for @locationReportNow.
  ///
  /// In en, this message translates to:
  /// **'Share my location'**
  String get locationReportNow;

  /// No description provided for @locationShareOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is on'**
  String get locationShareOnTitle;

  /// No description provided for @locationShareOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is off'**
  String get locationShareOffTitle;

  /// No description provided for @locationShareOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your position is reported to family about every 30 seconds.'**
  String get locationShareOnSubtitle;

  /// No description provided for @locationShareOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on to let family see where you are.'**
  String get locationShareOffSubtitle;

  /// No description provided for @locationShareToggleOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on location sharing'**
  String get locationShareToggleOn;

  /// No description provided for @locationShareToggleOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off location sharing'**
  String get locationShareToggleOff;

  /// No description provided for @locationShareCancelHint.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is off — turn it on to report your position.'**
  String get locationShareCancelHint;

  /// No description provided for @locationResolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving address…'**
  String get locationResolving;

  /// No description provided for @locationAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable'**
  String get locationAddressUnavailable;

  /// No description provided for @locationAddressFallback.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable for this language — showing English.'**
  String get locationAddressFallback;

  /// No description provided for @locationFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen map'**
  String get locationFullscreen;

  /// No description provided for @locationExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get locationExitFullscreen;

  /// No description provided for @locationReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share location'**
  String get locationReportFailed;

  /// No description provided for @locationLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locationLocating;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'To share your position with family members, allow Sweet Home to access your location.'**
  String get locationPermissionBody;

  /// No description provided for @locationPermissionGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get locationPermissionGrant;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Enable it in system settings to share your location.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationPermissionOpenSettings;

  /// No description provided for @locationGpsOff.
  ///
  /// In en, this message translates to:
  /// **'GPS is off. Turn it on to share accurate location.'**
  String get locationGpsOff;

  /// No description provided for @locationGpsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get a GPS fix in time. Try again outdoors or check your signal.'**
  String get locationGpsTimeout;

  /// No description provided for @locationGpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location service isn\'t available on this device. Check system settings, mock-location app, or vendor privacy settings.'**
  String get locationGpsUnavailable;

  /// No description provided for @locationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get locationRefresh;

  /// No description provided for @joinRequestsAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get joinRequestsAdminTitle;

  /// No description provided for @joinRequestsAdminEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests right now.'**
  String get joinRequestsAdminEmpty;

  /// No description provided for @joinRequestsAdminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get joinRequestsAdminReject;

  /// No description provided for @joinRequestsAdminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get joinRequestsAdminApprove;

  /// No description provided for @joinRequestsAdminRelationLine.
  ///
  /// In en, this message translates to:
  /// **'Wants to be {relation} of {targetName}'**
  String joinRequestsAdminRelationLine(String relation, String targetName);

  /// No description provided for @joinRequestsAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'Message: {message}'**
  String joinRequestsAdminMessage(String message);

  /// No description provided for @joinRequestsAdminRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get joinRequestsAdminRejectDialogTitle;

  /// No description provided for @joinRequestsAdminRejectDialogReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get joinRequestsAdminRejectDialogReason;

  /// No description provided for @joinRequestsAdminRejectSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get joinRequestsAdminRejectSubmit;

  /// No description provided for @joinRequestsAdminRejectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get joinRequestsAdminRejectCancel;

  /// No description provided for @joinRequestsAdminRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get joinRequestsAdminRejectSuccess;

  /// No description provided for @joinRequestsAdminApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get joinRequestsAdminApproveSuccess;

  /// No description provided for @joinRequestsAdminError.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action'**
  String get joinRequestsAdminError;

  /// No description provided for @requestJoinModeByCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code'**
  String get requestJoinModeByCode;

  /// No description provided for @requestJoinModeByPhone.
  ///
  /// In en, this message translates to:
  /// **'Know a member\'s phone'**
  String get requestJoinModeByPhone;

  /// No description provided for @requestJoinNoFamilySubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get requestJoinNoFamilySubmit;

  /// No description provided for @requestJoinByCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Use the family\'s invite code if you have one.'**
  String get requestJoinByCodeHint;

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

  /// No description provided for @chatRoomSendImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send image'**
  String get chatRoomSendImageTooltip;

  /// No description provided for @chatRoomImageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading image…'**
  String get chatRoomImageUploading;

  /// No description provided for @chatRoomImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send image'**
  String get chatRoomImageUploadFailed;

  /// No description provided for @chatRoomEmojiTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open emoji picker'**
  String get chatRoomEmojiTooltip;

  /// No description provided for @chatRoomKeyboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show keyboard'**
  String get chatRoomKeyboardTooltip;

  /// No description provided for @emojiCategorySmileys.
  ///
  /// In en, this message translates to:
  /// **'Smileys & emotion'**
  String get emojiCategorySmileys;

  /// No description provided for @emojiCategoryPeople.
  ///
  /// In en, this message translates to:
  /// **'People & body'**
  String get emojiCategoryPeople;

  /// No description provided for @emojiCategoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals & nature'**
  String get emojiCategoryAnimals;

  /// No description provided for @emojiCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get emojiCategoryFood;

  /// No description provided for @emojiCategoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities & sports'**
  String get emojiCategoryActivities;

  /// No description provided for @emojiCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel & places'**
  String get emojiCategoryTravel;

  /// No description provided for @emojiCategoryObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get emojiCategoryObjects;

  /// No description provided for @emojiCategorySymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get emojiCategorySymbols;

  /// No description provided for @chatMessageTypeImage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get chatMessageTypeImage;

  /// No description provided for @chatMessageTypeVoice.
  ///
  /// In en, this message translates to:
  /// **'[Voice]'**
  String get chatMessageTypeVoice;

  /// No description provided for @chatMessageTypeSystem.
  ///
  /// In en, this message translates to:
  /// **'[System]'**
  String get chatMessageTypeSystem;

  /// No description provided for @locationHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Trajectory'**
  String get locationHistoryTitle;

  /// No description provided for @locationHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trajectory points for this day'**
  String get locationHistoryEmpty;

  /// No description provided for @locationHistoryEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'The member hasn\'t reported a location on the selected day.'**
  String get locationHistoryEmptyDesc;

  /// No description provided for @profileMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get profileMe;

  /// No description provided for @locationHistoryPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get locationHistoryPickDate;

  /// No description provided for @locationHistoryPointCount.
  ///
  /// In en, this message translates to:
  /// **'{count} trajectory points'**
  String locationHistoryPointCount(int count);

  /// No description provided for @locationHistoryForMember.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s trajectory'**
  String locationHistoryForMember(Object name);

  /// No description provided for @locationHistoryForDate.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String locationHistoryForDate(Object date);

  /// No description provided for @locationHistoryView.
  ///
  /// In en, this message translates to:
  /// **'View trajectory'**
  String get locationHistoryView;

  /// No description provided for @locationHistoryBatteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}%'**
  String locationHistoryBatteryLabel(Object percent);

  /// No description provided for @locationHistoryPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get locationHistoryPlay;

  /// No description provided for @locationHistoryPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get locationHistoryPause;

  /// No description provided for @locationHistoryReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get locationHistoryReplay;

  /// No description provided for @locationHistoryPointAddress.
  ///
  /// In en, this message translates to:
  /// **'📍 {address}'**
  String locationHistoryPointAddress(String address);

  /// No description provided for @fenceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Geofences'**
  String get fenceListTitle;

  /// No description provided for @fenceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No geofences yet'**
  String get fenceListEmpty;

  /// No description provided for @fenceListGuardingGroup.
  ///
  /// In en, this message translates to:
  /// **'I\'m watching'**
  String get fenceListGuardingGroup;

  /// No description provided for @fenceListGuardedGroup.
  ///
  /// In en, this message translates to:
  /// **'Watching me'**
  String get fenceListGuardedGroup;

  /// No description provided for @fenceListNoGuarding.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t set up any geofences yet.'**
  String get fenceListNoGuarding;

  /// No description provided for @fenceListNoGuarded.
  ///
  /// In en, this message translates to:
  /// **'No family member has set up a geofence for you.'**
  String get fenceListNoGuarded;

  /// No description provided for @fenceListEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a fence to be notified when a family member enters or leaves it.'**
  String get fenceListEmptyDesc;

  /// No description provided for @fenceCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Geofence'**
  String get fenceCreateTitle;

  /// No description provided for @fenceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Fence name'**
  String get fenceNameLabel;

  /// No description provided for @fenceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. School, Home'**
  String get fenceNameHint;

  /// No description provided for @fenceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius (meters)'**
  String get fenceRangeLabel;

  /// No description provided for @fenceRangeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 200'**
  String get fenceRangeHint;

  /// No description provided for @fenceInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'Radius must be greater than 0'**
  String get fenceInvalidRange;

  /// No description provided for @fencePickLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the fence center on the map'**
  String get fencePickLocationTitle;

  /// No description provided for @fencePickLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place the center, then set a radius.'**
  String get fencePickLocationHint;

  /// No description provided for @fencePickLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Center set'**
  String get fencePickLocationSelected;

  /// No description provided for @fencePickLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please pick a center on the map'**
  String get fencePickLocationRequired;

  /// No description provided for @fenceTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Watched member'**
  String get fenceTargetLabel;

  /// No description provided for @fenceCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Set by'**
  String get fenceCreatedBy;

  /// No description provided for @fenceCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String fenceCreatedAt(String date);

  /// No description provided for @fenceRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius {meters} m'**
  String fenceRadiusLabel(int meters);

  /// No description provided for @fenceCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get fenceCreateButton;

  /// No description provided for @fenceCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Geofence created'**
  String get fenceCreateSuccess;

  /// No description provided for @fenceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fenceDelete;

  /// No description provided for @fenceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this geofence?'**
  String get fenceDeleteConfirm;

  /// No description provided for @fenceDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Geofence deleted'**
  String get fenceDeleteSuccess;

  /// No description provided for @fenceNoWatchableMembers.
  ///
  /// In en, this message translates to:
  /// **'No family members to watch'**
  String get fenceNoWatchableMembers;

  /// No description provided for @fenceAlarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Geofence Alerts'**
  String get fenceAlarmsTitle;

  /// No description provided for @fenceAlarmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alerts'**
  String get fenceAlarmEmpty;

  /// No description provided for @fenceAlarmEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'You will be notified here when a member you watch leaves a fence.'**
  String get fenceAlarmEmptyDesc;

  /// No description provided for @fenceAlarmInside.
  ///
  /// In en, this message translates to:
  /// **'Entered'**
  String get fenceAlarmInside;

  /// No description provided for @fenceAlarmOutside.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get fenceAlarmOutside;

  /// No description provided for @fenceAlarmTime.
  ///
  /// In en, this message translates to:
  /// **'Triggered at {time}'**
  String fenceAlarmTime(String time);

  /// No description provided for @myHomeFenceEntry.
  ///
  /// In en, this message translates to:
  /// **'Geofences'**
  String get myHomeFenceEntry;

  /// No description provided for @myHomeFenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Set safe zones and get notified when family enters or leaves'**
  String get myHomeFenceDesc;

  /// No description provided for @myHomeFenceAlarmsEntry.
  ///
  /// In en, this message translates to:
  /// **'Geofence Alerts'**
  String get myHomeFenceAlarmsEntry;

  /// No description provided for @myHomeFenceAlarmsDesc.
  ///
  /// In en, this message translates to:
  /// **'History of when family entered or left a fence'**
  String get myHomeFenceAlarmsDesc;

  /// No description provided for @myHomeFamilyTreeEntry.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get myHomeFamilyTreeEntry;

  /// No description provided for @myHomeFamilyTreeDesc.
  ///
  /// In en, this message translates to:
  /// **'A clean view of your whole family at a glance'**
  String get myHomeFamilyTreeDesc;

  /// No description provided for @familyTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTreeTitle;

  /// No description provided for @familyTreeViewerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get familyTreeViewerYou;

  /// No description provided for @familyTreeViewerLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get familyTreeViewerLabel;

  /// No description provided for @familyTreeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No family members yet'**
  String get familyTreeEmpty;

  /// No description provided for @familyTreeEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Once your family joins, their relationships will appear here.'**
  String get familyTreeEmptyDesc;

  /// No description provided for @familyTreeOtherFamily.
  ///
  /// In en, this message translates to:
  /// **'Other relatives'**
  String get familyTreeOtherFamily;

  /// No description provided for @familyTreeOtherFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Plus {count} more family members shown as a list'**
  String familyTreeOtherFamilyDesc(Object count);

  /// No description provided for @appWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sweet Home'**
  String get appWindowTitle;

  /// No description provided for @myHomeSectionFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get myHomeSectionFamilyTitle;

  /// No description provided for @myHomeWelcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Home is where the heart gathers'**
  String get myHomeWelcomeTagline;

  /// No description provided for @greetingEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'It\'s late'**
  String get greetingEarlyMorning;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingNoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingNoon;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingLateNight.
  ///
  /// In en, this message translates to:
  /// **'It\'s late'**
  String get greetingLateNight;

  /// No description provided for @profileSectionFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get profileSectionFamilyTitle;

  /// No description provided for @profileSectionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSectionSettingsTitle;

  /// No description provided for @profileFamilyMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View all family members'**
  String get profileFamilyMembersSubtitle;

  /// No description provided for @profileJoinFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join another family with an invite code'**
  String get profileJoinFamilySubtitle;

  /// No description provided for @locationHubSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time Location'**
  String get locationHubSectionTitle;

  /// No description provided for @locationHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time Location'**
  String get locationHubTitle;

  /// No description provided for @locationHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live map, history, geofences and alerts for the whole family'**
  String get locationHubSubtitle;

  /// No description provided for @locationHubLiveMapDesc.
  ///
  /// In en, this message translates to:
  /// **'See where each family member is right now'**
  String get locationHubLiveMapDesc;

  /// No description provided for @locationHubHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'View a member\'s movement for a chosen day'**
  String get locationHubHistoryDesc;

  /// No description provided for @locationHubFenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Set safe zones and get notified on entry or exit'**
  String get locationHubFenceDesc;

  /// No description provided for @locationHubFenceAlarmsDesc.
  ///
  /// In en, this message translates to:
  /// **'History of when family entered or left a fence'**
  String get locationHubFenceAlarmsDesc;

  /// No description provided for @profileJoinRequestsRow.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get profileJoinRequestsRow;

  /// No description provided for @profileJoinRequestsAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Admin only'**
  String get profileJoinRequestsAdminOnly;

  /// No description provided for @familyFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No moments yet'**
  String get familyFeedEmptyTitle;

  /// No description provided for @familyFeedEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Post the first update for your family.'**
  String get familyFeedEmptyDesc;

  /// No description provided for @familyFeedLoadMoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more'**
  String get familyFeedLoadMoreError;

  /// No description provided for @familyFeedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this update?'**
  String get familyFeedDeleteTitle;

  /// No description provided for @familyFeedDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This update will be removed for everyone.'**
  String get familyFeedDeleteBody;

  /// No description provided for @familyFeedDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get familyFeedDeleteConfirm;

  /// No description provided for @familyFeedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Update deleted'**
  String get familyFeedDeleted;

  /// No description provided for @familyFeedLikeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get familyFeedLikeTooltip;

  /// No description provided for @familyFeedUnlikeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get familyFeedUnlikeTooltip;

  /// No description provided for @familyFeedLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 likes} =1{1 like} other{{count} likes}}'**
  String familyFeedLikeCount(int count);

  /// No description provided for @familyFeedMoreLikers.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String familyFeedMoreLikers(Object count);

  /// No description provided for @momentDetailLikedTimes.
  ///
  /// In en, this message translates to:
  /// **'Liked {count} times'**
  String momentDetailLikedTimes(int count);

  /// No description provided for @familyFeedNoCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get familyFeedNoCommentsYet;

  /// No description provided for @familyFeedCommentsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Comments are on the way'**
  String get familyFeedCommentsComingSoon;

  /// No description provided for @familyFeedPublishButton.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get familyFeedPublishButton;

  /// No description provided for @publishMomentTitle.
  ///
  /// In en, this message translates to:
  /// **'New update'**
  String get publishMomentTitle;

  /// No description provided for @publishMomentContentLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get publishMomentContentLabel;

  /// No description provided for @publishMomentContentHint.
  ///
  /// In en, this message translates to:
  /// **'Share a thought, a photo, or a moment from your day.'**
  String get publishMomentContentHint;

  /// No description provided for @publishMomentContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write something or add a photo'**
  String get publishMomentContentRequired;

  /// No description provided for @publishMomentAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get publishMomentAddMedia;

  /// No description provided for @publishMomentMediaTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get publishMomentMediaTypeImage;

  /// No description provided for @publishMomentMediaTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get publishMomentMediaTypeVideo;

  /// No description provided for @publishMomentMediaTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get publishMomentMediaTypeAudio;

  /// No description provided for @publishMomentAddMediaSheet.
  ///
  /// In en, this message translates to:
  /// **'Add to your post'**
  String get publishMomentAddMediaSheet;

  /// No description provided for @publishMomentMaxMedia.
  ///
  /// In en, this message translates to:
  /// **'Up to 9 files per post'**
  String get publishMomentMaxMedia;

  /// No description provided for @publishMomentRemoveMedia.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get publishMomentRemoveMedia;

  /// No description provided for @publishMomentRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get publishMomentRecordingHint;

  /// No description provided for @publishMomentRecordingStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get publishMomentRecordingStop;

  /// No description provided for @publishMomentRecordingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get publishMomentRecordingCancel;

  /// No description provided for @publishMomentRecordingTooShort.
  ///
  /// In en, this message translates to:
  /// **'Hold for a bit longer'**
  String get publishMomentRecordingTooShort;

  /// No description provided for @publishMomentRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t record audio'**
  String get publishMomentRecordingFailed;

  /// No description provided for @publishMomentRecordingPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to add a voice clip'**
  String get publishMomentRecordingPermissionBody;

  /// No description provided for @publishMomentPublish.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get publishMomentPublish;

  /// No description provided for @publishMomentPublishing.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get publishMomentPublishing;

  /// No description provided for @publishMomentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get publishMomentSuccess;

  /// No description provided for @publishMomentFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post — try again'**
  String get publishMomentFailed;

  /// No description provided for @publishMomentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current}/{total}…'**
  String publishMomentUploading(Object current, Object total);

  /// No description provided for @publishMomentDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this post?'**
  String get publishMomentDiscardTitle;

  /// No description provided for @publishMomentDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost.'**
  String get publishMomentDiscardBody;

  /// No description provided for @publishMomentDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get publishMomentDiscardConfirm;

  /// No description provided for @publishMomentDiscardCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get publishMomentDiscardCancel;

  /// No description provided for @momentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get momentDetailTitle;

  /// No description provided for @momentDetailWhoLikedTitle.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get momentDetailWhoLikedTitle;

  /// No description provided for @momentDetailNoLikes.
  ///
  /// In en, this message translates to:
  /// **'Be the first to like this'**
  String get momentDetailNoLikes;

  /// No description provided for @momentDetailPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get momentDetailPlayVideo;

  /// No description provided for @momentDetailVideoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load video'**
  String get momentDetailVideoLoadFailed;

  /// No description provided for @momentDetailAudioPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get momentDetailAudioPlay;

  /// No description provided for @momentDetailAudioPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get momentDetailAudioPause;

  /// No description provided for @publishMomentRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording {seconds}s — tap to stop'**
  String publishMomentRecordingInProgress(int seconds);

  /// No description provided for @publishMomentRecordingStopInline.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get publishMomentRecordingStopInline;

  /// No description provided for @publishMomentCompressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing…'**
  String get publishMomentCompressing;

  /// No description provided for @publishMomentVideoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Video is still {size} MB after compression — please pick a shorter clip.'**
  String publishMomentVideoTooLarge(String size);

  /// No description provided for @publishMomentVideoTooLargeRaw.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t compress video ({size} MB). Try a smaller file.'**
  String publishMomentVideoTooLargeRaw(String size);

  /// No description provided for @familyFeedLikeTooltipLong.
  ///
  /// In en, this message translates to:
  /// **'Tap to like · long-press to undo your likes'**
  String get familyFeedLikeTooltipLong;

  /// No description provided for @familyFeedLikeCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear your likes — try again'**
  String get familyFeedLikeCancelFailed;

  /// No description provided for @conversationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages and chats'**
  String get conversationsSearchHint;

  /// No description provided for @conversationsSearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Type a keyword to search your saved messages.'**
  String get conversationsSearchEmptyHint;

  /// No description provided for @conversationsSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\".'**
  String conversationsSearchNoResults(String query);

  /// No description provided for @profileThemeRow.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileThemeRow;

  /// No description provided for @profileThemeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a theme'**
  String get profileThemeSheetTitle;

  /// No description provided for @momentCommentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get momentCommentSectionTitle;

  /// No description provided for @momentCommentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment'**
  String get momentCommentEmpty;

  /// No description provided for @momentCommentInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get momentCommentInputHint;

  /// No description provided for @momentCommentSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get momentCommentSend;

  /// No description provided for @momentCommentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get momentCommentDeleteTitle;

  /// No description provided for @momentCommentDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This comment will be removed for everyone.'**
  String get momentCommentDeleteBody;

  /// No description provided for @momentCommentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the comment — please try again.'**
  String get momentCommentDeleteFailed;

  /// No description provided for @chatMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message is too long (max 2000 characters).'**
  String get chatMessageTooLong;
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
