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
  String get navContacts => '연락처';

  @override
  String get navMyHome => '홈';

  @override
  String get navFamilyFeed => '패밀리 피드';

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
  String get profileLogoutConfirmMessage => '로그아웃하시겠습니까?';

  @override
  String get profileLanguageRow => '언어';

  @override
  String get profileFamilyMembersRow => '가족 구성원';

  @override
  String get myHomeTitle => '홈';

  @override
  String get myHomeLocationEntry => '실시간 위치';

  @override
  String get myHomeLocationDesc => '가족 구성원의 현재 위치를 확인하세요';

  @override
  String get myHomeJoinRequestsEntry => '가입 요청';

  @override
  String get myHomeJoinRequestsDesc => '가족 가입 요청 검토 및 승인';

  @override
  String myHomeJoinRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count건 대기',
      one: '1건 대기',
      zero: '대기 없음',
    );
    return '$_temp0';
  }

  @override
  String get familyFeedTitle => '패밀리 피드';

  @override
  String get familyFeedComingSoon => '곧 출시';

  @override
  String get familyFeedComingSoonDesc => '가족 소식과 마일스톤이 곧 도착합니다.';

  @override
  String get contactsTitle => '연락처';

  @override
  String get contactsEmpty => '아직 가족 구성원이 없습니다';

  @override
  String get locationTitle => '실시간 위치';

  @override
  String get locationOnline => '온라인';

  @override
  String get locationOffline => '최근 위치 없음';

  @override
  String get locationUpdatedJustNow => '방금 업데이트됨';

  @override
  String locationUpdatedMinutesAgo(Object minutes) {
    return '$minutes분 전 업데이트';
  }

  @override
  String locationBattery(Object percent) {
    return '배터리: $percent%';
  }

  @override
  String get locationBatteryUnknown => '배터리: 알 수 없음';

  @override
  String locationCoordinates(Object lat, Object lng) {
    return '경도 $lng, 위도 $lat';
  }

  @override
  String get locationNoData => '아직 위치 정보가 없습니다';

  @override
  String get locationNoDataDesc => '가족 구성원이 위치 공유를 켜야 여기에 표시됩니다.';

  @override
  String locationTotalMembers(Object total) {
    return '가족 $total명';
  }

  @override
  String locationOnlineCount(Object online, Object total) {
    return '$online/$total명이 위치를 공유 중';
  }

  @override
  String get locationReportNow => '내 위치 공유하기';

  @override
  String get locationShareOnTitle => '위치 공유가 켜져 있습니다';

  @override
  String get locationShareOffTitle => '위치 공유가 꺼져 있습니다';

  @override
  String get locationShareOnSubtitle => '현재 위치가 약 30초마다 가족에게 자동 전송됩니다.';

  @override
  String get locationShareOffSubtitle => '켜면 가족이 내 위치를 볼 수 있습니다.';

  @override
  String get locationShareToggleOn => '위치 공유 켜기';

  @override
  String get locationShareToggleOff => '위치 공유 끄기';

  @override
  String get locationShareCancelHint => '위치 공유가 꺼져 있습니다 — 켜면 위치가 자동으로 공유됩니다.';

  @override
  String get locationResolving => '주소 확인 중…';

  @override
  String get locationAddressUnavailable => '주소를 확인할 수 없습니다';

  @override
  String get locationAddressFallback => '이 언어의 주소 데이터가 없어 영어로 표시합니다.';

  @override
  String get locationFullscreen => '전체 화면 지도';

  @override
  String get locationExitFullscreen => '전체 화면 종료';

  @override
  String get locationReportFailed => '위치를 공유할 수 없습니다';

  @override
  String get locationLocating => '위치 확인 중…';

  @override
  String get locationPermissionTitle => '위치 권한이 필요합니다';

  @override
  String get locationPermissionBody =>
      '가족과 위치를 공유하려면 Sweet Home의 위치 접근을 허용해주세요.';

  @override
  String get locationPermissionGrant => '권한 허용';

  @override
  String get locationPermissionDenied =>
      '권한이 거부되었습니다. 시스템 설정에서 허용한 후 다시 시도해주세요.';

  @override
  String get locationPermissionOpenSettings => '설정 열기';

  @override
  String get locationGpsOff => 'GPS가 꺼져 있습니다. 켜면 정확한 위치를 공유할 수 있습니다.';

  @override
  String get locationGpsTimeout =>
      '시간 내에 GPS 위치를 가져오지 못했습니다. 실외에서 신호를 확인한 후 다시 시도해주세요.';

  @override
  String get locationGpsUnavailable =>
      '이 기기에서 위치 서비스를 사용할 수 없습니다. 시스템 설정, 모의 위치 앱, 제조사 개인정보 설정을 확인해주세요.';

  @override
  String get locationRefresh => '새로고침';

  @override
  String get joinRequestsAdminTitle => '가입 요청';

  @override
  String get joinRequestsAdminEmpty => '현재 대기 중인 요청이 없습니다.';

  @override
  String get joinRequestsAdminReject => '거절';

  @override
  String get joinRequestsAdminApprove => '승인';

  @override
  String joinRequestsAdminRelationLine(String relation, String targetName) {
    return '$targetName의 $relation이 되고 싶음';
  }

  @override
  String joinRequestsAdminMessage(String message) {
    return '메시지: $message';
  }

  @override
  String get joinRequestsAdminRejectDialogTitle => '이 요청을 거절하시겠습니까?';

  @override
  String get joinRequestsAdminRejectDialogReason => '거절 사유 (선택)';

  @override
  String get joinRequestsAdminRejectSubmit => '거절';

  @override
  String get joinRequestsAdminRejectCancel => '취소';

  @override
  String get joinRequestsAdminRejectSuccess => '요청이 거절되었습니다';

  @override
  String get joinRequestsAdminApproveSuccess => '요청이 승인되었습니다';

  @override
  String get joinRequestsAdminError => '작업을 완료할 수 없습니다';

  @override
  String get requestJoinModeByCode => '초대 코드가 있어요';

  @override
  String get requestJoinModeByPhone => '구성원 전화번호를 알아요';

  @override
  String get requestJoinNoFamilySubmit => '요청 보내기';

  @override
  String get requestJoinByCodeHint => '초대 코드가 있는 경우 사용하세요.';

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
  String get editProfileChangeAvatar => '아바타 변경';

  @override
  String get editProfileAvatarUploading => '업로드 중…';

  @override
  String get editProfileAvatarFailed => '업로드에 실패했습니다. 다시 시도해 주세요';

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

  @override
  String get chatRoomSendImageTooltip => '이미지 보내기';

  @override
  String get chatRoomImageUploading => '이미지 업로드 중…';

  @override
  String get chatRoomImageUploadFailed => '이미지를 보낼 수 없습니다';

  @override
  String get chatRoomEmojiTooltip => '이모지 선택기 열기';

  @override
  String get chatRoomKeyboardTooltip => '키보드 표시';

  @override
  String get emojiCategorySmileys => '스마일 · 감정';

  @override
  String get emojiCategoryPeople => '사람 · 몸';

  @override
  String get emojiCategoryAnimals => '동물 · 자연';

  @override
  String get emojiCategoryFood => '음식 · 음료';

  @override
  String get emojiCategoryActivities => '활동 · 스포츠';

  @override
  String get emojiCategoryTravel => '여행 · 장소';

  @override
  String get emojiCategoryObjects => '사물';

  @override
  String get emojiCategorySymbols => '기호';

  @override
  String get chatMessageTypeImage => '[이미지]';

  @override
  String get chatMessageTypeVoice => '[음성]';

  @override
  String get chatMessageTypeSystem => '[시스템]';

  @override
  String get locationHistoryTitle => '오늘의 이동 경로';

  @override
  String get locationHistoryEmpty => '이 날의 이동 경로 데이터가 없습니다';

  @override
  String get locationHistoryEmptyDesc => '선택한 날짜에 구성원이 위치를 보고하지 않았습니다.';

  @override
  String get profileMe => '나';

  @override
  String get locationHistoryPickDate => '날짜 선택';

  @override
  String locationHistoryPointCount(int count) {
    return '경로 포인트 $count개';
  }

  @override
  String locationHistoryForMember(Object name) {
    return '$name의 이동 경로';
  }

  @override
  String locationHistoryForDate(Object date) {
    return '$date 이동 경로';
  }

  @override
  String get locationHistoryView => '경로 보기';

  @override
  String locationHistoryBatteryLabel(Object percent) {
    return '배터리 $percent%';
  }

  @override
  String get locationHistoryPlay => '재생';

  @override
  String get locationHistoryPause => '일시정지';

  @override
  String get locationHistoryReplay => '다시 재생';

  @override
  String locationHistoryPointAddress(String address) {
    return '📍 $address';
  }

  @override
  String get fenceListTitle => '지오펜스';

  @override
  String get fenceListEmpty => '지오펜스가 없습니다';

  @override
  String get fenceListGuardingGroup => '내가 지킴';

  @override
  String get fenceListGuardedGroup => '지켜주는 사람';

  @override
  String get fenceListNoGuarding => '아직 설정한 지오펜스가 없습니다.';

  @override
  String get fenceListNoGuarded => '아직 나를 위한 지오펜스를 설정한 가족이 없습니다.';

  @override
  String get fenceListEmptyDesc =>
      '가족이 영역에 들어가거나 나올 때 알림을 받을 수 있는 안전 구역을 추가하세요.';

  @override
  String get fenceCreateTitle => '지오펜스 추가';

  @override
  String get fenceNameLabel => '펜스 이름';

  @override
  String get fenceNameHint => '예: 학교, 집';

  @override
  String get fenceRangeLabel => '반경 (미터)';

  @override
  String get fenceRangeHint => '예: 200';

  @override
  String get fenceInvalidRange => '반경은 0보다 커야 합니다';

  @override
  String get fencePickLocationTitle => '지도에서 중심점 선택';

  @override
  String get fencePickLocationHint => '지도를 탭하여 중심점을 놓고 반경을 설정하세요.';

  @override
  String get fencePickLocationSelected => '중심점이 설정됨';

  @override
  String get fencePickLocationRequired => '지도에서 중심점을 선택해주세요';

  @override
  String get fenceTargetLabel => '관찰 대상';

  @override
  String get fenceCreatedBy => '설정자';

  @override
  String fenceCreatedAt(String date) {
    return '생성일 $date';
  }

  @override
  String fenceRadiusLabel(int meters) {
    return '반경 ${meters}m';
  }

  @override
  String get fenceCreateButton => '생성';

  @override
  String get fenceCreateSuccess => '지오펜스가 생성되었습니다';

  @override
  String get fenceDelete => '삭제';

  @override
  String get fenceDeleteConfirm => '이 지오펜스를 삭제하시겠습니까?';

  @override
  String get fenceDeleteSuccess => '지오펜스가 삭제되었습니다';

  @override
  String get fenceNoWatchableMembers => '관찰할 가족 구성원이 없습니다';

  @override
  String get fenceAlarmsTitle => '지오펜스 알림';

  @override
  String get fenceAlarmEmpty => '알림 없음';

  @override
  String get fenceAlarmEmptyDesc => '관찰 중인 가족이 펜스를 출입하면 여기에 알림이 표시됩니다.';

  @override
  String get fenceAlarmInside => '진입';

  @override
  String get fenceAlarmOutside => '이탈';

  @override
  String fenceAlarmTime(String time) {
    return '알림 시각 $time';
  }

  @override
  String get myHomeFenceEntry => '지오펜스';

  @override
  String get myHomeFenceDesc => '가족의 안전 영역을 설정하고 출입 알림 받기';

  @override
  String get myHomeFenceAlarmsEntry => '지오펜스 알림';

  @override
  String get myHomeFenceAlarmsDesc => '가족의 펜스 출입 기록 확인';

  @override
  String get myHomeFamilyTreeEntry => '가계도';

  @override
  String get myHomeFamilyTreeDesc => '가족을 한눈에 보기';

  @override
  String get familyTreeTitle => '가계도';

  @override
  String get familyTreeViewerYou => '나';

  @override
  String get familyTreeViewerLabel => '본인';

  @override
  String get familyTreeEmpty => '아직 가족이 없습니다';

  @override
  String get familyTreeEmptyDesc => '가족이 가입하면 관계가 여기에 표시됩니다.';

  @override
  String get familyTreeOtherFamily => '기타 친척';

  @override
  String familyTreeOtherFamilyDesc(Object count) {
    return '나머지 $count명의 가족은 목록으로 표시';
  }

  @override
  String get appWindowTitle => 'Sweet Home';

  @override
  String get myHomeSectionFamilyTitle => '가족';

  @override
  String get myHomeWelcomeTagline => '가족의 따스함이 함께하는 곳';

  @override
  String get greetingEarlyMorning => '늦은 시간이네요';

  @override
  String get greetingMorning => '좋은 아침입니다';

  @override
  String get greetingNoon => '안녕하세요';

  @override
  String get greetingAfternoon => '좋은 오후입니다';

  @override
  String get greetingEvening => '좋은 저녁입니다';

  @override
  String get greetingLateNight => '늦은 시간이네요';

  @override
  String get profileSectionFamilyTitle => '가족';

  @override
  String get profileSectionSettingsTitle => '설정';

  @override
  String get profileFamilyMembersSubtitle => '모든 가족 구성원 보기';

  @override
  String get profileJoinFamilySubtitle => '초대 코드로 다른 가족에 참여';

  @override
  String get locationHubSectionTitle => '실시간 위치';

  @override
  String get locationHubTitle => '실시간 위치';

  @override
  String get locationHubSubtitle => '가족의 실시간 위치, 이동 경로, 지오펜스 및 알림';

  @override
  String get locationHubLiveMapDesc => '가족 구성원의 현재 위치를 확인하세요';

  @override
  String get locationHubHistoryDesc => '구성원의 하루 이동 경로 확인';

  @override
  String get locationHubFenceDesc => '안전 영역을 설정하고 출입 알림 받기';

  @override
  String get locationHubFenceAlarmsDesc => '가족의 펜스 출입 기록 확인';

  @override
  String get profileJoinRequestsRow => '가입 요청';

  @override
  String get profileJoinRequestsAdminOnly => '관리자만';

  @override
  String get familyFeedEmptyTitle => '아직 게시글이 없어요';

  @override
  String get familyFeedEmptyDesc => '가족에 첫 게시글을 올려보세요.';

  @override
  String get familyFeedLoadMoreError => '더 불러오기 실패';

  @override
  String get familyFeedDeleteTitle => '이 게시글을 삭제할까요?';

  @override
  String get familyFeedDeleteBody => '삭제하면 가족 모두가 더 이상 볼 수 없어요.';

  @override
  String get familyFeedDeleteConfirm => '삭제';

  @override
  String get familyFeedDeleted => '게시글이 삭제되었어요';

  @override
  String get familyFeedLikeTooltip => '좋아요';

  @override
  String get familyFeedUnlikeTooltip => '좋아요 취소';

  @override
  String familyFeedLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '좋아요 $count개',
      zero: '좋아요 0개',
    );
    return '$_temp0';
  }

  @override
  String familyFeedMoreLikers(Object count) {
    return '$count명 더';
  }

  @override
  String get familyFeedNoCommentsYet => '아직 댓글이 없어요';

  @override
  String get familyFeedCommentsComingSoon => '댓글 기능은 곧 추가돼요';

  @override
  String get familyFeedPublishButton => '게시';

  @override
  String get publishMomentTitle => '새 게시글';

  @override
  String get publishMomentContentLabel => '무슨 일이 있나요?';

  @override
  String get publishMomentContentHint => '사진이든 마음이든, 가족과 나눠보세요.';

  @override
  String get publishMomentContentRequired => '내용을 입력하거나 사진을 첨부해 주세요';

  @override
  String get publishMomentAddMedia => '미디어 추가';

  @override
  String get publishMomentMediaTypeImage => '사진';

  @override
  String get publishMomentMediaTypeVideo => '동영상';

  @override
  String get publishMomentMediaTypeAudio => '음성';

  @override
  String get publishMomentAddMediaSheet => '게시글에 추가';

  @override
  String get publishMomentMaxMedia => '최대 9개 파일';

  @override
  String get publishMomentRemoveMedia => '제거';

  @override
  String get publishMomentRecordingHint => '눌러서 녹음';

  @override
  String get publishMomentRecordingStop => '눌러서 종료';

  @override
  String get publishMomentRecordingCancel => '취소';

  @override
  String get publishMomentRecordingTooShort => '조금만 더 길게 녹음해 주세요';

  @override
  String get publishMomentRecordingFailed => '녹음에 실패했어요';

  @override
  String get publishMomentRecordingPermissionBody =>
      '음성을 추가하려면 마이크 접근 권한이 필요해요';

  @override
  String get publishMomentPublish => '게시';

  @override
  String get publishMomentPublishing => '게시 중…';

  @override
  String get publishMomentSuccess => '게시 완료';

  @override
  String get publishMomentFailed => '게시하지 못했어요. 다시 시도해 주세요';

  @override
  String publishMomentUploading(Object current, Object total) {
    return '업로드 중 $current/$total…';
  }

  @override
  String get publishMomentDiscardTitle => '이 게시글을 버릴까요?';

  @override
  String get publishMomentDiscardBody => '작성한 내용은 사라져요.';

  @override
  String get publishMomentDiscardConfirm => '버리기';

  @override
  String get publishMomentDiscardCancel => '계속 작성';

  @override
  String get momentDetailTitle => '게시글';

  @override
  String get momentDetailWhoLikedTitle => '좋아요';

  @override
  String get momentDetailNoLikes => '첫 좋아요를 남겨보세요';

  @override
  String get momentDetailPlayVideo => '동영상 재생';

  @override
  String get momentDetailVideoLoadFailed => '동영상을 불러오지 못했어요';

  @override
  String get momentDetailAudioPlay => '재생';

  @override
  String get momentDetailAudioPause => '일시정지';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '녹음 중 $seconds초 — 탭하여 중지';
  }

  @override
  String get publishMomentRecordingStopInline => '중지';

  @override
  String get publishMomentCompressing => '압축 중…';

  @override
  String publishMomentVideoTooLarge(String size) {
    return '압축 후에도 $size MB 입니다. 더 짧은 영상을 선택해 주세요.';
  }

  @override
  String publishMomentVideoTooLargeRaw(String size) {
    return '비디오를 압축하지 못했습니다 ($size MB). 더 작은 파일을 선택해 주세요.';
  }

  @override
  String get familyFeedLikeTooltipLong => '탭하여 좋아요 · 길게 눌러 취소';

  @override
  String get familyFeedLikeCancelFailed => '좋아요를 취소하지 못했습니다 — 다시 시도해 주세요';

  @override
  String get conversationsSearchHint => '메시지와 채팅 검색';

  @override
  String get conversationsSearchEmptyHint => '키워드를 입력해 저장된 메시지를 검색하세요.';

  @override
  String conversationsSearchNoResults(String query) {
    return '\"$query\"와 일치하는 결과가 없습니다.';
  }

  @override
  String get profileThemeRow => '테마';

  @override
  String get profileThemeSheetTitle => '테마 선택';
}
