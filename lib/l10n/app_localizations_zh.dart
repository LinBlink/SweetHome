// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '过家家 · Sweet Home';

  @override
  String get brandName => '过家家';

  @override
  String get appTagline => '家庭的温暖，一触即达';

  @override
  String get navMessages => '消息';

  @override
  String get navContacts => '联系人';

  @override
  String get navMyHome => '我的家';

  @override
  String get navFamilyFeed => '家庭动态';

  @override
  String get navProfile => '我的';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonPasswordLabel => '密码';

  @override
  String get commonPasswordRequired => '请输入密码';

  @override
  String get commonPasswordTooShort => '密码至少6位';

  @override
  String get errorNetworkFailed => '网络连接失败，请稍后重试';

  @override
  String get loginButton => '登录';

  @override
  String get loginNoAccount => '还没有账号？';

  @override
  String get loginRegisterNow => '立即注册';

  @override
  String get registerTitle => '创建账号';

  @override
  String get registerNicknameLabel => '你的昵称';

  @override
  String get registerNicknameRequired => '请输入昵称';

  @override
  String get registerGenderLabel => '性别';

  @override
  String get registerGenderMale => '男';

  @override
  String get registerGenderFemale => '女';

  @override
  String get registerGenderRequired => '请选择性别';

  @override
  String get registerCreateFamilyTab => '创建新家庭';

  @override
  String get registerJoinFamilyTab => '加入已有家庭';

  @override
  String get registerFamilyNameLabel => '家庭名称（如：王家、李家）';

  @override
  String get registerFamilyNameRequired => '请输入家庭名称';

  @override
  String get registerFamilyNameHint => '* 注册后可生成邀请码，邀请家人加入';

  @override
  String get registerInviteCodeLabel => '家庭邀请码';

  @override
  String get registerInviteCodeRequired => '请输入邀请码';

  @override
  String get registerInviteCodeInvalid => '邀请码格式不正确';

  @override
  String get registerInviteCodeHint => '* 邀请码由家庭管理员生成，有效期48小时';

  @override
  String get registerFindFamilyButton => '查找家庭';

  @override
  String get registerFindFamilyFailed => '未找到该邀请码对应的家庭';

  @override
  String get registerRelationLabel => '与TA的关系';

  @override
  String get registerRelationChild => 'TA的孩子';

  @override
  String get registerRelationParent => 'TA的父母';

  @override
  String get registerRelationSpouse => 'TA的配偶';

  @override
  String get registerRelationSibling => 'TA的兄弟姐妹';

  @override
  String get registerRelationAnchorRequired => '请选择与哪位成员的关系';

  @override
  String get registerSubmitCreate => '注册并创建家庭';

  @override
  String get registerSubmitJoin => '注册并加入家庭';

  @override
  String get phoneLabel => '手机号';

  @override
  String get phoneRequired => '请输入手机号';

  @override
  String get phoneInvalid => '手机号格式不正确';

  @override
  String get countryPickerTitle => '选择国家/地区';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileLogoutConfirmMessage => '确定要退出当前账号吗？';

  @override
  String get profileLanguageRow => '语言';

  @override
  String get profileFamilyMembersRow => '家庭成员';

  @override
  String get myHomeTitle => '我的家';

  @override
  String get myHomeLocationEntry => '实时位置';

  @override
  String get myHomeLocationDesc => '查看每个家庭成员的当前位置';

  @override
  String get familyFeedTitle => '家庭动态';

  @override
  String get familyFeedComingSoon => '即将上线';

  @override
  String get familyFeedComingSoonDesc => '家庭动态与里程碑即将推出。';

  @override
  String get contactsTitle => '联系人';

  @override
  String get contactsEmpty => '暂无家庭成员';

  @override
  String get locationTitle => '实时位置';

  @override
  String get locationOnline => '在线';

  @override
  String get locationOffline => '暂无位置';

  @override
  String get locationUpdatedJustNow => '刚刚更新';

  @override
  String locationUpdatedMinutesAgo(Object minutes) {
    return '$minutes 分钟前更新';
  }

  @override
  String locationBattery(Object percent) {
    return '电量：$percent%';
  }

  @override
  String get locationBatteryUnknown => '电量：未知';

  @override
  String locationCoordinates(Object lat, Object lng) {
    return '经度 $lng，纬度 $lat';
  }

  @override
  String get locationNoData => '暂无位置数据';

  @override
  String get locationNoDataDesc => '家庭成员需要开启位置共享后，才能在此显示。';

  @override
  String locationTotalMembers(Object total) {
    return '共 $total 位成员';
  }

  @override
  String locationOnlineCount(Object online, Object total) {
    return '$online/$total 位正在共享位置';
  }

  @override
  String get locationReportNow => '分享我的位置';

  @override
  String get locationShareOnTitle => '位置共享已开启';

  @override
  String get locationShareOffTitle => '位置共享已关闭';

  @override
  String get locationShareOnSubtitle => '位置约每 30 秒自动发送给家人。';

  @override
  String get locationShareOffSubtitle => '开启后，家人即可看到你的位置。';

  @override
  String get locationShareToggleOn => '开启位置共享';

  @override
  String get locationShareToggleOff => '关闭位置共享';

  @override
  String get locationShareCancelHint => '位置共享未开启 — 打开开关后自动上报位置。';

  @override
  String get locationResolving => '正在解析地址…';

  @override
  String get locationAddressUnavailable => '无法解析地址';

  @override
  String get locationAddressFallback => '当前语言无该地址数据 — 显示英文版本。';

  @override
  String get locationFullscreen => '全屏显示地图';

  @override
  String get locationExitFullscreen => '退出全屏';

  @override
  String get locationReportFailed => '位置分享失败';

  @override
  String get locationLocating => '正在定位…';

  @override
  String get locationPermissionTitle => '需要定位权限';

  @override
  String get locationPermissionBody => '如需向家庭成员共享你的位置，请允许过家家访问你的位置。';

  @override
  String get locationPermissionGrant => '授予权限';

  @override
  String get locationPermissionDenied => '权限被拒绝。请到系统设置中开启后，再尝试分享位置。';

  @override
  String get locationPermissionOpenSettings => '打开设置';

  @override
  String get locationGpsOff => 'GPS 已关闭。开启后可分享精确位置。';

  @override
  String get locationGpsTimeout => '无法及时获取 GPS 定位。请到开阔处或检查信号后重试。';

  @override
  String get locationGpsUnavailable =>
      '设备当前无法获取位置。请检查系统设置、开发者选项的模拟位置应用，或厂商隐私设置。';

  @override
  String get locationRefresh => '刷新';

  @override
  String get conversationsSearchTooltip => '搜索';

  @override
  String get conversationsNewTooltip => '新建对话';

  @override
  String get conversationsEmptyTitle => '还没有消息';

  @override
  String get conversationsEmptySubtitle => '邀请家人加入，开始聊天吧';

  @override
  String get connectionErrorRetry => '重试';

  @override
  String get newConversationTitle => '新建对话';

  @override
  String get editProfileTitle => '编辑资料';

  @override
  String get editProfileNicknameLabel => '昵称';

  @override
  String get editProfileSave => '保存';

  @override
  String get editProfileChangeAvatar => '更换头像';

  @override
  String get editProfileAvatarUploading => '上传中…';

  @override
  String get editProfileAvatarFailed => '上传失败，请重试';

  @override
  String get inviteGenerate => '邀请';

  @override
  String get inviteCodeLabel => '邀请码';

  @override
  String inviteExpiryDays(int days) {
    return '$days天后过期';
  }

  @override
  String inviteExpiryHours(int hours) {
    return '$hours小时后过期';
  }

  @override
  String inviteExpiryMinutes(int minutes) {
    return '$minutes分钟后过期';
  }

  @override
  String get inviteExpiryLessThanMinute => '即将过期';

  @override
  String get inviteExpiryExpired => '已过期';

  @override
  String get inviteCopy => '复制';

  @override
  String get inviteCopied => '已复制到剪贴板';

  @override
  String get joinFamilyTitle => '加入其他家庭';

  @override
  String get joinFamilyConfirmMessage => '加入新家庭将退出当前所在的家庭，确定要继续吗？';

  @override
  String chatRoomMessageCount(int count) {
    return '$count 条消息';
  }

  @override
  String get chatRoomDefaultSubtitle => '家庭聊天室';

  @override
  String get chatRoomMoreTooltip => '更多';

  @override
  String get chatRoomEmptyHint => '发一条消息，打个招呼吧';

  @override
  String get chatRoomInputHint => '说点什么……';

  @override
  String get chatRoomMoreOption => '更多';

  @override
  String get familyMembersTitle => '家庭成员';

  @override
  String get familyMembersAdminBadge => '管理员';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String get timeYesterday => '昨天';

  @override
  String get countryChina => '中国';

  @override
  String get countryUSA => '美国';

  @override
  String get countryCanada => '加拿大';

  @override
  String get countryFrance => '法国';

  @override
  String get countryUK => '英国';

  @override
  String get countryGermany => '德国';

  @override
  String get countryMalaysia => '马来西亚';

  @override
  String get countryAustralia => '澳大利亚';

  @override
  String get countryIndonesia => '印度尼西亚';

  @override
  String get countryPhilippines => '菲律宾';

  @override
  String get countryNewZealand => '新西兰';

  @override
  String get countrySingapore => '新加坡';

  @override
  String get countryThailand => '泰国';

  @override
  String get countryJapan => '日本';

  @override
  String get countryKorea => '韩国';

  @override
  String get countryVietnam => '越南';

  @override
  String get countryIndia => '印度';

  @override
  String get countryMyanmar => '缅甸';

  @override
  String get countryHongKong => '中国香港';

  @override
  String get countryMacau => '中国澳门';

  @override
  String get countryTaiwan => '中国台湾';

  @override
  String get chatRoomSendImageTooltip => '发送图片';

  @override
  String get chatRoomImageUploading => '图片上传中…';

  @override
  String get chatRoomImageUploadFailed => '图片发送失败';

  @override
  String get chatRoomRecordVideoOption => '拍摄视频';

  @override
  String get chatRoomGalleryVideoOption => '从相册选择视频';

  @override
  String get chatRoomVoiceOption => '语音留言';

  @override
  String get chatRoomVideoUploadFailed => '视频发送失败';

  @override
  String get chatRoomVoiceUploadFailed => '语音发送失败';

  @override
  String get chatRoomEmojiTooltip => '打开表情';

  @override
  String get chatRoomKeyboardTooltip => '显示键盘';

  @override
  String get emojiCategorySmileys => '表情与情绪';

  @override
  String get emojiCategoryPeople => '人物与手势';

  @override
  String get emojiCategoryAnimals => '动物与自然';

  @override
  String get emojiCategoryFood => '美食与饮品';

  @override
  String get emojiCategoryActivities => '活动与运动';

  @override
  String get emojiCategoryTravel => '旅行与地点';

  @override
  String get emojiCategoryObjects => '物品';

  @override
  String get emojiCategorySymbols => '符号';

  @override
  String get chatMessageTypeImage => '[图片]';

  @override
  String get chatMessageTypeVoice => '[语音]';

  @override
  String get chatMessageTypeVideo => '[视频]';

  @override
  String get chatMessageTypeSystem => '[系统消息]';

  @override
  String get locationHistoryTitle => '今日轨迹';

  @override
  String get locationHistoryEmpty => '当天暂无轨迹记录';

  @override
  String get locationHistoryEmptyDesc => '该成员当天未上报过位置。';

  @override
  String get profileMe => '我';

  @override
  String get locationHistoryPickDate => '选择日期';

  @override
  String locationHistoryPointCount(int count) {
    return '共 $count 个轨迹点';
  }

  @override
  String locationHistoryForMember(Object name) {
    return '$name 的轨迹';
  }

  @override
  String locationHistoryForDate(Object date) {
    return '$date 轨迹';
  }

  @override
  String get locationHistoryView => '查看轨迹';

  @override
  String locationHistoryBatteryLabel(Object percent) {
    return '电量 $percent%';
  }

  @override
  String get locationHistoryPlay => '播放';

  @override
  String get locationHistoryPause => '暂停';

  @override
  String get locationHistoryReplay => '重新播放';

  @override
  String locationHistoryPointAddress(String address) {
    return '📍 $address';
  }

  @override
  String get fenceListTitle => '电子围栏';

  @override
  String get fenceListEmpty => '暂无围栏';

  @override
  String get fenceListGuardingGroup => '我监护谁';

  @override
  String get fenceListGuardedGroup => '被谁监护';

  @override
  String get fenceListNoGuarding => '你还没有设置过围栏';

  @override
  String get fenceListNoGuarded => '还没有家人为你设置围栏';

  @override
  String get fenceListEmptyDesc => '为家人设置安全活动范围，进入或离开时收到提醒。';

  @override
  String get fenceCreateTitle => '新建围栏';

  @override
  String get fenceNameLabel => '围栏名称';

  @override
  String get fenceNameHint => '例如：学校、家附近';

  @override
  String get fenceRangeLabel => '围栏半径（米）';

  @override
  String get fenceRangeHint => '例如：200';

  @override
  String get fenceInvalidRange => '半径必须大于 0';

  @override
  String get fencePickLocationTitle => '在地图上选择围栏中心点';

  @override
  String get fencePickLocationHint => '点击地图选择位置，再设置半径。';

  @override
  String get fencePickLocationSelected => '已选择中心点';

  @override
  String get fencePickLocationRequired => '请在地图上选择中心点';

  @override
  String get fenceTargetLabel => '被监护人';

  @override
  String get fenceCreatedBy => '设置者';

  @override
  String fenceCreatedAt(String date) {
    return '创建于 $date';
  }

  @override
  String fenceRadiusLabel(int meters) {
    return '半径 $meters 米';
  }

  @override
  String get fenceCreateButton => '创建';

  @override
  String get fenceCreateSuccess => '围栏已创建';

  @override
  String get fenceDelete => '删除';

  @override
  String get fenceDeleteConfirm => '确定要删除此围栏吗？';

  @override
  String get fenceDeleteSuccess => '围栏已删除';

  @override
  String get fenceNoWatchableMembers => '暂无可被监护的家庭成员';

  @override
  String get fenceAlarmsTitle => '围栏报警';

  @override
  String get fenceAlarmEmpty => '暂无报警';

  @override
  String get fenceAlarmEmptyDesc => '被你监护的家人离开围栏时，会在此提醒你。';

  @override
  String get fenceAlarmInside => '进入';

  @override
  String get fenceAlarmOutside => '离开';

  @override
  String fenceAlarmTime(String time) {
    return '触发时间 $time';
  }

  @override
  String get myHomeFenceEntry => '电子围栏';

  @override
  String get myHomeFenceDesc => '为家人设置安全活动范围';

  @override
  String get myHomeFenceAlarmsEntry => '围栏报警';

  @override
  String get myHomeFenceAlarmsDesc => '查看家人进出围栏的提醒';

  @override
  String get myHomeFamilyTreeEntry => '族谱';

  @override
  String get myHomeFamilyTreeDesc => '一张图看清整个家族';

  @override
  String get familyTreeTitle => '族谱';

  @override
  String get familyTreeViewerYou => '你';

  @override
  String get familyTreeViewerLabel => '本人';

  @override
  String get familyTreeEmpty => '还没有家人';

  @override
  String get familyTreeEmptyDesc => '家人加入后，他们的关系会显示在这里。';

  @override
  String get familyTreeOtherFamily => '其他亲属';

  @override
  String familyTreeOtherFamilyDesc(Object count) {
    return '另有 $count 位家人以列表展示';
  }

  @override
  String get appWindowTitle => '过家家';

  @override
  String get myHomeSectionFamilyTitle => '家';

  @override
  String get myHomeWelcomeTagline => '家人闲坐,灯火可亲';

  @override
  String get greetingEarlyMorning => '夜深了';

  @override
  String get greetingMorning => '早安';

  @override
  String get greetingNoon => '中午好';

  @override
  String get greetingAfternoon => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get greetingLateNight => '夜深了';

  @override
  String get profileSectionFamilyTitle => '家 庭';

  @override
  String get profileSectionSettingsTitle => '设 置';

  @override
  String get profileFamilyMembersSubtitle => '查看所有家庭成员';

  @override
  String get profileJoinFamilySubtitle => '邀请码加入其它家庭';

  @override
  String get locationHubSectionTitle => '实时位置';

  @override
  String get locationHubTitle => '实时位置';

  @override
  String get locationHubSubtitle => '查看家人实时位置、活动轨迹、围栏与报警';

  @override
  String get locationHubLiveMapDesc => '查看每个家庭成员的当前位置';

  @override
  String get locationHubHistoryDesc => '查看成员某一天的活动轨迹';

  @override
  String get locationHubFenceDesc => '设置安全活动范围，进入或离开时收到提醒';

  @override
  String get locationHubFenceAlarmsDesc => '查看家人进出围栏的提醒';

  @override
  String get familyFeedEmptyTitle => '还没有动态';

  @override
  String get familyFeedEmptyDesc => '发一条，让家里人多一点回忆。';

  @override
  String get familyFeedLoadMoreError => '加载更多失败';

  @override
  String get familyFeedDeleteTitle => '删除这条动态？';

  @override
  String get familyFeedDeleteBody => '删除后家里所有人都看不到。';

  @override
  String get familyFeedDeleteConfirm => '删除';

  @override
  String get familyFeedDeleted => '动态已删除';

  @override
  String get familyFeedLikeTooltip => '赞';

  @override
  String get familyFeedUnlikeTooltip => '已赞';

  @override
  String familyFeedLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '被点赞 $count 次',
      zero: '还没有人点赞',
    );
    return '$_temp0';
  }

  @override
  String familyFeedMoreLikers(Object count) {
    return '还有 $count 人';
  }

  @override
  String momentCardCommentCount(int count) {
    return '$count 条评论';
  }

  @override
  String momentCardLatestComment(String content) {
    return '$content';
  }

  @override
  String momentDetailLikedTimes(int count) {
    return '点赞 $count 次';
  }

  @override
  String get familyFeedNoCommentsYet => '还没有评论';

  @override
  String get familyFeedCommentsComingSoon => '评论功能即将上线';

  @override
  String get familyFeedPublishButton => '发布';

  @override
  String get publishMomentTitle => '发动态';

  @override
  String get publishMomentContentLabel => '说点什么…';

  @override
  String get publishMomentContentHint => '一张照片，一段心情，都是家里的记忆。';

  @override
  String get publishMomentContentRequired => '写点儿内容或者加张照片再发布吧';

  @override
  String get publishMomentAddMedia => '添加';

  @override
  String get publishMomentMediaTypeImage => '照片';

  @override
  String get publishMomentMediaTypeVideo => '视频';

  @override
  String get publishMomentMediaTypeAudio => '语音';

  @override
  String get publishMomentAddMediaSheet => '添加到动态';

  @override
  String get publishMomentMaxMedia => '最多 9 个文件';

  @override
  String get publishMomentReorderHint => '长按并拖动可调整顺序';

  @override
  String get publishMomentRemoveMedia => '移除';

  @override
  String get publishMomentRecordingHint => '点击开始录音';

  @override
  String get publishMomentRecordingStop => '点击结束';

  @override
  String get publishMomentRecordingCancel => '取消';

  @override
  String get publishMomentRecordingTooShort => '再长一点点吧';

  @override
  String get publishMomentRecordingFailed => '录音失败';

  @override
  String get publishMomentRecordingPermissionBody => '需要麦克风权限才能录制语音';

  @override
  String get publishMomentPublish => '发布';

  @override
  String get publishMomentPublishing => '发布中…';

  @override
  String get publishMomentSuccess => '发布成功';

  @override
  String get publishMomentFailed => '发布失败，请重试';

  @override
  String publishMomentUploading(Object current, Object total) {
    return '正在上传 $current/$total…';
  }

  @override
  String get publishMomentDiscardTitle => '放弃这条动态？';

  @override
  String get publishMomentDiscardBody => '当前编辑将丢失。';

  @override
  String get publishMomentDiscardConfirm => '放弃';

  @override
  String get publishMomentDiscardCancel => '继续编辑';

  @override
  String get publishMomentDraftSaveAction => '存为草稿';

  @override
  String get publishMomentDraftRestored => '已恢复草稿';

  @override
  String get publishMomentDraftClear => '清除草稿';

  @override
  String get momentDetailTitle => '动态详情';

  @override
  String get momentDetailWhoLikedTitle => '点赞列表';

  @override
  String get momentDetailNoLikes => '抢个沙发吧';

  @override
  String get momentDetailPlayVideo => '播放视频';

  @override
  String get momentDetailVideoLoadFailed => '视频加载失败';

  @override
  String get momentDetailAudioLoadFailed => '语音加载失败';

  @override
  String get momentDetailAudioPlay => '播放';

  @override
  String get momentDetailAudioPause => '暂停';

  @override
  String get momentDetailLikeKing => '点赞狂人';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '录音中 $seconds 秒 — 点一下停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '正在压缩…';

  @override
  String get publishMomentMediaUploading => '媒体上传中…';

  @override
  String publishMomentVideoTooLarge(String size) {
    return '压缩后仍有 $size MB，请选择更短的视频。';
  }

  @override
  String publishMomentVideoTooLargeRaw(String size) {
    return '视频压缩失败（$size MB），请选择更小的文件。';
  }

  @override
  String get familyFeedLikeTooltipLong => '点一下赞 · 长按取消你点的赞';

  @override
  String get familyFeedLikeCancelFailed => '取消点赞失败,请重试';

  @override
  String get conversationsSearchHint => '搜索消息和聊天';

  @override
  String get conversationsSearchEmptyHint => '输入关键词搜索已保存的消息。';

  @override
  String conversationsSearchNoResults(String query) {
    return '没有找到匹配「$query」的结果。';
  }

  @override
  String get profileThemeRow => '主题';

  @override
  String get profileThemeSheetTitle => '选择主题';

  @override
  String get profileAppearanceRow => '外观模式';

  @override
  String get profileAppearanceSheetTitle => '选择外观模式';

  @override
  String get profileThemeModeSection => '外观模式';

  @override
  String get profileThemeModeSystem => '跟随系统';

  @override
  String get profileThemeModeLight => '浅色';

  @override
  String get profileThemeModeDark => '深色';

  @override
  String get profileThemeColorSection => '配色';

  @override
  String get momentCommentSectionTitle => '评论';

  @override
  String get momentCommentEmpty => '还没有评论，来抢沙发';

  @override
  String get momentCommentInputHint => '说点什么...';

  @override
  String get momentCommentSend => '发送';

  @override
  String get momentCommentDeleteTitle => '删除这条评论？';

  @override
  String get momentCommentDeleteBody => '该评论将对所有家庭成员删除。';

  @override
  String get momentCommentDeleteFailed => '删除评论失败，请重试';

  @override
  String get chatMessageTooLong => '消息过长（最多 2000 字）';

  @override
  String get profileClearLocalChatConfirmTitle => '删除本地聊天记录？';

  @override
  String get profileClearLocalChatConfirmBody =>
      '仅清除本机缓存的消息，不会删除服务器上的记录，重新打开聊天会从服务器重新加载。';

  @override
  String get profileClearLocalChatSuccess => '本地聊天记录已删除';

  @override
  String get profileStorageRow => '存储空间';

  @override
  String get profileStorageSubtitle => '查看本地缓存占用，并清理';

  @override
  String get profileExportChatRow => '导出聊天记录';

  @override
  String get profileExportChatSubtitle => '将本地聊天记录保存为文本文件';

  @override
  String get chatExportTitle => '导出聊天记录';

  @override
  String get chatExportEmpty => '暂无可导出的本地聊天记录';

  @override
  String chatExportSummary(int conversations, int messages) {
    return '共 $conversations 个对话，$messages 条消息';
  }

  @override
  String get chatExportCopy => '复制全部';

  @override
  String get chatExportCopied => '已复制到剪贴板';

  @override
  String chatExportSavedTo(String path) {
    return '已保存至：$path';
  }

  @override
  String get chatExportSelectConversationsTitle => '选择要导出的对话';

  @override
  String get chatExportSelectAll => '全选';

  @override
  String get chatExportDeselectAll => '取消全选';

  @override
  String get chatExportFormatSection => '导出格式';

  @override
  String get chatExportFormatTxt => '文本（不含图片）';

  @override
  String get chatExportFormatPdf => 'PDF（含图片）';

  @override
  String get chatExportGenerateButton => '导出';

  @override
  String get chatExportSelectAtLeastOne => '请至少选择一个对话';

  @override
  String get chatExportShare => '分享';

  @override
  String get chatExportGenerating => '正在生成…';

  @override
  String chatExportGeneratingProgress(int current, int total) {
    return '正在生成 $current/$total 条消息…';
  }

  @override
  String get chatExportDateRangeAll => '全部时间';

  @override
  String get chatExportLongRangeTitle => '日期范围较长';

  @override
  String get chatExportLongRangeBody => '选择的日期范围较长，生成速度可能会比较慢，是否继续导出？';

  @override
  String get chatExportImageLoadFailed => '图片加载失败';

  @override
  String get storageScreenTitle => '存储空间';

  @override
  String storageTotalLabel(String size) {
    return '共 $size';
  }

  @override
  String get storageImageCache => '图片缓存';

  @override
  String get storageAvatarCache => '头像缓存';

  @override
  String get storageVideoCache => '视频缓存';

  @override
  String get storageAudioCache => '音频缓存';

  @override
  String get storageChatHistory => '聊天记录';

  @override
  String get storageSizeUnknown => '未知';

  @override
  String get storageClear => '清除';

  @override
  String get storageClearAll => '清除全部缓存';

  @override
  String storageClearMediaConfirmTitle(String category) {
    return '确定要清除$category吗？';
  }

  @override
  String get storageClearMediaConfirmBody => '缓存文件将被删除，下次使用时会重新从网络下载。';

  @override
  String get storageClearAllConfirmTitle => '确定要清除全部本地缓存吗？';

  @override
  String get storageClearAllConfirmBody =>
      '这将清除图片、视频、音频缓存以及本地保存的聊天记录。媒体文件会在需要时重新下载；聊天记录可重新从服务器加载。';

  @override
  String get storageClearSuccess => '缓存已清除';

  @override
  String get myHomeSectionHealthTitle => '健康';

  @override
  String get healthTitle => '家庭健康';

  @override
  String get healthSubtitle => '记录全家人的身高、体重和血压';

  @override
  String get healthTabMyRecords => '我的记录';

  @override
  String get healthTabFamily => '家人';

  @override
  String get healthTabSettings => '设置';

  @override
  String get healthTabAll => '全部';

  @override
  String get healthRecordNew => '记录新数据';

  @override
  String get healthRecordSubmit => '保存';

  @override
  String get healthRecordDate => '日期';

  @override
  String get healthHeight => '身高';

  @override
  String get healthWeight => '体重';

  @override
  String get healthBloodPressure => '血压';

  @override
  String get healthHeightCm => '身高 (cm)';

  @override
  String get healthWeightKg => '体重 (kg)';

  @override
  String get healthBloodPressureSystolic => '收缩压 (mmHg)';

  @override
  String get healthBloodPressureDiastolic => '舒张压 (mmHg)';

  @override
  String get healthBloodPressureBothRequired => '请输入收缩压和舒张压';

  @override
  String get healthValueRequired => '请输入数值';

  @override
  String get healthValueInvalid => '数字格式不正确';

  @override
  String get healthHistoryTitle => '历史记录';

  @override
  String get healthNoRecords => '暂无健康记录';

  @override
  String get healthSelectMember => '选择家庭成员';

  @override
  String get healthSelectMemberHint => '选择家人查看他们公开的健康数据。';

  @override
  String get healthFilterByMetric => '按类型筛选';

  @override
  String get healthVisibilityTitle => '可见性';

  @override
  String get healthReminderTitle => '每日提醒';

  @override
  String get healthReminderEnable => '开启每日提醒';

  @override
  String get healthReminderTime => '提醒时间';

  @override
  String get healthReminderHint => '到设定时间若还未记录健康数据，将通过推送通知提醒你。';

  @override
  String get healthChartEmpty => '数据不足，暂无法绘制图表。';

  @override
  String get healthChartSinglePoint => '当前只有一条记录，继续记录即可看到趋势。';

  @override
  String get healthChartLatest => '最新';

  @override
  String get healthChartMin => '最低';

  @override
  String get healthChartMax => '最高';

  @override
  String get healthChartAverage => '平均';

  @override
  String get healthChartSelectMetric => '选择上方指标类型查看图表。';

  @override
  String get healthEditSave => '保存';

  @override
  String get healthEditDateConflict => '该日期已存在该指标的记录。';

  @override
  String get healthEditRecordNotFound => '这条记录已不存在。';

  @override
  String get healthEditNotOwner => '只能修改自己的记录。';

  @override
  String get healthEditFailed => '更新记录失败。';

  @override
  String get healthRecordEditHint => '点击记录以编辑';

  @override
  String get healthChartBpZoneLow => '偏低';

  @override
  String get healthChartBpZoneNormal => '正常';

  @override
  String get healthChartBpZoneElevated => '偏高';

  @override
  String get healthChartBpZoneHigh => '高';

  @override
  String get healthChartBpDiastolicCap => '舒张压上限 80';

  @override
  String get familyFeedScopeMyFamily => '自个儿家';

  @override
  String get familyFeedScopeOthers => '串串门';

  @override
  String get publishMomentPublicToggle => '公开发布';

  @override
  String get publishMomentPublicHint => '公开后这条动态及其评论会出现在跨家庭动态广场里';

  @override
  String get publicMomentsTitle => '串串门';

  @override
  String publicMomentsFromFamily(String familyName) {
    return '来自 $familyName';
  }

  @override
  String get publicMomentsEmptyTitle => '还没有人公开发布';

  @override
  String get publicMomentsEmptyDesc => '想做第一个分享的人？';

  @override
  String get publicMomentsLoadMoreError => '加载更多失败';

  @override
  String get profileBalanceLabel => '余额';

  @override
  String balanceValue(String amount) {
    return '¥$amount';
  }

  @override
  String get editProfileBalanceHint => '如需充值请联系家庭管理员';

  @override
  String get redpacketHubTitle => '我的红包';

  @override
  String get redpacketHubSubtitle => '查看我发出和收到的红包';

  @override
  String get redpacketSendTitle => '发红包';

  @override
  String get redpacketTotalAmountLabel => '总金额';

  @override
  String get redpacketTotalAmountHint => '单位：元，例如 100 或 88.88';

  @override
  String get redpacketTotalCountLabel => '红包个数';

  @override
  String redpacketTotalCountHint(int max) {
    return '最多 $max 个';
  }

  @override
  String get redpacketSendButton => '塞钱进红包';

  @override
  String redpacketAmountYuan(String amount) {
    return '$amount 元';
  }

  @override
  String redpacketShareCountSuffix(int count) {
    return '$count 份';
  }

  @override
  String redpacketCountUnit(int count) {
    return '$count 个红包';
  }

  @override
  String get redpacketCardLabel => '红包';

  @override
  String redpacketCardFromLabel(String name) {
    return '$name 发了一个红包';
  }

  @override
  String get redpacketStatusOngoing => '进行中';

  @override
  String get redpacketStatusFinished => '已领完';

  @override
  String get redpacketStatusExpired => '已过期';

  @override
  String get redpacketStatusRefunded => '已退款';

  @override
  String get redpacketGrabButton => '开';

  @override
  String redpacketGrabSuccess(String amount) {
    return '你抢到了 ¥$amount';
  }

  @override
  String get redpacketAlreadyGrabbed => '你已经抢过这个红包了';

  @override
  String get redpacketGrabListTitle => '已领取的人';

  @override
  String get redpacketGrabListEmpty => '暂无人领取';

  @override
  String redpacketGrabListCount(int grabbed, int total) {
    return '$grabbed/$total 已领取';
  }

  @override
  String get redpacketExpiredNotice => '红包已过期';

  @override
  String get redpacketEmptyNotice => '红包已被抢光了';

  @override
  String get redpacketSelfNotice => '你发出的红包';

  @override
  String get redpacketRecordsTitle => '我的红包';

  @override
  String get redpacketRecordsTabSent => '我发出的';

  @override
  String get redpacketRecordsTabReceived => '我收到的';

  @override
  String get redpacketRecordsEmpty => '暂无红包记录';

  @override
  String get redpacketErrorInvalidAmount => '总金额必须不少于红包个数（每份至少 1 分钱）。';

  @override
  String get redpacketErrorInsufficientFund => '余额不足，无法发送红包。';

  @override
  String get redpacketErrorTooManyShares => '红包个数不能超过会话成员数。';

  @override
  String get redpacketErrorNotMember => '你已不在该会话中。';

  @override
  String get redpacketErrorExpired => '红包已过期。';

  @override
  String get redpacketErrorAlreadyGrabbed => '你已经抢过这个红包。';

  @override
  String get redpacketErrorEmpty => '红包已被抢完。';

  @override
  String get redpacketErrorNotFound => '红包不存在。';

  @override
  String get redpacketMessageSendFailed => '红包已创建，但公告消息发送失败，网络恢复后重新打开会话查看。';

  @override
  String get chatRoomRedpacketOption => '红包';

  @override
  String get chatMessageTypeRedpacket => '[红包]';

  @override
  String get errorParamInvalid => '请求参数错误。';

  @override
  String get errorUnauthorized => '未登录或登录已过期，请重新登录。';

  @override
  String get errorForbidden => '没有权限执行该操作。';

  @override
  String get errorResourceNotFound => '请求的资源不存在。';

  @override
  String get errorDataConflict => '数据冲突，请刷新后重试。';

  @override
  String get errorSystemBusy => '系统繁忙，请稍后再试。';

  @override
  String get errorEmptyFile => '上传的文件为空。';

  @override
  String get errorFileSizeIllegal => '文件大小不符合要求。';

  @override
  String get errorFileTypeIllegal => '文件类型不符合要求。';

  @override
  String get errorFileNameIllegal => '文件名不符合要求。';

  @override
  String get errorFileUploadFailed => '文件上传失败，请稍后再试。';

  @override
  String get errorPhoneFormatInvalid => '手机号码格式不正确，请检查。';

  @override
  String get errorPasswordFormatInvalid => '密码格式不符合要求，请检查。';

  @override
  String get errorNameFormatInvalid => '昵称不符合要求，请检查。';

  @override
  String get errorRegisterParamConflict => '家庭名称与邀请码只能二选一。';

  @override
  String get errorPhoneAlreadyExists => '该手机号已被注册。';

  @override
  String get errorLoginFailed => '手机号或密码错误。';

  @override
  String get errorTokenInvalid => '登录已失效，请重新登录。';

  @override
  String get errorTokenExpired => '登录已过期，请重新登录。';

  @override
  String get errorRefreshTokenInvalid => '登录已失效，请重新登录。';

  @override
  String get errorUserNotFound => '用户不存在。';

  @override
  String get errorFamilyNameEmpty => '请输入家庭名称。';

  @override
  String get errorInviteCodeEmpty => '请输入邀请码。';

  @override
  String get errorRelationTypeInvalid => '无效的家庭关系类型。';

  @override
  String get errorFamilyNotFound => '找不到该家庭。';

  @override
  String get errorFamilyMemberNotFound => '找不到该家庭成员。';

  @override
  String get errorInviteCodeInvalid => '邀请码不存在或已过期。';

  @override
  String get errorRelationAnchorInvalid => '选择的关系对象无效。';

  @override
  String get errorNotFamilyMember => '你不是该家庭成员。';

  @override
  String get errorNotFamilyAdmin => '仅家庭管理员可执行该操作。';

  @override
  String get errorFamilySaveFailed => '家庭创建失败，请稍后再试。';

  @override
  String get errorSpouseAlreadyExists => '对方已经有配偶了。';

  @override
  String get errorNoKnownParent => '父母关系未知，无法建立兄弟姐妹关系。';

  @override
  String get errorConversationNotFound => '会话不存在。';

  @override
  String get errorMessageTooLong => '消息内容过长。';

  @override
  String get errorMessageTypeInvalid => '不支持的消息类型。';

  @override
  String get errorLocationCoordinateInvalid => '定位坐标不能为空。';

  @override
  String get errorLocationBatteryInvalid => '电量数值不合法。';

  @override
  String get errorLocationTimestampMissing => '定位时间戳不能为空。';

  @override
  String get errorLocationTimestampStale => '定位数据已过期，请重新上报。';

  @override
  String get errorLocationTargetNotFamilyMember => '目标用户不是同一家庭成员。';

  @override
  String get errorFenceRangeInvalid => '围栏半径不合法。';

  @override
  String get errorFenceNotFound => '围栏不存在。';

  @override
  String get errorNotFenceSetter => '仅围栏设置者可执行该操作。';

  @override
  String get errorMomentContentEmpty => '动态内容和媒体不能同时为空。';

  @override
  String get errorMomentMediaTypeInvalid => '媒体类型不正确。';

  @override
  String get errorLikeRecordNotFound => '尚未点赞，无法取消。';

  @override
  String get errorMomentNotFound => '动态不存在。';

  @override
  String get errorNotMomentOwner => '仅动态发布者本人可执行该操作。';

  @override
  String get errorCommentContentEmpty => '评论内容不能为空。';

  @override
  String get errorCommentNotFound => '评论不存在。';

  @override
  String get errorNotCommentOwner => '仅评论作者本人可执行该操作。';

  @override
  String get errorHealthMetricTypeInvalid => '健康指标类型不正确。';

  @override
  String get errorHealthRecordValueInvalid => '健康记录数值不合法。';

  @override
  String get errorNotSameFamily => '目标用户不是同一家庭成员。';

  @override
  String get errorRemindTimeInvalid => '提醒时间格式不正确。';

  @override
  String get errorHealthRecordNotFound => '健康记录不存在。';

  @override
  String get errorNotHealthRecordOwner => '仅本人可修改自己的健康记录。';

  @override
  String get errorHealthRecordDateConflict => '该日期已存在同指标的记录。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => '过家家 · Sweet Home';

  @override
  String get brandName => '过家家';

  @override
  String get appTagline => '家庭的温暖，一触即达';

  @override
  String get navMessages => '消息';

  @override
  String get navContacts => '联系人';

  @override
  String get navMyHome => '我的家';

  @override
  String get navFamilyFeed => '家庭动态';

  @override
  String get navProfile => '我的';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonPasswordLabel => '密码';

  @override
  String get commonPasswordRequired => '请输入密码';

  @override
  String get commonPasswordTooShort => '密码至少6位';

  @override
  String get errorNetworkFailed => '网络连接失败，请稍后重试';

  @override
  String get loginButton => '登录';

  @override
  String get loginNoAccount => '还没有账号？';

  @override
  String get loginRegisterNow => '立即注册';

  @override
  String get registerTitle => '创建账号';

  @override
  String get registerNicknameLabel => '你的昵称';

  @override
  String get registerNicknameRequired => '请输入昵称';

  @override
  String get registerGenderLabel => '性别';

  @override
  String get registerGenderMale => '男';

  @override
  String get registerGenderFemale => '女';

  @override
  String get registerGenderRequired => '请选择性别';

  @override
  String get registerCreateFamilyTab => '创建新家庭';

  @override
  String get registerJoinFamilyTab => '加入已有家庭';

  @override
  String get registerFamilyNameLabel => '家庭名称（如：王家、李家）';

  @override
  String get registerFamilyNameRequired => '请输入家庭名称';

  @override
  String get registerFamilyNameHint => '* 注册后可生成邀请码，邀请家人加入';

  @override
  String get registerInviteCodeLabel => '家庭邀请码';

  @override
  String get registerInviteCodeRequired => '请输入邀请码';

  @override
  String get registerInviteCodeInvalid => '邀请码格式不正确';

  @override
  String get registerInviteCodeHint => '* 邀请码由家庭管理员生成，有效期48小时';

  @override
  String get registerFindFamilyButton => '查找家庭';

  @override
  String get registerFindFamilyFailed => '未找到该邀请码对应的家庭';

  @override
  String get registerRelationLabel => '与TA的关系';

  @override
  String get registerRelationChild => 'TA的孩子';

  @override
  String get registerRelationParent => 'TA的父母';

  @override
  String get registerRelationSpouse => 'TA的配偶';

  @override
  String get registerRelationSibling => 'TA的兄弟姐妹';

  @override
  String get registerRelationAnchorRequired => '请选择与哪位成员的关系';

  @override
  String get registerSubmitCreate => '注册并创建家庭';

  @override
  String get registerSubmitJoin => '注册并加入家庭';

  @override
  String get phoneLabel => '手机号';

  @override
  String get phoneRequired => '请输入手机号';

  @override
  String get phoneInvalid => '手机号格式不正确';

  @override
  String get countryPickerTitle => '选择国家/地区';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileLogoutConfirmMessage => '确定要退出当前账号吗？';

  @override
  String get profileLanguageRow => '语言';

  @override
  String get profileFamilyMembersRow => '家庭成员';

  @override
  String get myHomeTitle => '我的家';

  @override
  String get myHomeLocationEntry => '实时位置';

  @override
  String get myHomeLocationDesc => '查看每个家庭成员的当前位置';

  @override
  String get familyFeedTitle => '家庭动态';

  @override
  String get familyFeedComingSoon => '即将上线';

  @override
  String get familyFeedComingSoonDesc => '家庭动态与里程碑即将推出。';

  @override
  String get contactsTitle => '联系人';

  @override
  String get contactsEmpty => '暂无家庭成员';

  @override
  String get locationTitle => '实时位置';

  @override
  String get locationOnline => '在线';

  @override
  String get locationOffline => '暂无位置';

  @override
  String get locationUpdatedJustNow => '刚刚更新';

  @override
  String locationUpdatedMinutesAgo(Object minutes) {
    return '$minutes 分钟前更新';
  }

  @override
  String locationBattery(Object percent) {
    return '电量：$percent%';
  }

  @override
  String get locationBatteryUnknown => '电量：未知';

  @override
  String locationCoordinates(Object lat, Object lng) {
    return '经度 $lng，纬度 $lat';
  }

  @override
  String get locationNoData => '暂无位置数据';

  @override
  String get locationNoDataDesc => '家庭成员需要开启位置共享后，才能在此显示。';

  @override
  String locationTotalMembers(Object total) {
    return '共 $total 位成员';
  }

  @override
  String locationOnlineCount(Object online, Object total) {
    return '$online/$total 位正在共享位置';
  }

  @override
  String get locationReportNow => '分享我的位置';

  @override
  String get locationShareOnTitle => '位置共享已开启';

  @override
  String get locationShareOffTitle => '位置共享已关闭';

  @override
  String get locationShareOnSubtitle => '位置约每 30 秒自动发送给家人。';

  @override
  String get locationShareOffSubtitle => '开启后，家人即可看到你的位置。';

  @override
  String get locationShareToggleOn => '开启位置共享';

  @override
  String get locationShareToggleOff => '关闭位置共享';

  @override
  String get locationShareCancelHint => '位置共享未开启 — 打开开关后自动上报位置。';

  @override
  String get locationResolving => '正在解析地址…';

  @override
  String get locationAddressUnavailable => '无法解析地址';

  @override
  String get locationAddressFallback => '当前语言无该地址数据 — 显示英文版本。';

  @override
  String get locationFullscreen => '全屏显示地图';

  @override
  String get locationExitFullscreen => '退出全屏';

  @override
  String get locationReportFailed => '位置分享失败';

  @override
  String get locationLocating => '正在定位…';

  @override
  String get locationPermissionTitle => '需要定位权限';

  @override
  String get locationPermissionBody => '如需向家庭成员共享你的位置，请允许过家家访问你的位置。';

  @override
  String get locationPermissionGrant => '授予权限';

  @override
  String get locationPermissionDenied => '权限被拒绝。请到系统设置中开启后，再尝试分享位置。';

  @override
  String get locationPermissionOpenSettings => '打开设置';

  @override
  String get locationGpsOff => 'GPS 已关闭。开启后可分享精确位置。';

  @override
  String get locationGpsTimeout => '无法及时获取 GPS 定位。请到开阔处或检查信号后重试。';

  @override
  String get locationGpsUnavailable =>
      '设备当前无法获取位置。请检查系统设置、开发者选项的模拟位置应用，或厂商隐私设置。';

  @override
  String get locationRefresh => '刷新';

  @override
  String get conversationsSearchTooltip => '搜索';

  @override
  String get conversationsNewTooltip => '新建对话';

  @override
  String get conversationsEmptyTitle => '还没有消息';

  @override
  String get conversationsEmptySubtitle => '邀请家人加入，开始聊天吧';

  @override
  String get connectionErrorRetry => '重试';

  @override
  String get newConversationTitle => '新建对话';

  @override
  String get editProfileTitle => '编辑资料';

  @override
  String get editProfileNicknameLabel => '昵称';

  @override
  String get editProfileSave => '保存';

  @override
  String get editProfileChangeAvatar => '更换头像';

  @override
  String get editProfileAvatarUploading => '上传中…';

  @override
  String get editProfileAvatarFailed => '上传失败，请重试';

  @override
  String get inviteGenerate => '邀请';

  @override
  String get inviteCodeLabel => '邀请码';

  @override
  String inviteExpiryDays(int days) {
    return '$days天后过期';
  }

  @override
  String inviteExpiryHours(int hours) {
    return '$hours小时后过期';
  }

  @override
  String inviteExpiryMinutes(int minutes) {
    return '$minutes分钟后过期';
  }

  @override
  String get inviteExpiryLessThanMinute => '即将过期';

  @override
  String get inviteExpiryExpired => '已过期';

  @override
  String get inviteCopy => '复制';

  @override
  String get inviteCopied => '已复制到剪贴板';

  @override
  String get joinFamilyTitle => '加入其他家庭';

  @override
  String get joinFamilyConfirmMessage => '加入新家庭将退出当前所在的家庭，确定要继续吗？';

  @override
  String chatRoomMessageCount(int count) {
    return '$count 条消息';
  }

  @override
  String get chatRoomDefaultSubtitle => '家庭聊天室';

  @override
  String get chatRoomMoreTooltip => '更多';

  @override
  String get chatRoomEmptyHint => '发一条消息，打个招呼吧';

  @override
  String get chatRoomInputHint => '说点什么……';

  @override
  String get chatRoomMoreOption => '更多';

  @override
  String get familyMembersTitle => '家庭成员';

  @override
  String get familyMembersAdminBadge => '管理员';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String get timeYesterday => '昨天';

  @override
  String get countryChina => '中国';

  @override
  String get countryUSA => '美国';

  @override
  String get countryCanada => '加拿大';

  @override
  String get countryFrance => '法国';

  @override
  String get countryUK => '英国';

  @override
  String get countryGermany => '德国';

  @override
  String get countryMalaysia => '马来西亚';

  @override
  String get countryAustralia => '澳大利亚';

  @override
  String get countryIndonesia => '印度尼西亚';

  @override
  String get countryPhilippines => '菲律宾';

  @override
  String get countryNewZealand => '新西兰';

  @override
  String get countrySingapore => '新加坡';

  @override
  String get countryThailand => '泰国';

  @override
  String get countryJapan => '日本';

  @override
  String get countryKorea => '韩国';

  @override
  String get countryVietnam => '越南';

  @override
  String get countryIndia => '印度';

  @override
  String get countryMyanmar => '缅甸';

  @override
  String get countryHongKong => '中国香港';

  @override
  String get countryMacau => '中国澳门';

  @override
  String get countryTaiwan => '中国台湾';

  @override
  String get chatRoomSendImageTooltip => '发送图片';

  @override
  String get chatRoomImageUploading => '图片上传中…';

  @override
  String get chatRoomImageUploadFailed => '图片发送失败';

  @override
  String get chatRoomRecordVideoOption => '拍摄视频';

  @override
  String get chatRoomGalleryVideoOption => '从相册选择视频';

  @override
  String get chatRoomVoiceOption => '语音留言';

  @override
  String get chatRoomVideoUploadFailed => '视频发送失败';

  @override
  String get chatRoomVoiceUploadFailed => '语音发送失败';

  @override
  String get chatRoomEmojiTooltip => '打开表情';

  @override
  String get chatRoomKeyboardTooltip => '显示键盘';

  @override
  String get emojiCategorySmileys => '表情与情绪';

  @override
  String get emojiCategoryPeople => '人物与手势';

  @override
  String get emojiCategoryAnimals => '动物与自然';

  @override
  String get emojiCategoryFood => '美食与饮品';

  @override
  String get emojiCategoryActivities => '活动与运动';

  @override
  String get emojiCategoryTravel => '旅行与地点';

  @override
  String get emojiCategoryObjects => '物品';

  @override
  String get emojiCategorySymbols => '符号';

  @override
  String get chatMessageTypeImage => '[图片]';

  @override
  String get chatMessageTypeVoice => '[语音]';

  @override
  String get chatMessageTypeVideo => '[视频]';

  @override
  String get chatMessageTypeSystem => '[系统消息]';

  @override
  String get locationHistoryTitle => '今日轨迹';

  @override
  String get locationHistoryEmpty => '当天暂无轨迹记录';

  @override
  String get locationHistoryEmptyDesc => '该成员当天未上报过位置。';

  @override
  String get profileMe => '我';

  @override
  String get locationHistoryPickDate => '选择日期';

  @override
  String locationHistoryPointCount(int count) {
    return '共 $count 个轨迹点';
  }

  @override
  String locationHistoryForMember(Object name) {
    return '$name 的轨迹';
  }

  @override
  String locationHistoryForDate(Object date) {
    return '$date 轨迹';
  }

  @override
  String get locationHistoryView => '查看轨迹';

  @override
  String locationHistoryBatteryLabel(Object percent) {
    return '电量 $percent%';
  }

  @override
  String get locationHistoryPlay => '播放';

  @override
  String get locationHistoryPause => '暂停';

  @override
  String get locationHistoryReplay => '重新播放';

  @override
  String locationHistoryPointAddress(String address) {
    return '📍 $address';
  }

  @override
  String get fenceListTitle => '电子围栏';

  @override
  String get fenceListEmpty => '暂无围栏';

  @override
  String get fenceListGuardingGroup => '我监护谁';

  @override
  String get fenceListGuardedGroup => '被谁监护';

  @override
  String get fenceListNoGuarding => '你还没有设置过围栏';

  @override
  String get fenceListNoGuarded => '还没有家人为你设置围栏';

  @override
  String get fenceListEmptyDesc => '为家人设置安全活动范围，进入或离开时收到提醒。';

  @override
  String get fenceCreateTitle => '新建围栏';

  @override
  String get fenceNameLabel => '围栏名称';

  @override
  String get fenceNameHint => '例如：学校、家附近';

  @override
  String get fenceRangeLabel => '围栏半径（米）';

  @override
  String get fenceRangeHint => '例如：200';

  @override
  String get fenceInvalidRange => '半径必须大于 0';

  @override
  String get fencePickLocationTitle => '在地图上选择围栏中心点';

  @override
  String get fencePickLocationHint => '点击地图选择位置，再设置半径。';

  @override
  String get fencePickLocationSelected => '已选择中心点';

  @override
  String get fencePickLocationRequired => '请在地图上选择中心点';

  @override
  String get fenceTargetLabel => '被监护人';

  @override
  String get fenceCreatedBy => '设置者';

  @override
  String fenceCreatedAt(String date) {
    return '创建于 $date';
  }

  @override
  String fenceRadiusLabel(int meters) {
    return '半径 $meters 米';
  }

  @override
  String get fenceCreateButton => '创建';

  @override
  String get fenceCreateSuccess => '围栏已创建';

  @override
  String get fenceDelete => '删除';

  @override
  String get fenceDeleteConfirm => '确定要删除此围栏吗？';

  @override
  String get fenceDeleteSuccess => '围栏已删除';

  @override
  String get fenceNoWatchableMembers => '暂无可被监护的家庭成员';

  @override
  String get fenceAlarmsTitle => '围栏报警';

  @override
  String get fenceAlarmEmpty => '暂无报警';

  @override
  String get fenceAlarmEmptyDesc => '被你监护的家人离开围栏时，会在此提醒你。';

  @override
  String get fenceAlarmInside => '进入';

  @override
  String get fenceAlarmOutside => '离开';

  @override
  String fenceAlarmTime(String time) {
    return '触发时间 $time';
  }

  @override
  String get myHomeFenceEntry => '电子围栏';

  @override
  String get myHomeFenceDesc => '为家人设置安全活动范围';

  @override
  String get myHomeFenceAlarmsEntry => '围栏报警';

  @override
  String get myHomeFenceAlarmsDesc => '查看家人进出围栏的提醒';

  @override
  String get myHomeFamilyTreeEntry => '族谱';

  @override
  String get myHomeFamilyTreeDesc => '一张图看清整个家族';

  @override
  String get familyTreeTitle => '族谱';

  @override
  String get familyTreeViewerYou => '你';

  @override
  String get familyTreeViewerLabel => '本人';

  @override
  String get familyTreeEmpty => '还没有家人';

  @override
  String get familyTreeEmptyDesc => '家人加入后，他们的关系会显示在这里。';

  @override
  String get familyTreeOtherFamily => '其他亲属';

  @override
  String familyTreeOtherFamilyDesc(Object count) {
    return '另有 $count 位家人以列表展示';
  }

  @override
  String get appWindowTitle => '过家家';

  @override
  String get myHomeSectionFamilyTitle => '家';

  @override
  String get myHomeWelcomeTagline => '家人闲坐,灯火可亲';

  @override
  String get greetingEarlyMorning => '夜深了';

  @override
  String get greetingMorning => '早安';

  @override
  String get greetingNoon => '中午好';

  @override
  String get greetingAfternoon => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get greetingLateNight => '夜深了';

  @override
  String get profileSectionFamilyTitle => '家 庭';

  @override
  String get profileSectionSettingsTitle => '设 置';

  @override
  String get profileFamilyMembersSubtitle => '查看所有家庭成员';

  @override
  String get profileJoinFamilySubtitle => '邀请码加入其它家庭';

  @override
  String get locationHubSectionTitle => '实时位置';

  @override
  String get locationHubTitle => '实时位置';

  @override
  String get locationHubSubtitle => '查看家人实时位置、活动轨迹、围栏与报警';

  @override
  String get locationHubLiveMapDesc => '查看每个家庭成员的当前位置';

  @override
  String get locationHubHistoryDesc => '查看成员某一天的活动轨迹';

  @override
  String get locationHubFenceDesc => '设置安全活动范围，进入或离开时收到提醒';

  @override
  String get locationHubFenceAlarmsDesc => '查看家人进出围栏的提醒';

  @override
  String get familyFeedEmptyTitle => '还没有动态';

  @override
  String get familyFeedEmptyDesc => '发一条，让家里人多一点回忆。';

  @override
  String get familyFeedLoadMoreError => '加载更多失败';

  @override
  String get familyFeedDeleteTitle => '删除这条动态？';

  @override
  String get familyFeedDeleteBody => '删除后家里所有人都看不到。';

  @override
  String get familyFeedDeleteConfirm => '删除';

  @override
  String get familyFeedDeleted => '动态已删除';

  @override
  String get familyFeedLikeTooltip => '赞';

  @override
  String get familyFeedUnlikeTooltip => '已赞';

  @override
  String familyFeedLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '被点赞 $count 次',
      zero: '还没有人点赞',
    );
    return '$_temp0';
  }

  @override
  String familyFeedMoreLikers(Object count) {
    return '还有 $count 人';
  }

  @override
  String momentCardCommentCount(int count) {
    return '$count 条评论';
  }

  @override
  String momentCardLatestComment(String content) {
    return '$content';
  }

  @override
  String momentDetailLikedTimes(int count) {
    return '点赞 $count 次';
  }

  @override
  String get familyFeedNoCommentsYet => '还没有评论';

  @override
  String get familyFeedCommentsComingSoon => '评论功能即将上线';

  @override
  String get familyFeedPublishButton => '发布';

  @override
  String get publishMomentTitle => '发动态';

  @override
  String get publishMomentContentLabel => '说点什么…';

  @override
  String get publishMomentContentHint => '一张照片，一段心情，都是家里的记忆。';

  @override
  String get publishMomentContentRequired => '写点儿内容或者加张照片再发布吧';

  @override
  String get publishMomentAddMedia => '添加';

  @override
  String get publishMomentMediaTypeImage => '照片';

  @override
  String get publishMomentMediaTypeVideo => '视频';

  @override
  String get publishMomentMediaTypeAudio => '语音';

  @override
  String get publishMomentAddMediaSheet => '添加到动态';

  @override
  String get publishMomentMaxMedia => '最多 9 个文件';

  @override
  String get publishMomentReorderHint => '长按并拖动可调整顺序';

  @override
  String get publishMomentRemoveMedia => '移除';

  @override
  String get publishMomentRecordingHint => '点击开始录音';

  @override
  String get publishMomentRecordingStop => '点击结束';

  @override
  String get publishMomentRecordingCancel => '取消';

  @override
  String get publishMomentRecordingTooShort => '再长一点点吧';

  @override
  String get publishMomentRecordingFailed => '录音失败';

  @override
  String get publishMomentRecordingPermissionBody => '需要麦克风权限才能录制语音';

  @override
  String get publishMomentPublish => '发布';

  @override
  String get publishMomentPublishing => '发布中…';

  @override
  String get publishMomentSuccess => '发布成功';

  @override
  String get publishMomentFailed => '发布失败，请重试';

  @override
  String publishMomentUploading(Object current, Object total) {
    return '正在上传 $current/$total…';
  }

  @override
  String get publishMomentDiscardTitle => '放弃这条动态？';

  @override
  String get publishMomentDiscardBody => '当前编辑将丢失。';

  @override
  String get publishMomentDiscardConfirm => '放弃';

  @override
  String get publishMomentDiscardCancel => '继续编辑';

  @override
  String get publishMomentDraftSaveAction => '存为草稿';

  @override
  String get publishMomentDraftRestored => '已恢复草稿';

  @override
  String get publishMomentDraftClear => '清除草稿';

  @override
  String get momentDetailTitle => '动态详情';

  @override
  String get momentDetailWhoLikedTitle => '点赞列表';

  @override
  String get momentDetailNoLikes => '抢个沙发吧';

  @override
  String get momentDetailPlayVideo => '播放视频';

  @override
  String get momentDetailVideoLoadFailed => '视频加载失败';

  @override
  String get momentDetailAudioLoadFailed => '语音加载失败';

  @override
  String get momentDetailAudioPlay => '播放';

  @override
  String get momentDetailAudioPause => '暂停';

  @override
  String get momentDetailLikeKing => '点赞狂人';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '录音中 $seconds 秒 — 点一下停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '正在压缩…';

  @override
  String get publishMomentMediaUploading => '媒体上传中…';

  @override
  String publishMomentVideoTooLarge(String size) {
    return '压缩后仍有 $size MB，请选择更短的视频。';
  }

  @override
  String publishMomentVideoTooLargeRaw(String size) {
    return '视频压缩失败（$size MB），请选择更小的文件。';
  }

  @override
  String get familyFeedLikeTooltipLong => '点一下赞 · 长按取消你点的赞';

  @override
  String get familyFeedLikeCancelFailed => '取消点赞失败,请重试';

  @override
  String get conversationsSearchHint => '搜索消息和聊天';

  @override
  String get conversationsSearchEmptyHint => '输入关键词搜索已保存的消息。';

  @override
  String conversationsSearchNoResults(String query) {
    return '没有找到匹配「$query」的结果。';
  }

  @override
  String get profileThemeRow => '主题';

  @override
  String get profileThemeSheetTitle => '选择主题';

  @override
  String get profileAppearanceRow => '外观模式';

  @override
  String get profileAppearanceSheetTitle => '选择外观模式';

  @override
  String get profileThemeModeSection => '外观模式';

  @override
  String get profileThemeModeSystem => '跟随系统';

  @override
  String get profileThemeModeLight => '浅色';

  @override
  String get profileThemeModeDark => '深色';

  @override
  String get profileThemeColorSection => '配色';

  @override
  String get momentCommentSectionTitle => '评论';

  @override
  String get momentCommentEmpty => '还没有评论，来抢沙发';

  @override
  String get momentCommentInputHint => '说点什么...';

  @override
  String get momentCommentSend => '发送';

  @override
  String get momentCommentDeleteTitle => '删除这条评论？';

  @override
  String get momentCommentDeleteBody => '该评论将对所有家庭成员删除。';

  @override
  String get momentCommentDeleteFailed => '删除评论失败，请重试';

  @override
  String get chatMessageTooLong => '消息过长（最多 2000 字）';

  @override
  String get profileClearLocalChatConfirmTitle => '删除本地聊天记录？';

  @override
  String get profileClearLocalChatConfirmBody =>
      '仅清除本机缓存的消息，不会删除服务器上的记录，重新打开聊天会从服务器重新加载。';

  @override
  String get profileClearLocalChatSuccess => '本地聊天记录已删除';

  @override
  String get profileStorageRow => '存储空间';

  @override
  String get profileStorageSubtitle => '查看本地缓存占用，并清理';

  @override
  String get profileExportChatRow => '导出聊天记录';

  @override
  String get profileExportChatSubtitle => '将本地聊天记录保存为文本文件';

  @override
  String get chatExportTitle => '导出聊天记录';

  @override
  String get chatExportEmpty => '暂无可导出的本地聊天记录';

  @override
  String chatExportSummary(int conversations, int messages) {
    return '共 $conversations 个对话，$messages 条消息';
  }

  @override
  String get chatExportCopy => '复制全部';

  @override
  String get chatExportCopied => '已复制到剪贴板';

  @override
  String chatExportSavedTo(String path) {
    return '已保存至：$path';
  }

  @override
  String get chatExportSelectConversationsTitle => '选择要导出的对话';

  @override
  String get chatExportSelectAll => '全选';

  @override
  String get chatExportDeselectAll => '取消全选';

  @override
  String get chatExportFormatSection => '导出格式';

  @override
  String get chatExportFormatTxt => '文本（不含图片）';

  @override
  String get chatExportFormatPdf => 'PDF（含图片）';

  @override
  String get chatExportGenerateButton => '导出';

  @override
  String get chatExportSelectAtLeastOne => '请至少选择一个对话';

  @override
  String get chatExportShare => '分享';

  @override
  String get chatExportGenerating => '正在生成…';

  @override
  String chatExportGeneratingProgress(int current, int total) {
    return '正在生成 $current/$total 条消息…';
  }

  @override
  String get chatExportDateRangeAll => '全部时间';

  @override
  String get chatExportLongRangeTitle => '日期范围较长';

  @override
  String get chatExportLongRangeBody => '选择的日期范围较长，生成速度可能会比较慢，是否继续导出？';

  @override
  String get chatExportImageLoadFailed => '图片加载失败';

  @override
  String get storageScreenTitle => '存储空间';

  @override
  String storageTotalLabel(String size) {
    return '共 $size';
  }

  @override
  String get storageImageCache => '图片缓存';

  @override
  String get storageAvatarCache => '头像缓存';

  @override
  String get storageVideoCache => '视频缓存';

  @override
  String get storageAudioCache => '音频缓存';

  @override
  String get storageChatHistory => '聊天记录';

  @override
  String get storageSizeUnknown => '未知';

  @override
  String get storageClear => '清除';

  @override
  String get storageClearAll => '清除全部缓存';

  @override
  String storageClearMediaConfirmTitle(String category) {
    return '确定要清除$category吗？';
  }

  @override
  String get storageClearMediaConfirmBody => '缓存文件将被删除，下次使用时会重新从网络下载。';

  @override
  String get storageClearAllConfirmTitle => '确定要清除全部本地缓存吗？';

  @override
  String get storageClearAllConfirmBody =>
      '这将清除图片、视频、音频缓存以及本地保存的聊天记录。媒体文件会在需要时重新下载；聊天记录可重新从服务器加载。';

  @override
  String get storageClearSuccess => '缓存已清除';

  @override
  String get myHomeSectionHealthTitle => '健康';

  @override
  String get healthTitle => '家庭健康';

  @override
  String get healthSubtitle => '记录全家人的身高、体重和血压';

  @override
  String get healthTabMyRecords => '我的记录';

  @override
  String get healthTabFamily => '家人';

  @override
  String get healthTabSettings => '设置';

  @override
  String get healthTabAll => '全部';

  @override
  String get healthRecordNew => '记录新数据';

  @override
  String get healthRecordSubmit => '保存';

  @override
  String get healthRecordDate => '日期';

  @override
  String get healthHeight => '身高';

  @override
  String get healthWeight => '体重';

  @override
  String get healthBloodPressure => '血压';

  @override
  String get healthHeightCm => '身高 (cm)';

  @override
  String get healthWeightKg => '体重 (kg)';

  @override
  String get healthBloodPressureSystolic => '收缩压 (mmHg)';

  @override
  String get healthBloodPressureDiastolic => '舒张压 (mmHg)';

  @override
  String get healthBloodPressureBothRequired => '请输入收缩压和舒张压';

  @override
  String get healthValueRequired => '请输入数值';

  @override
  String get healthValueInvalid => '数字格式不正确';

  @override
  String get healthHistoryTitle => '历史记录';

  @override
  String get healthNoRecords => '暂无健康记录';

  @override
  String get healthSelectMember => '选择家庭成员';

  @override
  String get healthSelectMemberHint => '选择家人查看他们公开的健康数据。';

  @override
  String get healthFilterByMetric => '按类型筛选';

  @override
  String get healthVisibilityTitle => '可见性';

  @override
  String get healthReminderTitle => '每日提醒';

  @override
  String get healthReminderEnable => '开启每日提醒';

  @override
  String get healthReminderTime => '提醒时间';

  @override
  String get healthReminderHint => '到设定时间若还未记录健康数据，将通过推送通知提醒你。';

  @override
  String get healthChartEmpty => '数据不足，暂无法绘制图表。';

  @override
  String get healthChartSinglePoint => '当前只有一条记录，继续记录即可看到趋势。';

  @override
  String get healthChartLatest => '最新';

  @override
  String get healthChartMin => '最低';

  @override
  String get healthChartMax => '最高';

  @override
  String get healthChartAverage => '平均';

  @override
  String get healthChartSelectMetric => '选择上方指标类型查看图表。';

  @override
  String get healthEditSave => '保存';

  @override
  String get healthEditDateConflict => '该日期已存在该指标的记录。';

  @override
  String get healthEditRecordNotFound => '这条记录已不存在。';

  @override
  String get healthEditNotOwner => '只能修改自己的记录。';

  @override
  String get healthEditFailed => '更新记录失败。';

  @override
  String get healthRecordEditHint => '点击记录以编辑';

  @override
  String get healthChartBpZoneLow => '偏低';

  @override
  String get healthChartBpZoneNormal => '正常';

  @override
  String get healthChartBpZoneElevated => '偏高';

  @override
  String get healthChartBpZoneHigh => '高';

  @override
  String get healthChartBpDiastolicCap => '舒张压上限 80';

  @override
  String get familyFeedScopeMyFamily => '自个儿家';

  @override
  String get familyFeedScopeOthers => '串串门';

  @override
  String get publishMomentPublicToggle => '公开发布';

  @override
  String get publishMomentPublicHint => '公开后这条动态及其评论会出现在跨家庭动态广场里';

  @override
  String get publicMomentsTitle => '串串门';

  @override
  String publicMomentsFromFamily(String familyName) {
    return '来自 $familyName';
  }

  @override
  String get publicMomentsEmptyTitle => '还没有人公开发布';

  @override
  String get publicMomentsEmptyDesc => '想做第一个分享的人？';

  @override
  String get publicMomentsLoadMoreError => '加载更多失败';

  @override
  String get profileBalanceLabel => '余额';

  @override
  String balanceValue(String amount) {
    return '¥$amount';
  }

  @override
  String get editProfileBalanceHint => '如需充值请联系家庭管理员';

  @override
  String get redpacketHubTitle => '我的红包';

  @override
  String get redpacketHubSubtitle => '查看我发出和收到的红包';

  @override
  String get redpacketSendTitle => '发红包';

  @override
  String get redpacketTotalAmountLabel => '总金额';

  @override
  String get redpacketTotalAmountHint => '单位：元，例如 100 或 88.88';

  @override
  String get redpacketTotalCountLabel => '红包个数';

  @override
  String redpacketTotalCountHint(int max) {
    return '最多 $max 个';
  }

  @override
  String get redpacketSendButton => '塞钱进红包';

  @override
  String redpacketAmountYuan(String amount) {
    return '$amount 元';
  }

  @override
  String redpacketShareCountSuffix(int count) {
    return '$count 份';
  }

  @override
  String redpacketCountUnit(int count) {
    return '$count 个红包';
  }

  @override
  String get redpacketCardLabel => '红包';

  @override
  String redpacketCardFromLabel(String name) {
    return '$name 发了一个红包';
  }

  @override
  String get redpacketStatusOngoing => '进行中';

  @override
  String get redpacketStatusFinished => '已领完';

  @override
  String get redpacketStatusExpired => '已过期';

  @override
  String get redpacketStatusRefunded => '已退款';

  @override
  String get redpacketGrabButton => '开';

  @override
  String redpacketGrabSuccess(String amount) {
    return '你抢到了 ¥$amount';
  }

  @override
  String get redpacketAlreadyGrabbed => '你已经抢过这个红包了';

  @override
  String get redpacketGrabListTitle => '已领取的人';

  @override
  String get redpacketGrabListEmpty => '暂无人领取';

  @override
  String redpacketGrabListCount(int grabbed, int total) {
    return '$grabbed/$total 已领取';
  }

  @override
  String get redpacketExpiredNotice => '红包已过期';

  @override
  String get redpacketEmptyNotice => '红包已被抢光了';

  @override
  String get redpacketSelfNotice => '你发出的红包';

  @override
  String get redpacketRecordsTitle => '我的红包';

  @override
  String get redpacketRecordsTabSent => '我发出的';

  @override
  String get redpacketRecordsTabReceived => '我收到的';

  @override
  String get redpacketRecordsEmpty => '暂无红包记录';

  @override
  String get redpacketErrorInvalidAmount => '总金额必须不少于红包个数（每份至少 1 分钱）。';

  @override
  String get redpacketErrorInsufficientFund => '余额不足，无法发送红包。';

  @override
  String get redpacketErrorTooManyShares => '红包个数不能超过会话成员数。';

  @override
  String get redpacketErrorNotMember => '你已不在该会话中。';

  @override
  String get redpacketErrorExpired => '红包已过期。';

  @override
  String get redpacketErrorAlreadyGrabbed => '你已经抢过这个红包。';

  @override
  String get redpacketErrorEmpty => '红包已被抢完。';

  @override
  String get redpacketErrorNotFound => '红包不存在。';

  @override
  String get redpacketMessageSendFailed => '红包已创建，但公告消息发送失败，网络恢复后重新打开会话查看。';

  @override
  String get chatRoomRedpacketOption => '红包';

  @override
  String get chatMessageTypeRedpacket => '[红包]';

  @override
  String get errorParamInvalid => '请求参数错误。';

  @override
  String get errorUnauthorized => '未登录或登录已过期，请重新登录。';

  @override
  String get errorForbidden => '没有权限执行该操作。';

  @override
  String get errorResourceNotFound => '请求的资源不存在。';

  @override
  String get errorDataConflict => '数据冲突，请刷新后重试。';

  @override
  String get errorSystemBusy => '系统繁忙，请稍后再试。';

  @override
  String get errorEmptyFile => '上传的文件为空。';

  @override
  String get errorFileSizeIllegal => '文件大小不符合要求。';

  @override
  String get errorFileTypeIllegal => '文件类型不符合要求。';

  @override
  String get errorFileNameIllegal => '文件名不符合要求。';

  @override
  String get errorFileUploadFailed => '文件上传失败，请稍后再试。';

  @override
  String get errorPhoneFormatInvalid => '手机号码格式不正确，请检查。';

  @override
  String get errorPasswordFormatInvalid => '密码格式不符合要求，请检查。';

  @override
  String get errorNameFormatInvalid => '昵称不符合要求，请检查。';

  @override
  String get errorRegisterParamConflict => '家庭名称与邀请码只能二选一。';

  @override
  String get errorPhoneAlreadyExists => '该手机号已被注册。';

  @override
  String get errorLoginFailed => '手机号或密码错误。';

  @override
  String get errorTokenInvalid => '登录已失效，请重新登录。';

  @override
  String get errorTokenExpired => '登录已过期，请重新登录。';

  @override
  String get errorRefreshTokenInvalid => '登录已失效，请重新登录。';

  @override
  String get errorUserNotFound => '用户不存在。';

  @override
  String get errorFamilyNameEmpty => '请输入家庭名称。';

  @override
  String get errorInviteCodeEmpty => '请输入邀请码。';

  @override
  String get errorRelationTypeInvalid => '无效的家庭关系类型。';

  @override
  String get errorFamilyNotFound => '找不到该家庭。';

  @override
  String get errorFamilyMemberNotFound => '找不到该家庭成员。';

  @override
  String get errorInviteCodeInvalid => '邀请码不存在或已过期。';

  @override
  String get errorRelationAnchorInvalid => '选择的关系对象无效。';

  @override
  String get errorNotFamilyMember => '你不是该家庭成员。';

  @override
  String get errorNotFamilyAdmin => '仅家庭管理员可执行该操作。';

  @override
  String get errorFamilySaveFailed => '家庭创建失败，请稍后再试。';

  @override
  String get errorSpouseAlreadyExists => '对方已经有配偶了。';

  @override
  String get errorNoKnownParent => '父母关系未知，无法建立兄弟姐妹关系。';

  @override
  String get errorConversationNotFound => '会话不存在。';

  @override
  String get errorMessageTooLong => '消息内容过长。';

  @override
  String get errorMessageTypeInvalid => '不支持的消息类型。';

  @override
  String get errorLocationCoordinateInvalid => '定位坐标不能为空。';

  @override
  String get errorLocationBatteryInvalid => '电量数值不合法。';

  @override
  String get errorLocationTimestampMissing => '定位时间戳不能为空。';

  @override
  String get errorLocationTimestampStale => '定位数据已过期，请重新上报。';

  @override
  String get errorLocationTargetNotFamilyMember => '目标用户不是同一家庭成员。';

  @override
  String get errorFenceRangeInvalid => '围栏半径不合法。';

  @override
  String get errorFenceNotFound => '围栏不存在。';

  @override
  String get errorNotFenceSetter => '仅围栏设置者可执行该操作。';

  @override
  String get errorMomentContentEmpty => '动态内容和媒体不能同时为空。';

  @override
  String get errorMomentMediaTypeInvalid => '媒体类型不正确。';

  @override
  String get errorLikeRecordNotFound => '尚未点赞，无法取消。';

  @override
  String get errorMomentNotFound => '动态不存在。';

  @override
  String get errorNotMomentOwner => '仅动态发布者本人可执行该操作。';

  @override
  String get errorCommentContentEmpty => '评论内容不能为空。';

  @override
  String get errorCommentNotFound => '评论不存在。';

  @override
  String get errorNotCommentOwner => '仅评论作者本人可执行该操作。';

  @override
  String get errorHealthMetricTypeInvalid => '健康指标类型不正确。';

  @override
  String get errorHealthRecordValueInvalid => '健康记录数值不合法。';

  @override
  String get errorNotSameFamily => '目标用户不是同一家庭成员。';

  @override
  String get errorRemindTimeInvalid => '提醒时间格式不正确。';

  @override
  String get errorHealthRecordNotFound => '健康记录不存在。';

  @override
  String get errorNotHealthRecordOwner => '仅本人可修改自己的健康记录。';

  @override
  String get errorHealthRecordDateConflict => '该日期已存在同指标的记录。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '過家家 · Sweet Home';

  @override
  String get brandName => '過家家';

  @override
  String get appTagline => '家庭的溫暖，一觸即達';

  @override
  String get navMessages => '消息';

  @override
  String get navContacts => '聯絡人';

  @override
  String get navMyHome => '我的家';

  @override
  String get navFamilyFeed => '家庭動態';

  @override
  String get navProfile => '我的';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '確定';

  @override
  String get commonPasswordLabel => '密碼';

  @override
  String get commonPasswordRequired => '請輸入密碼';

  @override
  String get commonPasswordTooShort => '密碼至少6位';

  @override
  String get errorNetworkFailed => '網路連線失敗，請稍後重試';

  @override
  String get loginButton => '登入';

  @override
  String get loginNoAccount => '還沒有帳號？';

  @override
  String get loginRegisterNow => '立即註冊';

  @override
  String get registerTitle => '建立帳號';

  @override
  String get registerNicknameLabel => '你的暱稱';

  @override
  String get registerNicknameRequired => '請輸入暱稱';

  @override
  String get registerGenderLabel => '性別';

  @override
  String get registerGenderMale => '男';

  @override
  String get registerGenderFemale => '女';

  @override
  String get registerGenderRequired => '請選擇性別';

  @override
  String get registerCreateFamilyTab => '建立新家庭';

  @override
  String get registerJoinFamilyTab => '加入已有家庭';

  @override
  String get registerFamilyNameLabel => '家庭名稱（如：王家、李家）';

  @override
  String get registerFamilyNameRequired => '請輸入家庭名稱';

  @override
  String get registerFamilyNameHint => '* 註冊後可產生邀請碼，邀請家人加入';

  @override
  String get registerInviteCodeLabel => '家庭邀請碼';

  @override
  String get registerInviteCodeRequired => '請輸入邀請碼';

  @override
  String get registerInviteCodeInvalid => '邀請碼格式不正確';

  @override
  String get registerInviteCodeHint => '* 邀請碼由家庭管理員產生，有效期48小時';

  @override
  String get registerFindFamilyButton => '查找家庭';

  @override
  String get registerFindFamilyFailed => '找不到該邀請碼對應的家庭';

  @override
  String get registerRelationLabel => '與TA的關係';

  @override
  String get registerRelationChild => 'TA的孩子';

  @override
  String get registerRelationParent => 'TA的父母';

  @override
  String get registerRelationSpouse => 'TA的配偶';

  @override
  String get registerRelationSibling => 'TA的兄弟姐妹';

  @override
  String get registerRelationAnchorRequired => '請選擇與哪位成員的關係';

  @override
  String get registerSubmitCreate => '註冊並建立家庭';

  @override
  String get registerSubmitJoin => '註冊並加入家庭';

  @override
  String get phoneLabel => '手機號';

  @override
  String get phoneRequired => '請輸入手機號';

  @override
  String get phoneInvalid => '手機號格式不正確';

  @override
  String get countryPickerTitle => '選擇國家/地區';

  @override
  String get profileLogout => '登出';

  @override
  String get profileLogoutConfirmMessage => '確定要登出目前帳號嗎？';

  @override
  String get profileLanguageRow => '語言';

  @override
  String get profileFamilyMembersRow => '家庭成員';

  @override
  String get myHomeTitle => '我的家';

  @override
  String get myHomeLocationEntry => '即時位置';

  @override
  String get myHomeLocationDesc => '查看每個家庭成員的當前位置';

  @override
  String get familyFeedTitle => '家庭動態';

  @override
  String get familyFeedComingSoon => '即將上線';

  @override
  String get familyFeedComingSoonDesc => '家庭動態與里程碑即將推出。';

  @override
  String get contactsTitle => '聯絡人';

  @override
  String get contactsEmpty => '暫無家庭成員';

  @override
  String get locationTitle => '即時位置';

  @override
  String get locationOnline => '在線';

  @override
  String get locationOffline => '暫無位置';

  @override
  String get locationUpdatedJustNow => '剛剛更新';

  @override
  String locationUpdatedMinutesAgo(Object minutes) {
    return '$minutes 分鐘前更新';
  }

  @override
  String locationBattery(Object percent) {
    return '電量：$percent%';
  }

  @override
  String get locationBatteryUnknown => '電量：未知';

  @override
  String locationCoordinates(Object lat, Object lng) {
    return '經度 $lng，緯度 $lat';
  }

  @override
  String get locationNoData => '暫無位置數據';

  @override
  String get locationNoDataDesc => '家庭成員需要開啟位置共享後，才能在此顯示。';

  @override
  String locationTotalMembers(Object total) {
    return '共 $total 位成員';
  }

  @override
  String locationOnlineCount(Object online, Object total) {
    return '$online/$total 位正在共享位置';
  }

  @override
  String get locationReportNow => '分享我的位置';

  @override
  String get locationShareOnTitle => '位置共享已開啟';

  @override
  String get locationShareOffTitle => '位置共享已關閉';

  @override
  String get locationShareOnSubtitle => '位置約每 30 秒自動傳送給家人。';

  @override
  String get locationShareOffSubtitle => '開啟後，家人即可看到你的位置。';

  @override
  String get locationShareToggleOn => '開啟位置共享';

  @override
  String get locationShareToggleOff => '關閉位置共享';

  @override
  String get locationShareCancelHint => '位置共享未開啟 — 打開開關後自動上報位置。';

  @override
  String get locationResolving => '正在解析地址…';

  @override
  String get locationAddressUnavailable => '無法解析地址';

  @override
  String get locationAddressFallback => '目前語言無此地址資料 — 顯示英文版本。';

  @override
  String get locationFullscreen => '全螢幕顯示地圖';

  @override
  String get locationExitFullscreen => '退出全螢幕';

  @override
  String get locationReportFailed => '位置分享失敗';

  @override
  String get locationLocating => '正在定位…';

  @override
  String get locationPermissionTitle => '需要定位權限';

  @override
  String get locationPermissionBody => '如需向家庭成員共享你的位置，請允許過家家訪問你的位置。';

  @override
  String get locationPermissionGrant => '授予權限';

  @override
  String get locationPermissionDenied => '權限被拒絕。請到系統設置中開啟後，再嘗試分享位置。';

  @override
  String get locationPermissionOpenSettings => '打開設置';

  @override
  String get locationGpsOff => 'GPS 已關閉。開啟後可分享精確位置。';

  @override
  String get locationGpsTimeout => '無法及時獲取 GPS 定位。請到開闊處或檢查信號後重試。';

  @override
  String get locationGpsUnavailable =>
      '設備當前無法獲取位置。請檢查系統設置、開發者選項的模擬位置應用，或廠商隱私設置。';

  @override
  String get locationRefresh => '刷新';

  @override
  String get conversationsSearchTooltip => '搜尋';

  @override
  String get conversationsNewTooltip => '新建對話';

  @override
  String get conversationsEmptyTitle => '還沒有訊息';

  @override
  String get conversationsEmptySubtitle => '邀請家人加入，開始聊天吧';

  @override
  String get connectionErrorRetry => '重試';

  @override
  String get newConversationTitle => '新建對話';

  @override
  String get editProfileTitle => '編輯資料';

  @override
  String get editProfileNicknameLabel => '暱稱';

  @override
  String get editProfileSave => '儲存';

  @override
  String get editProfileChangeAvatar => '更換頭像';

  @override
  String get editProfileAvatarUploading => '上傳中…';

  @override
  String get editProfileAvatarFailed => '上傳失敗，請重試';

  @override
  String get inviteGenerate => '邀請';

  @override
  String get inviteCodeLabel => '邀請碼';

  @override
  String inviteExpiryDays(int days) {
    return '$days天後過期';
  }

  @override
  String inviteExpiryHours(int hours) {
    return '$hours小時後過期';
  }

  @override
  String inviteExpiryMinutes(int minutes) {
    return '$minutes分鐘後過期';
  }

  @override
  String get inviteExpiryLessThanMinute => '即將過期';

  @override
  String get inviteExpiryExpired => '已過期';

  @override
  String get inviteCopy => '複製';

  @override
  String get inviteCopied => '已複製到剪貼簿';

  @override
  String get joinFamilyTitle => '加入其他家庭';

  @override
  String get joinFamilyConfirmMessage => '加入新家庭將退出目前所在的家庭，確定要繼續嗎？';

  @override
  String chatRoomMessageCount(int count) {
    return '$count 則訊息';
  }

  @override
  String get chatRoomDefaultSubtitle => '家庭聊天室';

  @override
  String get chatRoomMoreTooltip => '更多';

  @override
  String get chatRoomEmptyHint => '傳一則訊息，打個招呼吧';

  @override
  String get chatRoomInputHint => '說點什麼……';

  @override
  String get chatRoomMoreOption => '更多';

  @override
  String get familyMembersTitle => '家庭成員';

  @override
  String get familyMembersAdminBadge => '管理員';

  @override
  String get timeJustNow => '剛剛';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分鐘前';
  }

  @override
  String get timeYesterday => '昨天';

  @override
  String get countryChina => '中國';

  @override
  String get countryUSA => '美國';

  @override
  String get countryCanada => '加拿大';

  @override
  String get countryFrance => '法國';

  @override
  String get countryUK => '英國';

  @override
  String get countryGermany => '德國';

  @override
  String get countryMalaysia => '馬來西亞';

  @override
  String get countryAustralia => '澳大利亞';

  @override
  String get countryIndonesia => '印度尼西亞';

  @override
  String get countryPhilippines => '菲律賓';

  @override
  String get countryNewZealand => '紐西蘭';

  @override
  String get countrySingapore => '新加坡';

  @override
  String get countryThailand => '泰國';

  @override
  String get countryJapan => '日本';

  @override
  String get countryKorea => '韓國';

  @override
  String get countryVietnam => '越南';

  @override
  String get countryIndia => '印度';

  @override
  String get countryMyanmar => '緬甸';

  @override
  String get countryHongKong => '中國香港';

  @override
  String get countryMacau => '中國澳門';

  @override
  String get countryTaiwan => '台灣';

  @override
  String get chatRoomSendImageTooltip => '發送圖片';

  @override
  String get chatRoomImageUploading => '圖片上傳中…';

  @override
  String get chatRoomImageUploadFailed => '圖片發送失敗';

  @override
  String get chatRoomRecordVideoOption => '拍攝影片';

  @override
  String get chatRoomGalleryVideoOption => '從相簿選擇影片';

  @override
  String get chatRoomVoiceOption => '語音留言';

  @override
  String get chatRoomVideoUploadFailed => '影片發送失敗';

  @override
  String get chatRoomVoiceUploadFailed => '語音發送失敗';

  @override
  String get chatRoomEmojiTooltip => '打開表情';

  @override
  String get chatRoomKeyboardTooltip => '顯示鍵盤';

  @override
  String get emojiCategorySmileys => '表情與情緒';

  @override
  String get emojiCategoryPeople => '人物與手勢';

  @override
  String get emojiCategoryAnimals => '動物與自然';

  @override
  String get emojiCategoryFood => '美食與飲品';

  @override
  String get emojiCategoryActivities => '活動與運動';

  @override
  String get emojiCategoryTravel => '旅行與地點';

  @override
  String get emojiCategoryObjects => '物品';

  @override
  String get emojiCategorySymbols => '符號';

  @override
  String get chatMessageTypeImage => '[圖片]';

  @override
  String get chatMessageTypeVoice => '[語音]';

  @override
  String get chatMessageTypeVideo => '[影片]';

  @override
  String get chatMessageTypeSystem => '[系統訊息]';

  @override
  String get locationHistoryTitle => '今日軌跡';

  @override
  String get locationHistoryEmpty => '當天暫無軌跡記錄';

  @override
  String get locationHistoryEmptyDesc => '該成員當天未上報過位置。';

  @override
  String get profileMe => '我';

  @override
  String get locationHistoryPickDate => '選擇日期';

  @override
  String locationHistoryPointCount(int count) {
    return '共 $count 個軌跡點';
  }

  @override
  String locationHistoryForMember(Object name) {
    return '$name 的軌跡';
  }

  @override
  String locationHistoryForDate(Object date) {
    return '$date 軌跡';
  }

  @override
  String get locationHistoryView => '查看軌跡';

  @override
  String locationHistoryBatteryLabel(Object percent) {
    return '電量 $percent%';
  }

  @override
  String get locationHistoryPlay => '播放';

  @override
  String get locationHistoryPause => '暫停';

  @override
  String get locationHistoryReplay => '重新播放';

  @override
  String locationHistoryPointAddress(String address) {
    return '📍 $address';
  }

  @override
  String get fenceListTitle => '電子圍欄';

  @override
  String get fenceListEmpty => '暫無圍欄';

  @override
  String get fenceListGuardingGroup => '我監護誰';

  @override
  String get fenceListGuardedGroup => '被誰監護';

  @override
  String get fenceListNoGuarding => '你還沒有設定過圍欄';

  @override
  String get fenceListNoGuarded => '還沒有家人為你設定圍欄';

  @override
  String get fenceListEmptyDesc => '為家人設定安全活動範圍，進入或離開時收到提醒。';

  @override
  String get fenceCreateTitle => '新建圍欄';

  @override
  String get fenceNameLabel => '圍欄名稱';

  @override
  String get fenceNameHint => '例如：學校、家附近';

  @override
  String get fenceRangeLabel => '圍欄半徑（公尺）';

  @override
  String get fenceRangeHint => '例如：200';

  @override
  String get fenceInvalidRange => '半徑必須大於 0';

  @override
  String get fencePickLocationTitle => '在地圖上選擇圍欄中心點';

  @override
  String get fencePickLocationHint => '點擊地圖選擇位置，再設定半徑。';

  @override
  String get fencePickLocationSelected => '已選擇中心點';

  @override
  String get fencePickLocationRequired => '請在地圖上選擇中心點';

  @override
  String get fenceTargetLabel => '被監護人';

  @override
  String get fenceCreatedBy => '設定者';

  @override
  String fenceCreatedAt(String date) {
    return '建立於 $date';
  }

  @override
  String fenceRadiusLabel(int meters) {
    return '半徑 $meters 公尺';
  }

  @override
  String get fenceCreateButton => '建立';

  @override
  String get fenceCreateSuccess => '圍欄已建立';

  @override
  String get fenceDelete => '刪除';

  @override
  String get fenceDeleteConfirm => '確定要刪除此圍欄嗎？';

  @override
  String get fenceDeleteSuccess => '圍欄已刪除';

  @override
  String get fenceNoWatchableMembers => '暫無可被監護的家庭成員';

  @override
  String get fenceAlarmsTitle => '圍欄警報';

  @override
  String get fenceAlarmEmpty => '暫無警報';

  @override
  String get fenceAlarmEmptyDesc => '被你監護的家人離開圍欄時，會在此提醒你。';

  @override
  String get fenceAlarmInside => '進入';

  @override
  String get fenceAlarmOutside => '離開';

  @override
  String fenceAlarmTime(String time) {
    return '觸發時間 $time';
  }

  @override
  String get myHomeFenceEntry => '電子圍欄';

  @override
  String get myHomeFenceDesc => '為家人設定安全活動範圍';

  @override
  String get myHomeFenceAlarmsEntry => '圍欄警報';

  @override
  String get myHomeFenceAlarmsDesc => '查看家人進出圍欄的提醒';

  @override
  String get myHomeFamilyTreeEntry => '族譜';

  @override
  String get myHomeFamilyTreeDesc => '一張圖看清整個家族';

  @override
  String get familyTreeTitle => '族譜';

  @override
  String get familyTreeViewerYou => '你';

  @override
  String get familyTreeViewerLabel => '本人';

  @override
  String get familyTreeEmpty => '還沒有家人';

  @override
  String get familyTreeEmptyDesc => '家人加入後，他們的關係會顯示在這裡。';

  @override
  String get familyTreeOtherFamily => '其他親屬';

  @override
  String familyTreeOtherFamilyDesc(Object count) {
    return '另有 $count 位家人以列表展示';
  }

  @override
  String get appWindowTitle => '過家家';

  @override
  String get myHomeSectionFamilyTitle => '家';

  @override
  String get myHomeWelcomeTagline => '家人閒坐,燈火可親';

  @override
  String get greetingEarlyMorning => '夜深了';

  @override
  String get greetingMorning => '早安';

  @override
  String get greetingNoon => '中午好';

  @override
  String get greetingAfternoon => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get greetingLateNight => '夜深了';

  @override
  String get profileSectionFamilyTitle => '家 庭';

  @override
  String get profileSectionSettingsTitle => '設 置';

  @override
  String get profileFamilyMembersSubtitle => '查看所有家庭成員';

  @override
  String get profileJoinFamilySubtitle => '邀請碼加入其他家庭';

  @override
  String get locationHubSectionTitle => '即時位置';

  @override
  String get locationHubTitle => '即時位置';

  @override
  String get locationHubSubtitle => '查看家人即時位置、活動軌跡、圍欄與警報';

  @override
  String get locationHubLiveMapDesc => '查看每個家庭成員的當前位置';

  @override
  String get locationHubHistoryDesc => '查看成員某一天的活動軌跡';

  @override
  String get locationHubFenceDesc => '設定安全活動範圍，進入或離開時收到提醒';

  @override
  String get locationHubFenceAlarmsDesc => '查看家人進出圍欄的提醒';

  @override
  String get familyFeedEmptyTitle => '還沒有動態';

  @override
  String get familyFeedEmptyDesc => '發一條，讓家裡人多一點回憶。';

  @override
  String get familyFeedLoadMoreError => '載入更多失敗';

  @override
  String get familyFeedDeleteTitle => '刪除這條動態？';

  @override
  String get familyFeedDeleteBody => '刪除後家裡所有人都看不到。';

  @override
  String get familyFeedDeleteConfirm => '刪除';

  @override
  String get familyFeedDeleted => '動態已刪除';

  @override
  String get familyFeedLikeTooltip => '讚';

  @override
  String get familyFeedUnlikeTooltip => '已讚';

  @override
  String familyFeedLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '被點讚 $count 次',
      zero: '還沒有人點讚',
    );
    return '$_temp0';
  }

  @override
  String familyFeedMoreLikers(Object count) {
    return '還有 $count 人';
  }

  @override
  String momentCardCommentCount(int count) {
    return '$count 則評論';
  }

  @override
  String momentCardLatestComment(String content) {
    return '$content';
  }

  @override
  String momentDetailLikedTimes(int count) {
    return '點讚 $count 次';
  }

  @override
  String get familyFeedNoCommentsYet => '還沒有評論';

  @override
  String get familyFeedCommentsComingSoon => '評論功能即將上線';

  @override
  String get familyFeedPublishButton => '發佈';

  @override
  String get publishMomentTitle => '發動態';

  @override
  String get publishMomentContentLabel => '說點什麼…';

  @override
  String get publishMomentContentHint => '一張照片，一段心情，都是家裡的記憶。';

  @override
  String get publishMomentContentRequired => '寫點兒內容或者加張照片再發佈吧';

  @override
  String get publishMomentAddMedia => '新增';

  @override
  String get publishMomentMediaTypeImage => '照片';

  @override
  String get publishMomentMediaTypeVideo => '影片';

  @override
  String get publishMomentMediaTypeAudio => '語音';

  @override
  String get publishMomentAddMediaSheet => '新增到動態';

  @override
  String get publishMomentMaxMedia => '最多 9 個檔案';

  @override
  String get publishMomentReorderHint => '長按並拖動可調整順序';

  @override
  String get publishMomentRemoveMedia => '移除';

  @override
  String get publishMomentRecordingHint => '點擊開始錄音';

  @override
  String get publishMomentRecordingStop => '點擊結束';

  @override
  String get publishMomentRecordingCancel => '取消';

  @override
  String get publishMomentRecordingTooShort => '再長一點點吧';

  @override
  String get publishMomentRecordingFailed => '錄音失敗';

  @override
  String get publishMomentRecordingPermissionBody => '需要麥克風權限才能錄製語音';

  @override
  String get publishMomentPublish => '發佈';

  @override
  String get publishMomentPublishing => '發佈中…';

  @override
  String get publishMomentSuccess => '發佈成功';

  @override
  String get publishMomentFailed => '發佈失敗，請重試';

  @override
  String publishMomentUploading(Object current, Object total) {
    return '正在上傳 $current/$total…';
  }

  @override
  String get publishMomentDiscardTitle => '放棄這條動態？';

  @override
  String get publishMomentDiscardBody => '目前編輯將遺失。';

  @override
  String get publishMomentDiscardConfirm => '放棄';

  @override
  String get publishMomentDiscardCancel => '繼續編輯';

  @override
  String get publishMomentDraftSaveAction => '存為草稿';

  @override
  String get publishMomentDraftRestored => '已恢復草稿';

  @override
  String get publishMomentDraftClear => '清除草稿';

  @override
  String get momentDetailTitle => '動態詳情';

  @override
  String get momentDetailWhoLikedTitle => '點讚列表';

  @override
  String get momentDetailNoLikes => '搶個沙發吧';

  @override
  String get momentDetailPlayVideo => '播放影片';

  @override
  String get momentDetailVideoLoadFailed => '影片載入失敗';

  @override
  String get momentDetailAudioLoadFailed => '語音載入失敗';

  @override
  String get momentDetailAudioPlay => '播放';

  @override
  String get momentDetailAudioPause => '暫停';

  @override
  String get momentDetailLikeKing => '點讚狂人';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '錄音中 $seconds 秒 — 點一下停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '正在壓縮…';

  @override
  String get publishMomentMediaUploading => '媒體上傳中…';

  @override
  String publishMomentVideoTooLarge(String size) {
    return '壓縮後仍有 $size MB，請選擇更短的影片。';
  }

  @override
  String publishMomentVideoTooLargeRaw(String size) {
    return '影片壓縮失敗（$size MB），請選擇更小的檔案。';
  }

  @override
  String get familyFeedLikeTooltipLong => '點讚 · 長按取消你點的讚';

  @override
  String get familyFeedLikeCancelFailed => '取消讚失敗,請重試';

  @override
  String get conversationsSearchHint => '搜尋訊息和聊天';

  @override
  String get conversationsSearchEmptyHint => '輸入關鍵字搜尋已儲存的訊息。';

  @override
  String conversationsSearchNoResults(String query) {
    return '沒有找到符合「$query」的結果。';
  }

  @override
  String get profileThemeRow => '主題';

  @override
  String get profileThemeSheetTitle => '選擇主題';

  @override
  String get profileAppearanceRow => '外觀模式';

  @override
  String get profileAppearanceSheetTitle => '選擇外觀模式';

  @override
  String get profileThemeModeSection => '外觀模式';

  @override
  String get profileThemeModeSystem => '跟隨系統';

  @override
  String get profileThemeModeLight => '淺色';

  @override
  String get profileThemeModeDark => '深色';

  @override
  String get profileThemeColorSection => '配色';

  @override
  String get momentCommentSectionTitle => '評論';

  @override
  String get momentCommentEmpty => '還沒有評論，來搶沙發';

  @override
  String get momentCommentInputHint => '說點什麼...';

  @override
  String get momentCommentSend => '發送';

  @override
  String get momentCommentDeleteTitle => '刪除這條評論？';

  @override
  String get momentCommentDeleteBody => '該評論將對所有家庭成員刪除。';

  @override
  String get momentCommentDeleteFailed => '刪除評論失敗，請重試';

  @override
  String get chatMessageTooLong => '訊息過長（最多 2000 字）';

  @override
  String get profileClearLocalChatConfirmTitle => '刪除本機聊天記錄？';

  @override
  String get profileClearLocalChatConfirmBody =>
      '僅清除本機快取的訊息，不會刪除伺服器上的記錄，重新開啟聊天會從伺服器重新載入。';

  @override
  String get profileClearLocalChatSuccess => '本機聊天記錄已刪除';

  @override
  String get profileStorageRow => '儲存空間';

  @override
  String get profileStorageSubtitle => '查看本機快取佔用，並清理';

  @override
  String get profileExportChatRow => '匯出聊天記錄';

  @override
  String get profileExportChatSubtitle => '將本機聊天記錄儲存為文字檔';

  @override
  String get chatExportTitle => '匯出聊天記錄';

  @override
  String get chatExportEmpty => '暫無可匯出的本機聊天記錄';

  @override
  String chatExportSummary(int conversations, int messages) {
    return '共 $conversations 個對話，$messages 則訊息';
  }

  @override
  String get chatExportCopy => '複製全部';

  @override
  String get chatExportCopied => '已複製到剪貼簿';

  @override
  String chatExportSavedTo(String path) {
    return '已儲存至：$path';
  }

  @override
  String get chatExportSelectConversationsTitle => '選擇要匯出的對話';

  @override
  String get chatExportSelectAll => '全選';

  @override
  String get chatExportDeselectAll => '取消全選';

  @override
  String get chatExportFormatSection => '匯出格式';

  @override
  String get chatExportFormatTxt => '文字（不含圖片）';

  @override
  String get chatExportFormatPdf => 'PDF（含圖片）';

  @override
  String get chatExportGenerateButton => '匯出';

  @override
  String get chatExportSelectAtLeastOne => '請至少選擇一個對話';

  @override
  String get chatExportShare => '分享';

  @override
  String get chatExportGenerating => '正在產生…';

  @override
  String chatExportGeneratingProgress(int current, int total) {
    return '正在產生 $current/$total 則訊息…';
  }

  @override
  String get chatExportDateRangeAll => '全部時間';

  @override
  String get chatExportLongRangeTitle => '日期範圍較長';

  @override
  String get chatExportLongRangeBody => '選擇的日期範圍較長，產生速度可能會比較慢，是否繼續匯出？';

  @override
  String get chatExportImageLoadFailed => '圖片載入失敗';

  @override
  String get storageScreenTitle => '儲存空間';

  @override
  String storageTotalLabel(String size) {
    return '共 $size';
  }

  @override
  String get storageImageCache => '圖片快取';

  @override
  String get storageAvatarCache => '頭像快取';

  @override
  String get storageVideoCache => '影片快取';

  @override
  String get storageAudioCache => '音訊快取';

  @override
  String get storageChatHistory => '聊天記錄';

  @override
  String get storageSizeUnknown => '未知';

  @override
  String get storageClear => '清除';

  @override
  String get storageClearAll => '清除全部快取';

  @override
  String storageClearMediaConfirmTitle(String category) {
    return '確定要清除$category嗎？';
  }

  @override
  String get storageClearMediaConfirmBody => '快取檔案將被刪除，下次使用時會重新從網路下載。';

  @override
  String get storageClearAllConfirmTitle => '確定要清除全部本機快取嗎？';

  @override
  String get storageClearAllConfirmBody =>
      '這將清除圖片、影片、音訊快取以及本機保存的聊天記錄。媒體檔案會在需要時重新下載；聊天記錄可重新從伺服器載入。';

  @override
  String get storageClearSuccess => '快取已清除';

  @override
  String get myHomeSectionHealthTitle => '健康';

  @override
  String get healthTitle => '家庭健康';

  @override
  String get healthSubtitle => '記錄全家人的身高、體重和血壓';

  @override
  String get healthTabMyRecords => '我的記錄';

  @override
  String get healthTabFamily => '家人';

  @override
  String get healthTabSettings => '設定';

  @override
  String get healthTabAll => '全部';

  @override
  String get healthRecordNew => '記錄新數據';

  @override
  String get healthRecordSubmit => '儲存';

  @override
  String get healthRecordDate => '日期';

  @override
  String get healthHeight => '身高';

  @override
  String get healthWeight => '體重';

  @override
  String get healthBloodPressure => '血壓';

  @override
  String get healthHeightCm => '身高 (cm)';

  @override
  String get healthWeightKg => '體重 (kg)';

  @override
  String get healthBloodPressureSystolic => '收縮壓 (mmHg)';

  @override
  String get healthBloodPressureDiastolic => '舒張壓 (mmHg)';

  @override
  String get healthBloodPressureBothRequired => '請輸入收縮壓和舒張壓';

  @override
  String get healthValueRequired => '請輸入數值';

  @override
  String get healthValueInvalid => '數字格式不正確';

  @override
  String get healthHistoryTitle => '歷史記錄';

  @override
  String get healthNoRecords => '暫無健康記錄';

  @override
  String get healthSelectMember => '選擇家庭成員';

  @override
  String get healthSelectMemberHint => '選擇家人查看他們公開的健康數據。';

  @override
  String get healthFilterByMetric => '按類型篩選';

  @override
  String get healthVisibilityTitle => '可見性';

  @override
  String get healthReminderTitle => '每日提醒';

  @override
  String get healthReminderEnable => '開啟每日提醒';

  @override
  String get healthReminderTime => '提醒時間';

  @override
  String get healthReminderHint => '到設定時間若還未記錄健康數據，將通過推送通知提醒你。';

  @override
  String get healthChartEmpty => '資料不足，暫無法繪製圖表。';

  @override
  String get healthChartSinglePoint => '目前只有一筆記錄，繼續記錄即可看到趨勢。';

  @override
  String get healthChartLatest => '最新';

  @override
  String get healthChartMin => '最低';

  @override
  String get healthChartMax => '最高';

  @override
  String get healthChartAverage => '平均';

  @override
  String get healthChartSelectMetric => '選擇上方指標類型查看圖表。';

  @override
  String get healthEditSave => '儲存';

  @override
  String get healthEditDateConflict => '該日期已存在該指標的記錄。';

  @override
  String get healthEditRecordNotFound => '這筆記錄已不存在。';

  @override
  String get healthEditNotOwner => '只能修改自己的記錄。';

  @override
  String get healthEditFailed => '更新記錄失敗。';

  @override
  String get healthRecordEditHint => '點擊記錄以編輯';

  @override
  String get healthChartBpZoneLow => '偏低';

  @override
  String get healthChartBpZoneNormal => '正常';

  @override
  String get healthChartBpZoneElevated => '偏高';

  @override
  String get healthChartBpZoneHigh => '高';

  @override
  String get healthChartBpDiastolicCap => '舒張壓上限 80';

  @override
  String get familyFeedScopeMyFamily => '自個兒家';

  @override
  String get familyFeedScopeOthers => '串串門';

  @override
  String get publishMomentPublicToggle => '公開發佈';

  @override
  String get publishMomentPublicHint => '公開後這則動態及其評論會出現在跨家庭動態廣場裡';

  @override
  String get publicMomentsTitle => '串串門';

  @override
  String publicMomentsFromFamily(String familyName) {
    return '來自 $familyName';
  }

  @override
  String get publicMomentsEmptyTitle => '還沒有人公開發佈';

  @override
  String get publicMomentsEmptyDesc => '想做第一個分享的人？';

  @override
  String get publicMomentsLoadMoreError => '載入更多失敗';

  @override
  String get profileBalanceLabel => '餘額';

  @override
  String balanceValue(String amount) {
    return '¥$amount';
  }

  @override
  String get editProfileBalanceHint => '如需儲值請聯絡家庭管理員';

  @override
  String get redpacketHubTitle => '我的紅包';

  @override
  String get redpacketHubSubtitle => '查看我發出和收到的紅包';

  @override
  String get redpacketSendTitle => '發紅包';

  @override
  String get redpacketTotalAmountLabel => '總金額';

  @override
  String get redpacketTotalAmountHint => '單位：元，例如 100 或 88.88';

  @override
  String get redpacketTotalCountLabel => '紅包個數';

  @override
  String redpacketTotalCountHint(int max) {
    return '最多 $max 個';
  }

  @override
  String get redpacketSendButton => '塞錢進紅包';

  @override
  String redpacketAmountYuan(String amount) {
    return '$amount 元';
  }

  @override
  String redpacketShareCountSuffix(int count) {
    return '$count 份';
  }

  @override
  String redpacketCountUnit(int count) {
    return '$count 個紅包';
  }

  @override
  String get redpacketCardLabel => '紅包';

  @override
  String redpacketCardFromLabel(String name) {
    return '$name 發了一個紅包';
  }

  @override
  String get redpacketStatusOngoing => '進行中';

  @override
  String get redpacketStatusFinished => '已領完';

  @override
  String get redpacketStatusExpired => '已過期';

  @override
  String get redpacketStatusRefunded => '已退款';

  @override
  String get redpacketGrabButton => '開';

  @override
  String redpacketGrabSuccess(String amount) {
    return '你搶到了 ¥$amount';
  }

  @override
  String get redpacketAlreadyGrabbed => '你已經搶過這個紅包了';

  @override
  String get redpacketGrabListTitle => '已領取的人';

  @override
  String get redpacketGrabListEmpty => '暫無人領取';

  @override
  String redpacketGrabListCount(int grabbed, int total) {
    return '$grabbed/$total 已領取';
  }

  @override
  String get redpacketExpiredNotice => '紅包已過期';

  @override
  String get redpacketEmptyNotice => '紅包已被搶光了';

  @override
  String get redpacketSelfNotice => '你發出的紅包';

  @override
  String get redpacketRecordsTitle => '我的紅包';

  @override
  String get redpacketRecordsTabSent => '我發出的';

  @override
  String get redpacketRecordsTabReceived => '我收到的';

  @override
  String get redpacketRecordsEmpty => '暫無紅包記錄';

  @override
  String get redpacketErrorInvalidAmount => '總金額必須不少於紅包個數（每份至少 1 分錢）。';

  @override
  String get redpacketErrorInsufficientFund => '餘額不足，無法發送紅包。';

  @override
  String get redpacketErrorTooManyShares => '紅包個數不能超過對話成員數。';

  @override
  String get redpacketErrorNotMember => '你已不在該對話中。';

  @override
  String get redpacketErrorExpired => '紅包已過期。';

  @override
  String get redpacketErrorAlreadyGrabbed => '你已經搶過這個紅包。';

  @override
  String get redpacketErrorEmpty => '紅包已被搶完。';

  @override
  String get redpacketErrorNotFound => '紅包不存在。';

  @override
  String get redpacketMessageSendFailed => '紅包已建立，但公告訊息傳送失敗，網路恢復後重新開啟會話查看。';

  @override
  String get chatRoomRedpacketOption => '紅包';

  @override
  String get chatMessageTypeRedpacket => '[紅包]';

  @override
  String get errorParamInvalid => '請求參數錯誤。';

  @override
  String get errorUnauthorized => '未登入或登入已過期，請重新登入。';

  @override
  String get errorForbidden => '沒有權限執行該操作。';

  @override
  String get errorResourceNotFound => '請求的資源不存在。';

  @override
  String get errorDataConflict => '資料衝突，請重新整理後再試。';

  @override
  String get errorSystemBusy => '系統繁忙，請稍後再試。';

  @override
  String get errorEmptyFile => '上傳的檔案為空。';

  @override
  String get errorFileSizeIllegal => '檔案大小不符合要求。';

  @override
  String get errorFileTypeIllegal => '檔案類型不符合要求。';

  @override
  String get errorFileNameIllegal => '檔案名稱不符合要求。';

  @override
  String get errorFileUploadFailed => '檔案上傳失敗，請稍後再試。';

  @override
  String get errorPhoneFormatInvalid => '手機號碼格式不正確，請檢查。';

  @override
  String get errorPasswordFormatInvalid => '密碼格式不符合要求，請檢查。';

  @override
  String get errorNameFormatInvalid => '暱稱不符合要求，請檢查。';

  @override
  String get errorRegisterParamConflict => '家庭名稱與邀請碼只能擇一。';

  @override
  String get errorPhoneAlreadyExists => '該手機號碼已被註冊。';

  @override
  String get errorLoginFailed => '手機號碼或密碼錯誤。';

  @override
  String get errorTokenInvalid => '登入已失效，請重新登入。';

  @override
  String get errorTokenExpired => '登入已過期，請重新登入。';

  @override
  String get errorRefreshTokenInvalid => '登入已失效，請重新登入。';

  @override
  String get errorUserNotFound => '使用者不存在。';

  @override
  String get errorFamilyNameEmpty => '請輸入家庭名稱。';

  @override
  String get errorInviteCodeEmpty => '請輸入邀請碼。';

  @override
  String get errorRelationTypeInvalid => '無效的家庭關係類型。';

  @override
  String get errorFamilyNotFound => '找不到該家庭。';

  @override
  String get errorFamilyMemberNotFound => '找不到該家庭成員。';

  @override
  String get errorInviteCodeInvalid => '邀請碼不存在或已過期。';

  @override
  String get errorRelationAnchorInvalid => '選擇的關係對象無效。';

  @override
  String get errorNotFamilyMember => '你不是該家庭成員。';

  @override
  String get errorNotFamilyAdmin => '僅家庭管理員可執行該操作。';

  @override
  String get errorFamilySaveFailed => '家庭建立失敗，請稍後再試。';

  @override
  String get errorSpouseAlreadyExists => '對方已經有配偶了。';

  @override
  String get errorNoKnownParent => '父母關係未知，無法建立兄弟姊妹關係。';

  @override
  String get errorConversationNotFound => '對話不存在。';

  @override
  String get errorMessageTooLong => '訊息內容過長。';

  @override
  String get errorMessageTypeInvalid => '不支援的訊息類型。';

  @override
  String get errorLocationCoordinateInvalid => '定位座標不能為空。';

  @override
  String get errorLocationBatteryInvalid => '電量數值不合法。';

  @override
  String get errorLocationTimestampMissing => '定位時間戳記不能為空。';

  @override
  String get errorLocationTimestampStale => '定位資料已過期，請重新回報。';

  @override
  String get errorLocationTargetNotFamilyMember => '目標使用者不是同一家庭成員。';

  @override
  String get errorFenceRangeInvalid => '圍欄半徑不合法。';

  @override
  String get errorFenceNotFound => '圍欄不存在。';

  @override
  String get errorNotFenceSetter => '僅圍欄設置者可執行該操作。';

  @override
  String get errorMomentContentEmpty => '動態內容和媒體不能同時為空。';

  @override
  String get errorMomentMediaTypeInvalid => '媒體類型不正確。';

  @override
  String get errorLikeRecordNotFound => '尚未按讚，無法取消。';

  @override
  String get errorMomentNotFound => '動態不存在。';

  @override
  String get errorNotMomentOwner => '僅動態發布者本人可執行該操作。';

  @override
  String get errorCommentContentEmpty => '留言內容不能為空。';

  @override
  String get errorCommentNotFound => '留言不存在。';

  @override
  String get errorNotCommentOwner => '僅留言作者本人可執行該操作。';

  @override
  String get errorHealthMetricTypeInvalid => '健康指標類型不正確。';

  @override
  String get errorHealthRecordValueInvalid => '健康記錄數值不合法。';

  @override
  String get errorNotSameFamily => '目標使用者不是同一家庭成員。';

  @override
  String get errorRemindTimeInvalid => '提醒時間格式不正確。';

  @override
  String get errorHealthRecordNotFound => '健康記錄不存在。';

  @override
  String get errorNotHealthRecordOwner => '僅本人可修改自己的健康記錄。';

  @override
  String get errorHealthRecordDateConflict => '該日期已存在同指標的記錄。';
}
