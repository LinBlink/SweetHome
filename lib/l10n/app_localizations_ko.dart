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
  String get chatRoomRecordVideoOption => '동영상 촬영';

  @override
  String get chatRoomGalleryVideoOption => '앨범에서 동영상 선택';

  @override
  String get chatRoomVoiceOption => '음성 메시지';

  @override
  String get chatRoomVideoUploadFailed => '동영상을 보낼 수 없습니다';

  @override
  String get chatRoomVoiceUploadFailed => '음성 메시지를 보낼 수 없습니다';

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
  String get chatMessageTypeVideo => '[동영상]';

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
  String momentCardCommentCount(int count) {
    return '댓글 $count개';
  }

  @override
  String momentCardLatestComment(String content) {
    return '$content';
  }

  @override
  String momentDetailLikedTimes(int count) {
    return '좋아요 $count번';
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
  String get publishMomentReorderHint => '길게 눌러서 드래그하면 순서를 바꿀 수 있어요';

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
  String get publishMomentDraftSaveAction => '임시저장';

  @override
  String get publishMomentDraftRestored => '임시 저장된 글을 불러왔어요';

  @override
  String get publishMomentDraftClear => '임시저장 삭제';

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
  String get momentDetailAudioLoadFailed => '음성을 불러오지 못했어요';

  @override
  String get momentDetailAudioPlay => '재생';

  @override
  String get momentDetailAudioPause => '일시정지';

  @override
  String get momentDetailLikeKing => '좋아요광';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '녹음 중 $seconds초 — 탭하여 중지';
  }

  @override
  String get publishMomentRecordingStopInline => '중지';

  @override
  String get publishMomentCompressing => '압축 중…';

  @override
  String get publishMomentMediaUploading => '미디어 업로드 중…';

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

  @override
  String get profileAppearanceRow => '화면 모드';

  @override
  String get profileAppearanceSheetTitle => '화면 모드 선택';

  @override
  String get profileThemeModeSection => '화면 모드';

  @override
  String get profileThemeModeSystem => '시스템 설정 따르기';

  @override
  String get profileThemeModeLight => '라이트';

  @override
  String get profileThemeModeDark => '다크';

  @override
  String get profileThemeColorSection => '색상';

  @override
  String get momentCommentSectionTitle => '댓글';

  @override
  String get momentCommentEmpty => '아직 댓글이 없습니다';

  @override
  String get momentCommentInputHint => '댓글을 입력하세요...';

  @override
  String get momentCommentSend => '보내기';

  @override
  String get momentCommentDeleteTitle => '이 댓글을 삭제하시겠어요?';

  @override
  String get momentCommentDeleteBody => '이 댓글은 모든 가족에게서 삭제됩니다.';

  @override
  String get momentCommentDeleteFailed => '댓글 삭제에 실패했습니다';

  @override
  String get chatMessageTooLong => '메시지가 너무 깁니다 (최대 2000자)';

  @override
  String get profileClearLocalChatConfirmTitle => '로컬 채팅 기록을 삭제할까요?';

  @override
  String get profileClearLocalChatConfirmBody =>
      '이 기기에 저장된 메시지만 삭제돼요. 서버의 기록은 삭제되지 않으며, 채팅방을 다시 열면 서버에서 다시 불러와요.';

  @override
  String get profileClearLocalChatSuccess => '로컬 채팅 기록을 삭제했어요';

  @override
  String get profileStorageRow => '저장공간 및 캐시';

  @override
  String get profileStorageSubtitle => '로컬 캐시 사용량 확인 및 삭제';

  @override
  String get profileExportChatRow => '채팅 기록 내보내기';

  @override
  String get profileExportChatSubtitle => '로컬 메시지를 텍스트 파일로 저장';

  @override
  String get chatExportTitle => '채팅 기록 내보내기';

  @override
  String get chatExportEmpty => '내보낼 로컬 채팅 기록이 없어요';

  @override
  String chatExportSummary(int conversations, int messages) {
    return '대화 $conversations개, 메시지 $messages개';
  }

  @override
  String get chatExportCopy => '전체 복사';

  @override
  String get chatExportCopied => '클립보드에 복사되었습니다';

  @override
  String chatExportSavedTo(String path) {
    return '저장 위치: $path';
  }

  @override
  String get chatExportSelectConversationsTitle => '내보낼 대화 선택';

  @override
  String get chatExportSelectAll => '전체 선택';

  @override
  String get chatExportDeselectAll => '전체 선택 해제';

  @override
  String get chatExportFormatSection => '내보내기 형식';

  @override
  String get chatExportFormatTxt => '텍스트 (이미지 제외)';

  @override
  String get chatExportFormatPdf => 'PDF (이미지 포함)';

  @override
  String get chatExportGenerateButton => '내보내기';

  @override
  String get chatExportSelectAtLeastOne => '대화를 하나 이상 선택하세요';

  @override
  String get chatExportShare => '공유';

  @override
  String get chatExportGenerating => '생성 중…';

  @override
  String chatExportGeneratingProgress(int current, int total) {
    return '$current/$total개 메시지 생성 중…';
  }

  @override
  String get chatExportDateRangeAll => '전체 기간';

  @override
  String get chatExportLongRangeTitle => '날짜 범위가 깁니다';

  @override
  String get chatExportLongRangeBody =>
      '선택한 날짜 범위가 길어서 생성 속도가 느릴 수 있습니다. 계속할까요?';

  @override
  String get chatExportImageLoadFailed => '이미지를 불러올 수 없습니다';

  @override
  String get storageScreenTitle => '저장공간 및 캐시';

  @override
  String storageTotalLabel(String size) {
    return '총 $size';
  }

  @override
  String get storageImageCache => '이미지 캐시';

  @override
  String get storageAvatarCache => '아바타 캐시';

  @override
  String get storageVideoCache => '동영상 캐시';

  @override
  String get storageAudioCache => '오디오 캐시';

  @override
  String get storageChatHistory => '채팅 기록';

  @override
  String get storageSizeUnknown => '알 수 없음';

  @override
  String get storageClear => '삭제';

  @override
  String get storageClearAll => '전체 캐시 삭제';

  @override
  String storageClearMediaConfirmTitle(String category) {
    return '$category을(를) 삭제할까요?';
  }

  @override
  String get storageClearMediaConfirmBody =>
      '캐시된 파일이 삭제되며, 다음에 필요할 때 다시 다운로드됩니다.';

  @override
  String get storageClearAllConfirmTitle => '모든 로컬 캐시를 삭제할까요?';

  @override
  String get storageClearAllConfirmBody =>
      '이미지·동영상·오디오 캐시와 로컬에 저장된 채팅 기록이 삭제됩니다. 미디어는 필요할 때 다시 다운로드되며, 채팅 기록은 서버에서 다시 불러올 수 있습니다.';

  @override
  String get storageClearSuccess => '캐시가 삭제되었습니다';

  @override
  String get myHomeSectionHealthTitle => '건강';

  @override
  String get healthTitle => '가족 건강';

  @override
  String get healthSubtitle => '가족 모두의 키, 몸무게, 혈압을 기록하세요';

  @override
  String get healthTabMyRecords => '내 기록';

  @override
  String get healthTabFamily => '가족';

  @override
  String get healthTabSettings => '설정';

  @override
  String get healthTabAll => '전체';

  @override
  String get healthRecordNew => '새 기록';

  @override
  String get healthRecordSubmit => '저장';

  @override
  String get healthRecordDate => '날짜';

  @override
  String get healthHeight => '키';

  @override
  String get healthWeight => '몸무게';

  @override
  String get healthBloodPressure => '혈압';

  @override
  String get healthHeightCm => '키 (cm)';

  @override
  String get healthWeightKg => '몸무게 (kg)';

  @override
  String get healthBloodPressureSystolic => '수축기 (mmHg)';

  @override
  String get healthBloodPressureDiastolic => '이완기 (mmHg)';

  @override
  String get healthBloodPressureBothRequired => '수축기와 이완기를 모두 입력해주세요';

  @override
  String get healthValueRequired => '값을 입력해주세요';

  @override
  String get healthValueInvalid => '올바른 숫자가 아닙니다';

  @override
  String get healthHistoryTitle => '기록';

  @override
  String get healthNoRecords => '아직 건강 기록이 없습니다';

  @override
  String get healthSelectMember => '가족 구성원 선택';

  @override
  String get healthSelectMemberHint => '위에서 가족 구성원을 선택하여 공개 건강 데이터를 확인하세요.';

  @override
  String get healthFilterByMetric => '유형별 필터';

  @override
  String get healthVisibilityTitle => '공개 설정';

  @override
  String get healthReminderTitle => '매일 알림';

  @override
  String get healthReminderEnable => '매일 알림 켜기';

  @override
  String get healthReminderTime => '알림 시간';

  @override
  String get healthReminderHint => '설정한 시간까지 건강 데이터를 기록하지 않으면 푸시 알림으로 알려드립니다.';

  @override
  String get healthChartEmpty => '데이터가 부족하여 그래프를 표시할 수 없습니다.';

  @override
  String get healthChartSinglePoint => '기록이 1건뿐입니다. 계속 기록하면 추세를 볼 수 있어요.';

  @override
  String get healthChartLatest => '최신';

  @override
  String get healthChartMin => '최소';

  @override
  String get healthChartMax => '최대';

  @override
  String get healthChartAverage => '평균';

  @override
  String get healthChartSelectMetric => '위에서 지표를 선택하면 그래프가 표시됩니다.';

  @override
  String get healthEditSave => '저장';

  @override
  String get healthEditDateConflict => '이 날짜에 이미 기록이 있습니다.';

  @override
  String get healthEditRecordNotFound => '이 기록은 더 이상 존재하지 않습니다.';

  @override
  String get healthEditNotOwner => '자신의 기록만 편집할 수 있습니다.';

  @override
  String get healthEditFailed => '기록을 업데이트할 수 없습니다.';

  @override
  String get healthRecordEditHint => '탭하여 편집';

  @override
  String get healthChartBpZoneLow => '낮음';

  @override
  String get healthChartBpZoneNormal => '정상';

  @override
  String get healthChartBpZoneElevated => '높음';

  @override
  String get healthChartBpZoneHigh => '고혈압';

  @override
  String get healthChartBpDiastolicCap => '이완기 상한 80';

  @override
  String get familyFeedScopeMyFamily => '우리 가족';

  @override
  String get familyFeedScopeOthers => '다른 가족';

  @override
  String get publishMomentPublicToggle => '전체 공개';

  @override
  String get publishMomentPublicHint => '공개한 게시글은 다른 가족의 피드에도 표시됩니다';

  @override
  String get publicMomentsTitle => '다른 가족의 게시글';

  @override
  String publicMomentsFromFamily(String familyName) {
    return '$familyName에서';
  }

  @override
  String get publicMomentsEmptyTitle => '아직 공개 게시글이 없어요';

  @override
  String get publicMomentsEmptyDesc => '첫 번째로 공유해 보세요!';

  @override
  String get publicMomentsLoadMoreError => '더 불러오지 못했어요';

  @override
  String get profileBalanceLabel => '잔액';

  @override
  String balanceValue(String amount) {
    return '¥$amount';
  }

  @override
  String get editProfileBalanceHint => '충전은 가족 관리자에게 문의하세요';

  @override
  String get redpacketHubTitle => '내 홍바오';

  @override
  String get redpacketHubSubtitle => '보내거나 받은 홍바오를 확인하세요';

  @override
  String get redpacketSendTitle => '홍바오 보내기';

  @override
  String get redpacketTotalAmountLabel => '총 금액';

  @override
  String get redpacketTotalAmountHint => '단위: 위안 (예: 100 또는 88.88)';

  @override
  String get redpacketTotalCountLabel => '홍바오 개수';

  @override
  String redpacketTotalCountHint(int max) {
    return '최대 $max개';
  }

  @override
  String get redpacketSendButton => '홍바오에 넣기';

  @override
  String redpacketAmountYuan(String amount) {
    return '$amount 위안';
  }

  @override
  String redpacketShareCountSuffix(int count) {
    return '$count개';
  }

  @override
  String redpacketCountUnit(int count) {
    return '홍바오 $count개';
  }

  @override
  String get redpacketCardLabel => '홍바오';

  @override
  String redpacketCardFromLabel(String name) {
    return '$name님이 홍바오를 보냈습니다';
  }

  @override
  String get redpacketStatusOngoing => '진행 중';

  @override
  String get redpacketStatusFinished => '모두 받음';

  @override
  String get redpacketStatusExpired => '만료됨';

  @override
  String get redpacketStatusRefunded => '환불됨';

  @override
  String get redpacketGrabButton => '받기';

  @override
  String redpacketGrabSuccess(String amount) {
    return '¥$amount을(를) 받았습니다';
  }

  @override
  String get redpacketAlreadyGrabbed => '이미 받은 홍바오입니다';

  @override
  String get redpacketGrabListTitle => '받은 사람';

  @override
  String get redpacketGrabListEmpty => '아직 아무도 받지 않았습니다';

  @override
  String redpacketGrabListCount(int grabbed, int total) {
    return '$grabbed/$total 받음';
  }

  @override
  String get redpacketExpiredNotice => '이 홍바오는 만료되었습니다';

  @override
  String get redpacketEmptyNotice => '이 홍바오는 비어 있습니다';

  @override
  String get redpacketSelfNotice => '내가 보낸 홍바오입니다';

  @override
  String get redpacketRecordsTitle => '내 홍바오';

  @override
  String get redpacketRecordsTabSent => '보낸 것';

  @override
  String get redpacketRecordsTabReceived => '받은 것';

  @override
  String get redpacketRecordsEmpty => '홍바오 기록이 없습니다';

  @override
  String get redpacketErrorInvalidAmount => '총 금액은 홍바오 개수 이상이어야 합니다 (각 1분 이상).';

  @override
  String get redpacketErrorInsufficientFund => '잔액이 부족하여 홍바오를 보낼 수 없습니다.';

  @override
  String get redpacketErrorTooManyShares => '홍바오 개수는 대화 멤버 수를 초과할 수 없습니다.';

  @override
  String get redpacketErrorNotMember => '이 대화의 멤버가 아닙니다.';

  @override
  String get redpacketErrorExpired => '이 홍바오는 만료되었습니다.';

  @override
  String get redpacketErrorAlreadyGrabbed => '이미 받은 홍바오입니다.';

  @override
  String get redpacketErrorEmpty => '이 홍바오는 비어 있습니다.';

  @override
  String get redpacketErrorNotFound => '홍바오를 찾을 수 없습니다.';

  @override
  String get redpacketMessageSendFailed =>
      '홍바오는 생성되었지만 알림 메시지 전송에 실패했습니다. 온라인 상태가 되면 채팅방을 다시 열어보세요.';

  @override
  String get chatRoomRedpacketOption => '홍바오';

  @override
  String get chatMessageTypeRedpacket => '[홍바오]';

  @override
  String get errorParamInvalid => '요청 파라미터가 올바르지 않습니다.';

  @override
  String get errorUnauthorized => '로그인되어 있지 않거나 세션이 만료되었습니다. 다시 로그인해 주세요.';

  @override
  String get errorForbidden => '이 작업을 수행할 권한이 없습니다.';

  @override
  String get errorResourceNotFound => '요청한 리소스가 존재하지 않습니다.';

  @override
  String get errorDataConflict => '데이터 충돌이 발생했습니다. 새로고침 후 다시 시도해 주세요.';

  @override
  String get errorSystemBusy => '시스템이 혼잡합니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorEmptyFile => '업로드한 파일이 비어 있습니다.';

  @override
  String get errorFileSizeIllegal => '파일 크기가 요구 사항을 충족하지 않습니다.';

  @override
  String get errorFileTypeIllegal => '이 파일 형식은 지원되지 않습니다.';

  @override
  String get errorFileNameIllegal => '파일 이름이 유효하지 않습니다.';

  @override
  String get errorFileUploadFailed => '파일 업로드에 실패했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorPhoneFormatInvalid => '전화번호 형식이 올바르지 않습니다. 확인해 주세요.';

  @override
  String get errorPasswordFormatInvalid =>
      '비밀번호 형식이 요구 사항을 충족하지 않습니다. 확인해 주세요.';

  @override
  String get errorNameFormatInvalid => '닉네임이 요구 사항을 충족하지 않습니다. 확인해 주세요.';

  @override
  String get errorRegisterParamConflict => '가족 이름과 초대 코드 중 하나만 선택해야 합니다.';

  @override
  String get errorPhoneAlreadyExists => '이 전화번호는 이미 등록되어 있습니다.';

  @override
  String get errorLoginFailed => '전화번호 또는 비밀번호가 올바르지 않습니다.';

  @override
  String get errorTokenInvalid => '세션이 더 이상 유효하지 않습니다. 다시 로그인해 주세요.';

  @override
  String get errorTokenExpired => '세션이 만료되었습니다. 다시 로그인해 주세요.';

  @override
  String get errorRefreshTokenInvalid => '세션이 더 이상 유효하지 않습니다. 다시 로그인해 주세요.';

  @override
  String get errorUserNotFound => '이 사용자는 존재하지 않습니다.';

  @override
  String get errorFamilyNameEmpty => '가족 이름을 입력해 주세요.';

  @override
  String get errorInviteCodeEmpty => '초대 코드를 입력해 주세요.';

  @override
  String get errorRelationTypeInvalid => '가족 관계 유형이 유효하지 않습니다.';

  @override
  String get errorFamilyNotFound => '이 가족을 찾을 수 없습니다.';

  @override
  String get errorFamilyMemberNotFound => '이 가족 구성원을 찾을 수 없습니다.';

  @override
  String get errorInviteCodeInvalid => '이 초대 코드는 존재하지 않거나 만료되었습니다.';

  @override
  String get errorRelationAnchorInvalid => '선택한 관계 기준 대상이 유효하지 않습니다.';

  @override
  String get errorNotFamilyMember => '당신은 이 가족의 구성원이 아닙니다.';

  @override
  String get errorNotFamilyAdmin => '이 작업은 가족 관리자만 수행할 수 있습니다.';

  @override
  String get errorFamilySaveFailed => '가족 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorSpouseAlreadyExists => '상대방에게 이미 배우자가 있습니다.';

  @override
  String get errorNoKnownParent => '부모 관계를 알 수 없어 형제자매 관계를 설정할 수 없습니다.';

  @override
  String get errorConversationNotFound => '이 대화는 존재하지 않습니다.';

  @override
  String get errorMessageTooLong => '메시지가 너무 깁니다.';

  @override
  String get errorMessageTypeInvalid => '이 메시지 유형은 지원되지 않습니다.';

  @override
  String get errorLocationCoordinateInvalid => '위치 좌표는 비워둘 수 없습니다.';

  @override
  String get errorLocationBatteryInvalid => '배터리 값이 유효하지 않습니다.';

  @override
  String get errorLocationTimestampMissing => '위치 타임스탬프는 비워둘 수 없습니다.';

  @override
  String get errorLocationTimestampStale => '위치 데이터가 만료되었습니다. 다시 보고해 주세요.';

  @override
  String get errorLocationTargetNotFamilyMember => '대상 사용자는 같은 가족 구성원이 아닙니다.';

  @override
  String get errorFenceRangeInvalid => '펜스 반경이 유효하지 않습니다.';

  @override
  String get errorFenceNotFound => '이 펜스는 존재하지 않습니다.';

  @override
  String get errorNotFenceSetter => '이 작업은 펜스를 설정한 사람만 수행할 수 있습니다.';

  @override
  String get errorMomentContentEmpty => '게시물에는 텍스트 또는 미디어가 필요합니다.';

  @override
  String get errorMomentMediaTypeInvalid => '미디어 유형이 올바르지 않습니다.';

  @override
  String get errorLikeRecordNotFound => '아직 좋아요를 누르지 않아 취소할 수 없습니다.';

  @override
  String get errorMomentNotFound => '이 게시물은 존재하지 않습니다.';

  @override
  String get errorNotMomentOwner => '이 작업은 게시물 작성자만 수행할 수 있습니다.';

  @override
  String get errorCommentContentEmpty => '댓글은 비워둘 수 없습니다.';

  @override
  String get errorCommentNotFound => '이 댓글은 존재하지 않습니다.';

  @override
  String get errorNotCommentOwner => '이 작업은 댓글 작성자만 수행할 수 있습니다.';

  @override
  String get errorHealthMetricTypeInvalid => '건강 지표 유형이 올바르지 않습니다.';

  @override
  String get errorHealthRecordValueInvalid => '건강 기록 값이 유효하지 않습니다.';

  @override
  String get errorNotSameFamily => '대상 사용자는 같은 가족 구성원이 아닙니다.';

  @override
  String get errorRemindTimeInvalid => '알림 시간 형식이 올바르지 않습니다.';

  @override
  String get errorHealthRecordNotFound => '이 건강 기록은 존재하지 않습니다.';

  @override
  String get errorNotHealthRecordOwner => '본인의 건강 기록은 본인만 수정할 수 있습니다.';

  @override
  String get errorHealthRecordDateConflict => '이 날짜에는 이미 동일한 지표의 기록이 있습니다.';
}
