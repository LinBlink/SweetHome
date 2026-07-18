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
  String get conversationsSearchTooltip => '検索';

  @override
  String get conversationsNewTooltip => '新規会話';

  @override
  String get conversationsEmptyTitle => 'まだメッセージがありません';

  @override
  String get conversationsEmptySubtitle => '家族を招待してチャットを始めましょう';

  @override
  String get conversationSpouseLabel => '配偶者';

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

  @override
  String get chatRoomSendImageTooltip => '画像を送信';

  @override
  String get chatRoomImageUploading => '画像アップロード中…';

  @override
  String get chatRoomImageUploadFailed => '画像を送信できませんでした';

  @override
  String get chatRoomEmojiTooltip => '絵文字ピッカーを開く';

  @override
  String get chatRoomKeyboardTooltip => 'キーボードを表示';

  @override
  String get emojiCategorySmileys => '顔文字・感情';

  @override
  String get emojiCategoryPeople => '人物・体のパーツ';

  @override
  String get emojiCategoryAnimals => '動物・自然';

  @override
  String get emojiCategoryFood => '食べ物・飲み物';

  @override
  String get emojiCategoryActivities => 'アクティビティ・スポーツ';

  @override
  String get emojiCategoryTravel => '旅行・場所';

  @override
  String get emojiCategoryObjects => '物';

  @override
  String get emojiCategorySymbols => '記号';

  @override
  String get chatMessageTypeImage => '[画像]';

  @override
  String get chatMessageTypeVoice => '[音声]';

  @override
  String get chatMessageTypeSystem => '[システム]';

  @override
  String get locationHistoryTitle => '本日の軌跡';

  @override
  String get locationHistoryEmpty => 'この日の軌跡データはありません';

  @override
  String get locationHistoryEmptyDesc => 'このメンバーは選択した日に位置情報を送信していません。';

  @override
  String get profileMe => '自分';

  @override
  String get locationHistoryPickDate => '日付を選択';

  @override
  String locationHistoryPointCount(int count) {
    return '軌跡ポイント $count 件';
  }

  @override
  String locationHistoryForMember(Object name) {
    return '$name の軌跡';
  }

  @override
  String locationHistoryForDate(Object date) {
    return '$date の軌跡';
  }

  @override
  String get locationHistoryView => '軌跡を表示';

  @override
  String locationHistoryBatteryLabel(Object percent) {
    return 'バッテリー $percent%';
  }

  @override
  String get locationHistoryPlay => '再生';

  @override
  String get locationHistoryPause => '一時停止';

  @override
  String get locationHistoryReplay => 'もう一度再生';

  @override
  String locationHistoryPointAddress(String address) {
    return '📍 $address';
  }

  @override
  String get fenceListTitle => 'ジオフェンス';

  @override
  String get fenceListEmpty => 'ジオフェンスがありません';

  @override
  String get fenceListGuardingGroup => '見守り中';

  @override
  String get fenceListGuardedGroup => '見守られている';

  @override
  String get fenceListNoGuarding => 'ジオフェンスはまだ設定されていません。';

  @override
  String get fenceListNoGuarded => 'あなたのためにジオフェンスを設定した家族はまだいません。';

  @override
  String get fenceListEmptyDesc => '家族がエリアに出入りしたときに通知されるセーフゾーンを追加できます。';

  @override
  String get fenceCreateTitle => 'ジオフェンスを追加';

  @override
  String get fenceNameLabel => 'フェンス名';

  @override
  String get fenceNameHint => '例：学校、家';

  @override
  String get fenceRangeLabel => '半径（メートル）';

  @override
  String get fenceRangeHint => '例：200';

  @override
  String get fenceInvalidRange => '半径は 0 より大きい値を入力してください';

  @override
  String get fencePickLocationTitle => 'マップで中心点を選択';

  @override
  String get fencePickLocationHint => 'マップをタップして中心点を置き、半径を設定します。';

  @override
  String get fencePickLocationSelected => '中心点を設定しました';

  @override
  String get fencePickLocationRequired => 'マップで中心点を選択してください';

  @override
  String get fenceTargetLabel => '見守るメンバー';

  @override
  String get fenceCreatedBy => '設定者';

  @override
  String fenceCreatedAt(String date) {
    return '作成日時 $date';
  }

  @override
  String fenceRadiusLabel(int meters) {
    return '半径 $meters m';
  }

  @override
  String get fenceCreateButton => '作成';

  @override
  String get fenceCreateSuccess => 'ジオフェンスを作成しました';

  @override
  String get fenceDelete => '削除';

  @override
  String get fenceDeleteConfirm => 'このジオフェンスを削除しますか？';

  @override
  String get fenceDeleteSuccess => 'ジオフェンスを削除しました';

  @override
  String get fenceNoWatchableMembers => '見守る家族メンバーがいません';

  @override
  String get fenceAlarmsTitle => 'ジオフェンス通知';

  @override
  String get fenceAlarmEmpty => '通知はありません';

  @override
  String get fenceAlarmEmptyDesc => '見守っている家族がフェンスを出入りすると、ここに通知されます。';

  @override
  String get fenceAlarmInside => 'エリアに入りました';

  @override
  String get fenceAlarmOutside => 'エリアから出ました';

  @override
  String fenceAlarmTime(String time) {
    return '通知時刻 $time';
  }

  @override
  String get myHomeFenceEntry => 'ジオフェンス';

  @override
  String get myHomeFenceDesc => '家族の安全エリアを設定し、出入り時に通知を受け取る';

  @override
  String get myHomeFenceAlarmsEntry => 'ジオフェンス通知';

  @override
  String get myHomeFenceAlarmsDesc => '家族のエリア出入り履歴を確認';

  @override
  String get myHomeFamilyTreeEntry => '家系図';

  @override
  String get myHomeFamilyTreeDesc => '家族全員を一目で確認';

  @override
  String get familyTreeTitle => '家系図';

  @override
  String get familyTreeViewerYou => '自分';

  @override
  String get familyTreeViewerLabel => '本人';

  @override
  String get familyTreeEmpty => '家族はまだいません';

  @override
  String get familyTreeEmptyDesc => '家族が参加すると、ここに親戚関係が表示されます。';

  @override
  String get familyTreeOtherFamily => 'その他の親戚';

  @override
  String familyTreeOtherFamilyDesc(Object count) {
    return '残り $count 名の家族を一覧で表示';
  }

  @override
  String get appWindowTitle => 'Sweet Home';

  @override
  String get myHomeSectionFamilyTitle => '家族';

  @override
  String get myHomeWelcomeTagline => '家族の温もりに包まれて';

  @override
  String get greetingEarlyMorning => '夜更かしですね';

  @override
  String get greetingMorning => 'おはようございます';

  @override
  String get greetingNoon => 'こんにちは';

  @override
  String get greetingAfternoon => 'こんにちは';

  @override
  String get greetingEvening => 'こんばんは';

  @override
  String get greetingLateNight => '夜更かしですね';

  @override
  String get profileSectionFamilyTitle => '家族';

  @override
  String get profileSectionSettingsTitle => '設定';

  @override
  String get profileFamilyMembersSubtitle => '家族のメンバー全員を表示';

  @override
  String get profileJoinFamilySubtitle => '招待コードで他の家族に参加';

  @override
  String get locationHubSectionTitle => 'リアルタイム位置情報';

  @override
  String get locationHubTitle => 'リアルタイム位置情報';

  @override
  String get locationHubSubtitle => '家族の現在地・軌跡・ジオフェンスと通知';

  @override
  String get locationHubLiveMapDesc => '家族それぞれの現在地を確認';

  @override
  String get locationHubHistoryDesc => 'メンバーのある日の動きを確認';

  @override
  String get locationHubFenceDesc => '安全エリアを設定し、出入り時に通知を受け取る';

  @override
  String get locationHubFenceAlarmsDesc => '家族のエリア出入り履歴を確認';

  @override
  String get familyFeedEmptyTitle => 'まだ投稿がありません';

  @override
  String get familyFeedEmptyDesc => '最初の投稿を家族にシェアしましょう。';

  @override
  String get familyFeedLoadMoreError => 'もっと読み込めませんでした';

  @override
  String get familyFeedDeleteTitle => 'この投稿を削除しますか？';

  @override
  String get familyFeedDeleteBody => '削除すると、家族の誰もが見られなくなります。';

  @override
  String get familyFeedDeleteConfirm => '削除';

  @override
  String get familyFeedDeleted => '投稿を削除しました';

  @override
  String get familyFeedLikeTooltip => 'いいね';

  @override
  String get familyFeedUnlikeTooltip => 'いいね済み';

  @override
  String familyFeedLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'いいね $count件',
      zero: '0 いいね',
    );
    return '$_temp0';
  }

  @override
  String familyFeedMoreLikers(Object count) {
    return '他 $count 名';
  }

  @override
  String momentCardCommentCount(int count) {
    return '$count件のコメント';
  }

  @override
  String momentCardLatestComment(String content) {
    return '$content';
  }

  @override
  String momentDetailLikedTimes(int count) {
    return 'いいね $count 回';
  }

  @override
  String get familyFeedNoCommentsYet => 'まだコメントはありません';

  @override
  String get familyFeedCommentsComingSoon => 'コメント機能は近日公開';

  @override
  String get familyFeedPublishButton => '投稿';

  @override
  String get publishMomentTitle => '新しい投稿';

  @override
  String get publishMomentContentLabel => 'いま何してる？';

  @override
  String get publishMomentContentHint => '写真でも気持ちでも、家族の思い出を残しましょう。';

  @override
  String get publishMomentContentRequired => '内容を入力するか、写真を追加してください';

  @override
  String get publishMomentAddMedia => 'メディアを追加';

  @override
  String get publishMomentMediaTypeImage => '写真';

  @override
  String get publishMomentMediaTypeVideo => '動画';

  @override
  String get publishMomentMediaTypeAudio => '音声';

  @override
  String get publishMomentAddMediaSheet => '投稿に追加';

  @override
  String get publishMomentMaxMedia => '最大9ファイルまで';

  @override
  String get publishMomentRemoveMedia => '削除';

  @override
  String get publishMomentRecordingHint => 'タップして録音';

  @override
  String get publishMomentRecordingStop => 'タップで停止';

  @override
  String get publishMomentRecordingCancel => 'キャンセル';

  @override
  String get publishMomentRecordingTooShort => 'もう少し長めに録音してください';

  @override
  String get publishMomentRecordingFailed => '録音を保存できませんでした';

  @override
  String get publishMomentRecordingPermissionBody =>
      '音声を追加するにはマイクへのアクセス許可が必要です';

  @override
  String get publishMomentPublish => '投稿';

  @override
  String get publishMomentPublishing => '投稿中…';

  @override
  String get publishMomentSuccess => '投稿しました';

  @override
  String get publishMomentFailed => '投稿に失敗しました。もう一度お試しください';

  @override
  String publishMomentUploading(Object current, Object total) {
    return 'アップロード中 $current/$total…';
  }

  @override
  String get publishMomentDiscardTitle => 'この投稿を破棄しますか？';

  @override
  String get publishMomentDiscardBody => '編集中の内容は失われます。';

  @override
  String get publishMomentDiscardConfirm => '破棄';

  @override
  String get publishMomentDiscardCancel => '編集を続ける';

  @override
  String get momentDetailTitle => '投稿';

  @override
  String get momentDetailWhoLikedTitle => 'いいね';

  @override
  String get momentDetailNoLikes => '最初のいいねをしよう';

  @override
  String get momentDetailPlayVideo => '動画を再生';

  @override
  String get momentDetailVideoLoadFailed => '動画を読み込めませんでした';

  @override
  String get momentDetailAudioLoadFailed => '音声を読み込めませんでした';

  @override
  String get momentDetailAudioPlay => '再生';

  @override
  String get momentDetailAudioPause => '一時停止';

  @override
  String get momentDetailLikeKing => 'いいね魔人';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '録音中 $seconds 秒 — タップで停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '圧縮しています…';

  @override
  String publishMomentVideoTooLarge(String size) {
    return '圧縮しても $size MB です。短い動画を選んでください。';
  }

  @override
  String publishMomentVideoTooLargeRaw(String size) {
    return 'ビデオを圧縮できませんでした（$size MB）。小さいファイルを選んでください。';
  }

  @override
  String get familyFeedLikeTooltipLong => 'タップでいいね · 長押しで取り消し';

  @override
  String get familyFeedLikeCancelFailed => 'いいねを取り消せませんでした — もう一度お試しください';

  @override
  String get conversationsSearchHint => 'メッセージとチャットを検索';

  @override
  String get conversationsSearchEmptyHint => 'キーワードを入力して保存済みメッセージを検索。';

  @override
  String conversationsSearchNoResults(String query) {
    return '「$query」に一致する結果はありません。';
  }

  @override
  String get profileThemeRow => 'テーマ';

  @override
  String get profileThemeSheetTitle => 'テーマを選択';

  @override
  String get profileAppearanceRow => '外観';

  @override
  String get profileAppearanceSheetTitle => '外観を選択';

  @override
  String get profileThemeModeSection => '外観';

  @override
  String get profileThemeModeSystem => 'システムに従う';

  @override
  String get profileThemeModeLight => 'ライト';

  @override
  String get profileThemeModeDark => 'ダーク';

  @override
  String get profileThemeColorSection => 'カラー';

  @override
  String get momentCommentSectionTitle => 'コメント';

  @override
  String get momentCommentEmpty => 'まだコメントはありません';

  @override
  String get momentCommentInputHint => 'コメントを入力...';

  @override
  String get momentCommentSend => '送信';

  @override
  String get momentCommentDeleteTitle => 'このコメントを削除しますか？';

  @override
  String get momentCommentDeleteBody => 'このコメントはすべての家族から削除されます。';

  @override
  String get momentCommentDeleteFailed => 'コメントを削除できませんでした';

  @override
  String get chatMessageTooLong => 'メッセージが長すぎます（最大2000文字）';

  @override
  String get profileClearLocalChatConfirmTitle => 'ローカルのチャット履歴を削除しますか？';

  @override
  String get profileClearLocalChatConfirmBody =>
      'この端末に保存されたメッセージのみ削除されます。サーバー上のデータは削除されず、チャットを開くとサーバーから再読み込みされます。';

  @override
  String get profileClearLocalChatSuccess => 'ローカルのチャット履歴を削除しました';

  @override
  String get profileStorageRow => 'ストレージとキャッシュ';

  @override
  String get profileStorageSubtitle => 'ローカルキャッシュの使用量を確認・削除';

  @override
  String get profileExportChatRow => 'チャット履歴をエクスポート';

  @override
  String get profileExportChatSubtitle => 'ローカルのメッセージをテキストファイルに保存';

  @override
  String get chatExportTitle => 'チャット履歴をエクスポート';

  @override
  String get chatExportEmpty => 'エクスポートできるローカルのチャット履歴がありません';

  @override
  String chatExportSummary(int conversations, int messages) {
    return '会話 $conversations 件、メッセージ $messages 件';
  }

  @override
  String get chatExportCopy => 'すべてコピー';

  @override
  String get chatExportCopied => 'クリップボードにコピーしました';

  @override
  String chatExportSavedTo(String path) {
    return '保存先：$path';
  }

  @override
  String get storageScreenTitle => 'ストレージとキャッシュ';

  @override
  String storageTotalLabel(String size) {
    return '合計 $size';
  }

  @override
  String get storageImageCache => '画像キャッシュ';

  @override
  String get storageVideoCache => '動画キャッシュ';

  @override
  String get storageAudioCache => '音声キャッシュ';

  @override
  String get storageChatHistory => 'チャット履歴';

  @override
  String get storageSizeUnknown => '不明';

  @override
  String get storageClear => '削除';

  @override
  String get storageClearAll => 'すべてのキャッシュを削除';

  @override
  String storageClearMediaConfirmTitle(String category) {
    return '$categoryを削除しますか？';
  }

  @override
  String get storageClearMediaConfirmBody =>
      'キャッシュファイルが削除され、次回必要になったときに再ダウンロードされます。';

  @override
  String get storageClearAllConfirmTitle => 'すべてのローカルキャッシュを削除しますか？';

  @override
  String get storageClearAllConfirmBody =>
      '画像・動画・音声キャッシュとローカルのチャット履歴が削除されます。メディアは必要に応じて再ダウンロードされ、チャット履歴はサーバーから再取得されます。';

  @override
  String get storageClearSuccess => 'キャッシュを削除しました';
}
