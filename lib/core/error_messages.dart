import '../l10n/app_localizations.dart';

/// Providers have no BuildContext to localize with, so local (non-server)
/// error fallbacks are stored as sentinels and localized at the UI layer.
const String kNetworkErrorSentinel = 'NETWORK_ERROR';

/// Maps a raw error string (sentinel or server-provided message) to display
/// text.
///
/// The server never sends user-facing prose: every error response's
/// `message` field is the raw `ErrorCode` enum constant name (e.g.
/// `INVALID_REDPACKET_AMOUNT`, `LOGIN_FAILED`) — see
/// `asia.sweethome.common.exception.ErrorCode` on the backend — which is
/// useless shown directly to a user. This is the single place that maps
/// every one of those codes to the active locale's text. Any code not in
/// this switch (e.g. a future backend addition this table hasn't caught
/// up with yet) falls through to the raw string rather than crashing, the
/// same fallback every caller already expects.
String localizeErrorMessage(String raw, AppLocalizations l10n) {
  if (raw == kNetworkErrorSentinel) return l10n.errorNetworkFailed;
  switch (raw) {
    // COMMON
    case 'PARAM_ERROR':
      return l10n.errorParamInvalid;
    case 'UNAUTHORIZED':
      return l10n.errorUnauthorized;
    case 'FORBIDDEN':
      return l10n.errorForbidden;
    case 'NOT_FOUND':
      return l10n.errorResourceNotFound;
    case 'CONFLICT':
      return l10n.errorDataConflict;
    case 'SYSTEM_ERROR':
      return l10n.errorSystemBusy;

    // FILE UPLOAD
    case 'EMPTY_FILE':
      return l10n.errorEmptyFile;
    case 'FILE_SIZE_ILLEGAL':
      return l10n.errorFileSizeIllegal;
    case 'FILE_TYPE_ILLEGAL':
      return l10n.errorFileTypeIllegal;
    case 'FILE_NAME_ILLEGAL':
      return l10n.errorFileNameIllegal;
    case 'FILE_UPLOAD_ERROR':
      return l10n.errorFileUploadFailed;

    // AUTH
    case 'PHONE_FORMAT_NOT_VALID':
      return l10n.errorPhoneFormatInvalid;
    case 'PASSWORD_FORMAT_NOT_VALID':
      return l10n.errorPasswordFormatInvalid;
    case 'NAME_FORMAT_NOT_VALID':
      return l10n.errorNameFormatInvalid;
    case 'REGISTER_PARAM_CONFLICT':
      return l10n.errorRegisterParamConflict;
    case 'PHONE_ALREADY_EXISTS':
      return l10n.errorPhoneAlreadyExists;
    case 'LOGIN_FAILED':
      return l10n.errorLoginFailed;
    case 'TOKEN_INVALID':
      return l10n.errorTokenInvalid;
    case 'TOKEN_EXPIRED':
      return l10n.errorTokenExpired;
    case 'REFRESH_TOKEN_INVALID':
      return l10n.errorRefreshTokenInvalid;
    case 'USER_NOT_FOUND':
      return l10n.errorUserNotFound;

    // FAMILY
    case 'FAMILY_NAME_EMPTY':
      return l10n.errorFamilyNameEmpty;
    case 'FAMILY_INVITE_CODE_EMPTY':
      return l10n.errorInviteCodeEmpty;
    case 'INVALID_RELATION_TYPE':
      return l10n.errorRelationTypeInvalid;
    case 'NO_SUCH_FAMILY':
      return l10n.errorFamilyNotFound;
    case 'NO_SUCH_FAMILY_MEMBER':
      return l10n.errorFamilyMemberNotFound;
    case 'INVITE_CODE_INVALID':
      return l10n.errorInviteCodeInvalid;
    case 'INVALID_RELATION_ANCHOR':
      return l10n.errorRelationAnchorInvalid;
    case 'NOT_FAMILY_MEMBER':
      return l10n.errorNotFamilyMember;
    case 'NOT_FAMILY_ADMIN':
      return l10n.errorNotFamilyAdmin;
    case 'FAMILY_SAVE_FAILURE':
      return l10n.errorFamilySaveFailed;

    // FAMILY_RELATION
    case 'SPOUSE_ALREADY_EXISTS':
      return l10n.errorSpouseAlreadyExists;
    case 'NO_KNOWN_PARENT':
      return l10n.errorNoKnownParent;

    // CHAT
    case 'NO_SUCH_CONVERSATION':
      return l10n.errorConversationNotFound;
    case 'NOT_CONVERSATION_MEMBER':
      return l10n.redpacketErrorNotMember;
    case 'MESSAGE_TOO_LONG':
      return l10n.errorMessageTooLong;
    case 'INVALID_MESSAGE_TYPE':
      return l10n.errorMessageTypeInvalid;

    // LOCATION
    case 'LOCATION_COORDINATE_INVALID':
      return l10n.errorLocationCoordinateInvalid;
    case 'LOCATION_BATTERY_INVALID':
      return l10n.errorLocationBatteryInvalid;
    case 'LOCATION_TIMESTAMP_MISSING':
      return l10n.errorLocationTimestampMissing;
    case 'LOCATION_TIMESTAMP_STALE':
      return l10n.errorLocationTimestampStale;
    case 'LOCATION_TARGET_NOT_FAMILY_MEMBER':
      return l10n.errorLocationTargetNotFamilyMember;
    case 'LOCATION_FENCE_RANGE_INVALID':
      return l10n.errorFenceRangeInvalid;
    case 'NO_SUCH_FENCE':
      return l10n.errorFenceNotFound;
    case 'NOT_FENCE_SETTER':
      return l10n.errorNotFenceSetter;

    // MOMENT
    case 'MOMENT_CONTENT_EMPTY':
      return l10n.errorMomentContentEmpty;
    case 'INVALID_MOMENT_MEDIA_TYPE':
      return l10n.errorMomentMediaTypeInvalid;
    case 'NO_SUCH_LIKE_RECORD':
      return l10n.errorLikeRecordNotFound;
    case 'NO_SUCH_MOMENT':
      return l10n.errorMomentNotFound;
    case 'NOT_MOMENT_OWNER':
      return l10n.errorNotMomentOwner;
    case 'COMMENT_CONTENT_EMPTY':
      return l10n.errorCommentContentEmpty;
    case 'NO_SUCH_COMMENT':
      return l10n.errorCommentNotFound;
    case 'NOT_COMMENT_OWNER':
      return l10n.errorNotCommentOwner;

    // HEALTH
    case 'INVALID_HEALTH_METRIC_TYPE':
      return l10n.errorHealthMetricTypeInvalid;
    case 'HEALTH_RECORD_VALUE_INVALID':
      return l10n.errorHealthRecordValueInvalid;
    case 'NOT_SAME_FAMILY':
      return l10n.errorNotSameFamily;
    case 'INVALID_REMIND_TIME':
      return l10n.errorRemindTimeInvalid;
    case 'NO_SUCH_HEALTH_RECORD':
      return l10n.errorHealthRecordNotFound;
    case 'NOT_HEALTH_RECORD_OWNER':
      return l10n.errorNotHealthRecordOwner;
    case 'HEALTH_RECORD_DATE_CONFLICT':
      return l10n.errorHealthRecordDateConflict;

    // REDPACKET
    case 'INVALID_REDPACKET_AMOUNT':
      return l10n.redpacketErrorInvalidAmount;
    case 'REDPACKET_NUMBER_MORE_THAN_CONVERSATION_MEMBERS':
      return l10n.redpacketErrorTooManyShares;
    case 'REDPACKET_EXPIRED':
      return l10n.redpacketErrorExpired;
    case 'REDPACKET_GRABBED_ALREADY':
      return l10n.redpacketErrorAlreadyGrabbed;
    case 'REDPACKET_EMPTY':
      return l10n.redpacketErrorEmpty;
    case 'INVALID_REDPACKET':
      return l10n.redpacketErrorNotFound;

    // WALLET
    case 'INSUFFICIENT_FUND':
      return l10n.redpacketErrorInsufficientFund;
  }
  return raw;
}
