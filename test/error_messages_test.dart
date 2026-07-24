import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/error_messages.dart';
import 'package:sweethome_flutter/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('localizeErrorMessage', () {
    test('network sentinel maps to the network-failure message', () {
      expect(localizeErrorMessage(kNetworkErrorSentinel, l10n),
          l10n.errorNetworkFailed);
    });

    test('an unrecognized code falls through to the raw string', () {
      expect(localizeErrorMessage('SOME_FUTURE_ERROR_CODE', l10n),
          'SOME_FUTURE_ERROR_CODE');
    });

    // One representative code per `ErrorCode` module — locks in that
    // every module's codes are actually wired up, without enumerating
    // all ~60 (the switch statement itself is the exhaustive list).
    test('COMMON: PARAM_ERROR', () {
      expect(
          localizeErrorMessage('PARAM_ERROR', l10n), l10n.errorParamInvalid);
    });

    test('FILE UPLOAD: FILE_TYPE_ILLEGAL', () {
      expect(localizeErrorMessage('FILE_TYPE_ILLEGAL', l10n),
          l10n.errorFileTypeIllegal);
    });

    test('AUTH: LOGIN_FAILED', () {
      expect(
          localizeErrorMessage('LOGIN_FAILED', l10n), l10n.errorLoginFailed);
    });

    test('FAMILY: NOT_FAMILY_ADMIN', () {
      expect(localizeErrorMessage('NOT_FAMILY_ADMIN', l10n),
          l10n.errorNotFamilyAdmin);
    });

    test('FAMILY_RELATION: SPOUSE_ALREADY_EXISTS', () {
      expect(localizeErrorMessage('SPOUSE_ALREADY_EXISTS', l10n),
          l10n.errorSpouseAlreadyExists);
    });

    test('CHAT: NOT_CONVERSATION_MEMBER reuses the redpacket string', () {
      expect(localizeErrorMessage('NOT_CONVERSATION_MEMBER', l10n),
          l10n.redpacketErrorNotMember);
    });

    test('LOCATION: NOT_FENCE_SETTER', () {
      expect(localizeErrorMessage('NOT_FENCE_SETTER', l10n),
          l10n.errorNotFenceSetter);
    });

    test('MOMENT: NOT_COMMENT_OWNER', () {
      expect(localizeErrorMessage('NOT_COMMENT_OWNER', l10n),
          l10n.errorNotCommentOwner);
    });

    test('HEALTH: HEALTH_RECORD_DATE_CONFLICT', () {
      expect(localizeErrorMessage('HEALTH_RECORD_DATE_CONFLICT', l10n),
          l10n.errorHealthRecordDateConflict);
    });

    test('REDPACKET: INVALID_REDPACKET (unchanged from before this change)',
        () {
      expect(localizeErrorMessage('INVALID_REDPACKET', l10n),
          l10n.redpacketErrorNotFound);
    });

    test('WALLET: INSUFFICIENT_FUND (unchanged from before this change)', () {
      expect(localizeErrorMessage('INSUFFICIENT_FUND', l10n),
          l10n.redpacketErrorInsufficientFund);
    });
  });
}
