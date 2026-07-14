// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '过家家 · Sweet Home';

  @override
  String get brandName => '过家家';

  @override
  String get appTagline => '家族のぬくもりを、ワンタップで';

  @override
  String get navMessages => 'メッセージ';

  @override
  String get navContacts => '連絡先';

  @override
  String get navMyHome => 'ホーム';

  @override
  String get navFamilyFeed => '家族フィード';

  @override
  String get navProfile => 'マイページ';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => '確定';

  @override
  String get commonPasswordLabel => 'パスワード';

  @override
  String get commonPasswordRequired => 'パスワードを入力してください';

  @override
  String get commonPasswordTooShort => 'パスワードは6文字以上にしてください';

  @override
  String get errorNetworkFailed => 'ネットワーク接続に失敗しました。しばらくしてから再度お試しください';

  @override
  String get loginButton => 'ログイン';

  @override
  String get loginNoAccount => 'アカウントをお持ちでないですか？';

  @override
  String get loginRegisterNow => '今すぐ登録';

  @override
  String get registerTitle => 'アカウント作成';

  @override
  String get registerNicknameLabel => 'ニックネーム';

  @override
  String get registerNicknameRequired => 'ニックネームを入力してください';

  @override
  String get registerGenderLabel => '性別';

  @override
  String get registerGenderMale => '男性';

  @override
  String get registerGenderFemale => '女性';

  @override
  String get registerGenderRequired => '性別を選択してください';

  @override
  String get registerCreateFamilyTab => '新しい家族を作る';

  @override
  String get registerJoinFamilyTab => '既存の家族に参加';

  @override
  String get registerRequestJoinTab => '招待コードを申請';

  @override
  String get registerFamilyNameLabel => '家族名（例：王さん一家）';

  @override
  String get registerFamilyNameRequired => '家族名を入力してください';

  @override
  String get registerFamilyNameHint => '* 登録後、招待コードを発行して家族を招待できます';

  @override
  String get registerInviteCodeLabel => '家族の招待コード';

  @override
  String get registerInviteCodeRequired => '招待コードを入力してください';

  @override
  String get registerInviteCodeInvalid => '招待コードの形式が正しくありません';

  @override
  String get registerInviteCodeHint => '* 招待コードは家族の管理者が発行し、48時間有効です';

  @override
  String get registerFindFamilyButton => '家族を検索';

  @override
  String get registerFindFamilyFailed => 'この招待コードに対応する家族が見つかりません';

  @override
  String get registerRelationLabel => 'その人との関係';

  @override
  String get registerRelationChild => 'その人の子';

  @override
  String get registerRelationParent => 'その人の親';

  @override
  String get registerRelationSpouse => 'その人の配偶者';

  @override
  String get registerRelationSibling => 'その人の兄弟姉妹';

  @override
  String get registerRelationAnchorRequired => 'どのメンバーとの関係か選択してください';

  @override
  String get registerSubmitCreate => '登録して家族を作る';

  @override
  String get registerSubmitJoin => '登録して家族に参加';

  @override
  String get requestJoinTargetPhoneLabel => '知っている家族メンバーの電話番号';

  @override
  String get requestJoinTargetPhoneRequired => '相手の電話番号を入力してください';

  @override
  String get requestJoinTargetPhoneHint =>
      '* 招待コードは不要です。すでにその家族に属している人の電話番号を入力するだけで、その家族の管理者が申請を審査します';

  @override
  String get requestJoinMessageLabel => '管理者へのメッセージ（任意）';

  @override
  String get requestJoinSubmit => '申請を送信';

  @override
  String get requestJoinSubmittedTitle => '申請を送信しました';

  @override
  String get requestJoinSubmittedMessage =>
      '申請は家族の管理者に送信され、審査中です。承認されたら、先ほど入力した電話番号とパスワードでログインしてください';

  @override
  String get joinRequestsTitle => '参加申請';

  @override
  String get joinRequestsEmpty => '保留中の申請はありません';

  @override
  String joinRequestsRelationLine(String relation, String targetName) {
    return '$targetNameの$relationになりたいと申請しています';
  }

  @override
  String get relationNounChild => '子';

  @override
  String get relationNounParent => '親';

  @override
  String get relationNounSpouse => '配偶者';

  @override
  String get relationNounSibling => '兄弟姉妹';

  @override
  String get joinRequestsApprove => '承認';

  @override
  String get joinRequestsReject => '拒否';

  @override
  String get phoneLabel => '電話番号';

  @override
  String get phoneRequired => '電話番号を入力してください';

  @override
  String get phoneInvalid => '電話番号の形式が正しくありません';

  @override
  String get countryPickerTitle => '国/地域を選択';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get profileLogoutConfirmMessage => 'ログアウトしてもよろしいですか？';

  @override
  String get profileLanguageRow => '言語';

  @override
  String get profileFamilyMembersRow => '家族メンバー';

  @override
  String get myHomeTitle => 'ホーム';

  @override
  String get myHomeLocationEntry => 'リアルタイム位置情報';

  @override
  String get myHomeLocationDesc => '家族それぞれの現在地を確認';

  @override
  String get myHomeJoinRequestsEntry => '参加申請';

  @override
  String get myHomeJoinRequestsDesc => '家族への参加申請を審査';

  @override
  String myHomeJoinRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未処理 $count 件',
      one: '1 件未処理',
      zero: '未処理なし',
    );
    return '$_temp0';
  }

  @override
  String get familyFeedTitle => '家族フィード';

  @override
  String get familyFeedComingSoon => '近日公開';

  @override
  String get familyFeedComingSoonDesc => '家族の出来事を近々お届けします。';

  @override
  String get contactsTitle => '連絡先';

  @override
  String get contactsEmpty => '家族メンバーがいません';

  @override
  String get locationTitle => 'リアルタイム位置情報';

  @override
  String get locationOnline => 'オンライン';

  @override
  String get locationOffline => '位置情報なし';

  @override
  String get locationUpdatedJustNow => 'たった今更新';

  @override
  String locationUpdatedMinutesAgo(Object minutes) {
    return '$minutes分前に更新';
  }

  @override
  String locationBattery(Object percent) {
    return 'バッテリー：$percent%';
  }

  @override
  String get locationBatteryUnknown => 'バッテリー：不明';

  @override
  String locationCoordinates(Object lat, Object lng) {
    return '経度 $lng、緯度 $lat';
  }

  @override
  String get locationNoData => '位置情報がありません';

  @override
  String get locationNoDataDesc => '家族が位置共有をオンにすると、ここに表示されます。';

  @override
  String locationTotalMembers(Object total) {
    return '家族$total人';
  }

  @override
  String locationOnlineCount(Object online, Object total) {
    return '$online/$total 人が位置情報を共有中';
  }

  @override
  String get locationReportNow => '自分の位置を共有';

  @override
  String get locationShareOnTitle => '位置情報の共有がオンです';

  @override
  String get locationShareOffTitle => '位置情報の共有がオフです';

  @override
  String get locationShareOnSubtitle => '現在地は約 30 秒ごとに家族に自動送信されます。';

  @override
  String get locationShareOffSubtitle => 'オンにすると、家族があなたの現在地を確認できます。';

  @override
  String get locationShareToggleOn => '位置情報の共有をオンにする';

  @override
  String get locationShareToggleOff => '位置情報の共有をオフにする';

  @override
  String get locationShareCancelHint => '位置情報の共有はオフです — オンにすると位置が自動送信されます。';

  @override
  String get locationResolving => '住所を解析中…';

  @override
  String get locationAddressUnavailable => '住所を取得できません';

  @override
  String get locationAddressFallback => 'この言語の住所データがないため英語で表示しています。';

  @override
  String get locationFullscreen => 'フルスクリーンで地図を表示';

  @override
  String get locationExitFullscreen => 'フルスクリーンを終了';

  @override
  String get locationReportFailed => '位置情報の共有に失敗しました';

  @override
  String get locationLocating => '位置情報を取得中…';

  @override
  String get locationPermissionTitle => '位置情報の権限が必要です';

  @override
  String get locationPermissionBody =>
      '家族と位置情報を共有するには、Sweet Home の位置情報アクセスを許可してください。';

  @override
  String get locationPermissionGrant => '権限を許可';

  @override
  String get locationPermissionDenied =>
      '権限が拒否されました。システム設定で許可してから、もう一度お試しください。';

  @override
  String get locationPermissionOpenSettings => '設定を開く';

  @override
  String get locationGpsOff => 'GPSがオフです。オンにすると正確な位置を共有できます。';

  @override
  String get locationGpsTimeout =>
      '時間内にGPS位置を取得できませんでした。屋外で電波状況を確認してから再試行してください。';

  @override
  String get locationGpsUnavailable =>
      'この端末では位置情報サービスを利用できません。システム設定、モック位置情報アプリ、メーカーのプライバシー設定を確認してください。';

  @override
  String get locationRefresh => '更新';

  @override
  String get joinRequestsAdminTitle => '参加申請';

  @override
  String get joinRequestsAdminEmpty => '現在、未処理の申請はありません。';

  @override
  String get joinRequestsAdminReject => '拒否';

  @override
  String get joinRequestsAdminApprove => '承認';

  @override
  String joinRequestsAdminRelationLine(String relation, String targetName) {
    return '$targetName の$relationになりたい';
  }

  @override
  String joinRequestsAdminMessage(String message) {
    return 'メッセージ：$message';
  }

  @override
  String get joinRequestsAdminRejectDialogTitle => 'この申請を拒否しますか？';

  @override
  String get joinRequestsAdminRejectDialogReason => '理由（任意）';

  @override
  String get joinRequestsAdminRejectSubmit => '拒否';

  @override
  String get joinRequestsAdminRejectCancel => 'キャンセル';

  @override
  String get joinRequestsAdminRejectSuccess => '申請を拒否しました';

  @override
  String get joinRequestsAdminApproveSuccess => '申請を承認しました';

  @override
  String get joinRequestsAdminError => '操作に失敗しました';

  @override
  String get requestJoinModeByCode => '招待コードを持っている';

  @override
  String get requestJoinModeByPhone => '家族の電話番号を知っている';

  @override
  String get requestJoinNoFamilySubmit => '申請を送信';

  @override
  String get requestJoinByCodeHint => '招待コードがある場合はこちら。';

  @override
  String get conversationsSearchTooltip => '検索';

  @override
  String get conversationsNewTooltip => '新規会話';

  @override
  String get conversationsEmptyTitle => 'まだメッセージがありません';

  @override
  String get conversationsEmptySubtitle => '家族を招待してチャットを始めましょう';

  @override
  String get connectionErrorRetry => '再試行';

  @override
  String get newConversationTitle => '新規会話';

  @override
  String get editProfileTitle => 'プロフィール編集';

  @override
  String get editProfileNicknameLabel => 'ニックネーム';

  @override
  String get editProfileSave => '保存';

  @override
  String get editProfileChangeAvatar => 'アバターを変更';

  @override
  String get editProfileAvatarUploading => 'アップロード中…';

  @override
  String get editProfileAvatarFailed => 'アップロードに失敗しました。もう一度お試しください';

  @override
  String get inviteGenerate => '招待';

  @override
  String get inviteCodeLabel => '招待コード';

  @override
  String inviteExpiryDays(int days) {
    return '$days日後に失効';
  }

  @override
  String inviteExpiryHours(int hours) {
    return '$hours時間後に失効';
  }

  @override
  String inviteExpiryMinutes(int minutes) {
    return '$minutes分後に失効';
  }

  @override
  String get inviteExpiryLessThanMinute => 'まもなく失効';

  @override
  String get inviteExpiryExpired => '失効済み';

  @override
  String get inviteCopy => 'コピー';

  @override
  String get inviteCopied => 'クリップボードにコピーしました';

  @override
  String get joinFamilyTitle => '他の家族に参加';

  @override
  String get joinFamilyConfirmMessage => '新しい家族に参加すると、現在の家族から退出します。続けますか？';

  @override
  String chatRoomMessageCount(int count) {
    return '$count 件のメッセージ';
  }

  @override
  String get chatRoomDefaultSubtitle => '家族のチャットルーム';

  @override
  String get chatRoomMoreTooltip => 'その他';

  @override
  String get chatRoomEmptyHint => 'メッセージを送って挨拶しましょう';

  @override
  String get chatRoomInputHint => 'メッセージを入力...';

  @override
  String get chatRoomMoreOption => 'その他';

  @override
  String get familyMembersTitle => '家族メンバー';

  @override
  String get familyMembersAdminBadge => '管理者';

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String get timeYesterday => '昨日';

  @override
  String get countryChina => '中国';

  @override
  String get countryUSA => 'アメリカ';

  @override
  String get countryCanada => 'カナダ';

  @override
  String get countryFrance => 'フランス';

  @override
  String get countryUK => 'イギリス';

  @override
  String get countryGermany => 'ドイツ';

  @override
  String get countryMalaysia => 'マレーシア';

  @override
  String get countryAustralia => 'オーストラリア';

  @override
  String get countryIndonesia => 'インドネシア';

  @override
  String get countryPhilippines => 'フィリピン';

  @override
  String get countryNewZealand => 'ニュージーランド';

  @override
  String get countrySingapore => 'シンガポール';

  @override
  String get countryThailand => 'タイ';

  @override
  String get countryJapan => '日本';

  @override
  String get countryKorea => '韓国';

  @override
  String get countryVietnam => 'ベトナム';

  @override
  String get countryIndia => 'インド';

  @override
  String get countryMyanmar => 'ミャンマー';

  @override
  String get countryHongKong => '香港';

  @override
  String get countryMacau => 'マカオ';

  @override
  String get countryTaiwan => '台湾';
}
