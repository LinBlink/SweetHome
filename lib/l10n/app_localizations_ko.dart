// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '과가가 · Sweet Home';

  @override
  String get brandName => '과가가';

  @override
  String get appTagline => '가족의 따뜻함, 한 번의 터치로';

  @override
  String get navMessages => '메시지';

  @override
  String get navProfile => '나';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonPasswordLabel => '비밀번호';

  @override
  String get commonPasswordRequired => '비밀번호를 입력해주세요';

  @override
  String get commonPasswordTooShort => '비밀번호는 최소 6자 이상이어야 합니다';

  @override
  String get errorNetworkFailed => '네트워크 연결에 실패했습니다. 잠시 후 다시 시도해주세요';

  @override
  String get loginButton => '로그인';

  @override
  String get loginNoAccount => '계정이 없으신가요?';

  @override
  String get loginRegisterNow => '지금 가입하기';

  @override
  String get registerTitle => '계정 만들기';

  @override
  String get registerNicknameLabel => '닉네임';

  @override
  String get registerNicknameRequired => '닉네임을 입력해주세요';

  @override
  String get registerGenderLabel => '성별';

  @override
  String get registerGenderMale => '남성';

  @override
  String get registerGenderFemale => '여성';

  @override
  String get registerGenderRequired => '성별을 선택해주세요';

  @override
  String get registerCreateFamilyTab => '새 가족 만들기';

  @override
  String get registerJoinFamilyTab => '기존 가족 참여하기';

  @override
  String get registerRequestJoinTab => '초대 코드 요청';

  @override
  String get registerFamilyNameLabel => '가족 이름 (예: 왕씨 가족)';

  @override
  String get registerFamilyNameRequired => '가족 이름을 입력해주세요';

  @override
  String get registerFamilyNameHint => '* 가입 후 초대 코드를 생성하여 가족을 초대할 수 있습니다';

  @override
  String get registerInviteCodeLabel => '가족 초대 코드';

  @override
  String get registerInviteCodeRequired => '초대 코드를 입력해주세요';

  @override
  String get registerInviteCodeInvalid => '초대 코드 형식이 올바르지 않습니다';

  @override
  String get registerInviteCodeHint => '* 초대 코드는 가족 관리자가 생성하며 48시간 동안 유효합니다';

  @override
  String get registerFindFamilyButton => '가족 찾기';

  @override
  String get registerFindFamilyFailed => '해당 초대 코드로 가족을 찾을 수 없습니다';

  @override
  String get registerRelationLabel => '그 사람과의 관계';

  @override
  String get registerRelationChild => '그의 자녀';

  @override
  String get registerRelationParent => '그의 부모';

  @override
  String get registerRelationSpouse => '그의 배우자';

  @override
  String get registerRelationSibling => '그의 형제자매';

  @override
  String get registerRelationAnchorRequired => '어느 구성원과의 관계인지 선택해주세요';

  @override
  String get registerSubmitCreate => '가입하고 가족 만들기';

  @override
  String get registerSubmitJoin => '가입하고 가족 참여하기';

  @override
  String get requestJoinTargetPhoneLabel => '아는 가족 구성원의 전화번호';

  @override
  String get requestJoinTargetPhoneRequired => '상대방의 전화번호를 입력해주세요';

  @override
  String get requestJoinTargetPhoneHint =>
      '* 초대 코드가 필요 없습니다 — 이미 그 가족에 속한 사람의 전화번호만 입력하면 됩니다. 해당 가족의 관리자가 요청을 검토합니다';

  @override
  String get requestJoinMessageLabel => '관리자에게 남길 메시지 (선택)';

  @override
  String get requestJoinSubmit => '요청 제출';

  @override
  String get requestJoinSubmittedTitle => '요청이 제출되었습니다';

  @override
  String get requestJoinSubmittedMessage =>
      '요청이 가족 관리자에게 전송되어 검토 중입니다. 승인되면 방금 입력한 전화번호와 비밀번호로 로그인하세요';

  @override
  String get joinRequestsTitle => '가입 요청';

  @override
  String get joinRequestsEmpty => '대기 중인 요청이 없습니다';

  @override
  String joinRequestsRelationLine(String relation, String targetName) {
    return '$targetName의 $relation(이)가 되고 싶어합니다';
  }

  @override
  String get relationNounChild => '자녀';

  @override
  String get relationNounParent => '부모';

  @override
  String get relationNounSpouse => '배우자';

  @override
  String get relationNounSibling => '형제자매';

  @override
  String get joinRequestsApprove => '승인';

  @override
  String get joinRequestsReject => '거절';

  @override
  String get phoneLabel => '휴대폰 번호';

  @override
  String get phoneRequired => '휴대폰 번호를 입력해주세요';

  @override
  String get phoneInvalid => '휴대폰 번호 형식이 올바르지 않습니다';

  @override
  String get countryPickerTitle => '국가/지역 선택';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get profileLogoutConfirmMessage => '정말 로그아웃 하시겠습니까?';

  @override
  String get profileLanguageRow => '언어';

  @override
  String get profileFamilyMembersRow => '가족 구성원';

  @override
  String get conversationsSearchTooltip => '검색';

  @override
  String get conversationsNewTooltip => '새 대화';

  @override
  String get conversationsEmptyTitle => '아직 메시지가 없습니다';

  @override
  String get conversationsEmptySubtitle => '가족을 초대하여 대화를 시작해보세요';

  @override
  String get connectionErrorRetry => '다시 시도';

  @override
  String get newConversationTitle => '새 대화';

  @override
  String get editProfileTitle => '프로필 편집';

  @override
  String get editProfileNicknameLabel => '닉네임';

  @override
  String get editProfileSave => '저장';

  @override
  String get inviteGenerate => '초대';

  @override
  String get inviteCodeLabel => '초대 코드';

  @override
  String inviteExpiryDays(int days) {
    return '$days일 후에 만료';
  }

  @override
  String inviteExpiryHours(int hours) {
    return '$hours시간 후에 만료';
  }

  @override
  String inviteExpiryMinutes(int minutes) {
    return '$minutes분 후에 만료';
  }

  @override
  String get inviteExpiryLessThanMinute => '곧 만료';

  @override
  String get inviteExpiryExpired => '만료됨';

  @override
  String get inviteCopy => '복사';

  @override
  String get inviteCopied => '클립보드에 복사되었습니다';

  @override
  String get joinFamilyTitle => '다른 가족 참여하기';

  @override
  String get joinFamilyConfirmMessage =>
      '새 가족에 참여하면 현재 가족에서 나가게 됩니다. 계속하시겠습니까?';

  @override
  String chatRoomMessageCount(int count) {
    return '메시지 $count개';
  }

  @override
  String get chatRoomDefaultSubtitle => '가족 채팅방';

  @override
  String get chatRoomMoreTooltip => '더보기';

  @override
  String get chatRoomEmptyHint => '메시지를 보내 인사해보세요';

  @override
  String get chatRoomInputHint => '메시지를 입력하세요...';

  @override
  String get chatRoomMoreOption => '더보기';

  @override
  String get familyMembersTitle => '가족 구성원';

  @override
  String get familyMembersAdminBadge => '관리자';

  @override
  String get timeJustNow => '방금 전';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String get timeYesterday => '어제';

  @override
  String get countryChina => '중국';

  @override
  String get countryUSA => '미국';

  @override
  String get countryCanada => '캐나다';

  @override
  String get countryFrance => '프랑스';

  @override
  String get countryUK => '영국';

  @override
  String get countryGermany => '독일';

  @override
  String get countryMalaysia => '말레이시아';

  @override
  String get countryAustralia => '호주';

  @override
  String get countryIndonesia => '인도네시아';

  @override
  String get countryPhilippines => '필리핀';

  @override
  String get countryNewZealand => '뉴질랜드';

  @override
  String get countrySingapore => '싱가포르';

  @override
  String get countryThailand => '태국';

  @override
  String get countryJapan => '일본';

  @override
  String get countryKorea => '대한민국';

  @override
  String get countryVietnam => '베트남';

  @override
  String get countryIndia => '인도';

  @override
  String get countryMyanmar => '미얀마';

  @override
  String get countryHongKong => '홍콩';

  @override
  String get countryMacau => '마카오';

  @override
  String get countryTaiwan => '대만';
}
