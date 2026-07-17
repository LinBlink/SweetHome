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
  String get registerRequestJoinTab => '申请邀请码';

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
  String get requestJoinTargetPhoneLabel => '你认识的家庭成员的手机号';

  @override
  String get requestJoinTargetPhoneRequired => '请输入对方手机号';

  @override
  String get requestJoinTargetPhoneHint =>
      '* 不需要邀请码，只需要填一个已经在这个家庭里的人的手机号，对方家庭的管理员会审核你的申请';

  @override
  String get requestJoinMessageLabel => '给管理员的留言（选填）';

  @override
  String get requestJoinSubmit => '提交申请';

  @override
  String get requestJoinSubmittedTitle => '申请已提交';

  @override
  String get requestJoinSubmittedMessage =>
      '你的申请已发送给家庭管理员审核，审核通过后请用刚才填写的手机号和密码登录';

  @override
  String get joinRequestsTitle => '加入申请';

  @override
  String get joinRequestsEmpty => '暂无待处理的申请';

  @override
  String joinRequestsRelationLine(String relation, String targetName) {
    return '想成为 $targetName 的$relation';
  }

  @override
  String get relationNounChild => '孩子';

  @override
  String get relationNounParent => '父母';

  @override
  String get relationNounSpouse => '配偶';

  @override
  String get relationNounSibling => '兄弟姐妹';

  @override
  String get joinRequestsApprove => '通过';

  @override
  String get joinRequestsReject => '拒绝';

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
  String get myHomeJoinRequestsEntry => '加入申请';

  @override
  String get myHomeJoinRequestsDesc => '审核并批准加入本家庭的申请';

  @override
  String myHomeJoinRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条待处理',
      one: '1 条待处理',
      zero: '暂无待处理',
    );
    return '$_temp0';
  }

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
  String get joinRequestsAdminTitle => '加入申请';

  @override
  String get joinRequestsAdminEmpty => '暂无待处理的申请。';

  @override
  String get joinRequestsAdminReject => '拒绝';

  @override
  String get joinRequestsAdminApprove => '通过';

  @override
  String joinRequestsAdminRelationLine(String relation, String targetName) {
    return '想成为 $targetName 的$relation';
  }

  @override
  String joinRequestsAdminMessage(String message) {
    return '留言：$message';
  }

  @override
  String get joinRequestsAdminRejectDialogTitle => '确认拒绝此申请？';

  @override
  String get joinRequestsAdminRejectDialogReason => '拒绝原因（选填）';

  @override
  String get joinRequestsAdminRejectSubmit => '拒绝';

  @override
  String get joinRequestsAdminRejectCancel => '取消';

  @override
  String get joinRequestsAdminRejectSuccess => '已拒绝';

  @override
  String get joinRequestsAdminApproveSuccess => '已通过';

  @override
  String get joinRequestsAdminError => '操作失败';

  @override
  String get requestJoinModeByCode => '我有邀请码';

  @override
  String get requestJoinModeByPhone => '我认识某位成员的手机号';

  @override
  String get requestJoinNoFamilySubmit => '提交申请';

  @override
  String get requestJoinByCodeHint => '如已拿到邀请码，可使用邀请码加入。';

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
  String get profileJoinRequestsRow => '加入申请';

  @override
  String get profileJoinRequestsAdminOnly => '仅管理员可见';

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
  String get momentDetailAudioPlay => '播放';

  @override
  String get momentDetailAudioPause => '暂停';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '录音中 $seconds 秒 — 点一下停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '正在压缩…';

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
  String get profileClearLocalChatRow => '删除本地聊天记录';

  @override
  String get profileClearLocalChatSubtitle => '仅清除本机缓存的消息';

  @override
  String get profileClearLocalChatConfirmTitle => '删除本地聊天记录？';

  @override
  String get profileClearLocalChatConfirmBody =>
      '仅清除本机缓存的消息，不会删除服务器上的记录，重新打开聊天会从服务器重新加载。';

  @override
  String get profileClearLocalChatSuccess => '本地聊天记录已删除';
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
  String get registerRequestJoinTab => '申请邀请码';

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
  String get requestJoinTargetPhoneLabel => '你认识的家庭成员的手机号';

  @override
  String get requestJoinTargetPhoneRequired => '请输入对方手机号';

  @override
  String get requestJoinTargetPhoneHint =>
      '* 不需要邀请码，只需要填一个已经在这个家庭里的人的手机号，对方家庭的管理员会审核你的申请';

  @override
  String get requestJoinMessageLabel => '给管理员的留言（选填）';

  @override
  String get requestJoinSubmit => '提交申请';

  @override
  String get requestJoinSubmittedTitle => '申请已提交';

  @override
  String get requestJoinSubmittedMessage =>
      '你的申请已发送给家庭管理员审核，审核通过后请用刚才填写的手机号和密码登录';

  @override
  String get joinRequestsTitle => '加入申请';

  @override
  String get joinRequestsEmpty => '暂无待处理的申请';

  @override
  String joinRequestsRelationLine(String relation, String targetName) {
    return '想成为 $targetName 的$relation';
  }

  @override
  String get relationNounChild => '孩子';

  @override
  String get relationNounParent => '父母';

  @override
  String get relationNounSpouse => '配偶';

  @override
  String get relationNounSibling => '兄弟姐妹';

  @override
  String get joinRequestsApprove => '通过';

  @override
  String get joinRequestsReject => '拒绝';

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
  String get myHomeJoinRequestsEntry => '加入申请';

  @override
  String get myHomeJoinRequestsDesc => '审核并批准加入本家庭的申请';

  @override
  String myHomeJoinRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条待处理',
      one: '1 条待处理',
      zero: '暂无待处理',
    );
    return '$_temp0';
  }

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
  String get joinRequestsAdminTitle => '加入申请';

  @override
  String get joinRequestsAdminEmpty => '暂无待处理的申请。';

  @override
  String get joinRequestsAdminReject => '拒绝';

  @override
  String get joinRequestsAdminApprove => '通过';

  @override
  String joinRequestsAdminRelationLine(String relation, String targetName) {
    return '想成为 $targetName 的$relation';
  }

  @override
  String joinRequestsAdminMessage(String message) {
    return '留言：$message';
  }

  @override
  String get joinRequestsAdminRejectDialogTitle => '确认拒绝此申请？';

  @override
  String get joinRequestsAdminRejectDialogReason => '拒绝原因（选填）';

  @override
  String get joinRequestsAdminRejectSubmit => '拒绝';

  @override
  String get joinRequestsAdminRejectCancel => '取消';

  @override
  String get joinRequestsAdminRejectSuccess => '已拒绝';

  @override
  String get joinRequestsAdminApproveSuccess => '已通过';

  @override
  String get joinRequestsAdminError => '操作失败';

  @override
  String get requestJoinModeByCode => '我有邀请码';

  @override
  String get requestJoinModeByPhone => '我认识某位成员的手机号';

  @override
  String get requestJoinNoFamilySubmit => '提交申请';

  @override
  String get requestJoinByCodeHint => '如已拿到邀请码，可使用邀请码加入。';

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
  String get profileJoinRequestsRow => '加入申请';

  @override
  String get profileJoinRequestsAdminOnly => '仅管理员可见';

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
  String get momentDetailAudioPlay => '播放';

  @override
  String get momentDetailAudioPause => '暂停';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '录音中 $seconds 秒 — 点一下停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '正在压缩…';

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
  String get profileClearLocalChatRow => '删除本地聊天记录';

  @override
  String get profileClearLocalChatSubtitle => '仅清除本机缓存的消息';

  @override
  String get profileClearLocalChatConfirmTitle => '删除本地聊天记录？';

  @override
  String get profileClearLocalChatConfirmBody =>
      '仅清除本机缓存的消息，不会删除服务器上的记录，重新打开聊天会从服务器重新加载。';

  @override
  String get profileClearLocalChatSuccess => '本地聊天记录已删除';
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
  String get registerRequestJoinTab => '申請邀請碼';

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
  String get requestJoinTargetPhoneLabel => '你認識的家庭成員的手機號';

  @override
  String get requestJoinTargetPhoneRequired => '請輸入對方手機號';

  @override
  String get requestJoinTargetPhoneHint =>
      '* 不需要邀請碼，只需要填一個已經在這個家庭裡的人的手機號，對方家庭的管理員會審核你的申請';

  @override
  String get requestJoinMessageLabel => '給管理員的留言（選填）';

  @override
  String get requestJoinSubmit => '提交申請';

  @override
  String get requestJoinSubmittedTitle => '申請已提交';

  @override
  String get requestJoinSubmittedMessage =>
      '你的申請已發送給家庭管理員審核，審核通過後請用剛才填寫的手機號和密碼登入';

  @override
  String get joinRequestsTitle => '加入申請';

  @override
  String get joinRequestsEmpty => '暫無待處理的申請';

  @override
  String joinRequestsRelationLine(String relation, String targetName) {
    return '想成為 $targetName 的$relation';
  }

  @override
  String get relationNounChild => '孩子';

  @override
  String get relationNounParent => '父母';

  @override
  String get relationNounSpouse => '配偶';

  @override
  String get relationNounSibling => '兄弟姐妹';

  @override
  String get joinRequestsApprove => '通過';

  @override
  String get joinRequestsReject => '拒絕';

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
  String get myHomeJoinRequestsEntry => '加入申請';

  @override
  String get myHomeJoinRequestsDesc => '審核並批准加入本家庭的申請';

  @override
  String myHomeJoinRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 條待處理',
      one: '1 條待處理',
      zero: '暫無待處理',
    );
    return '$_temp0';
  }

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
  String get joinRequestsAdminTitle => '加入申請';

  @override
  String get joinRequestsAdminEmpty => '暫無待處理的申請。';

  @override
  String get joinRequestsAdminReject => '拒絕';

  @override
  String get joinRequestsAdminApprove => '通過';

  @override
  String joinRequestsAdminRelationLine(String relation, String targetName) {
    return '想成為 $targetName 的$relation';
  }

  @override
  String joinRequestsAdminMessage(String message) {
    return '留言：$message';
  }

  @override
  String get joinRequestsAdminRejectDialogTitle => '確認拒絕此申請？';

  @override
  String get joinRequestsAdminRejectDialogReason => '拒絕原因（選填）';

  @override
  String get joinRequestsAdminRejectSubmit => '拒絕';

  @override
  String get joinRequestsAdminRejectCancel => '取消';

  @override
  String get joinRequestsAdminRejectSuccess => '已拒絕';

  @override
  String get joinRequestsAdminApproveSuccess => '已通過';

  @override
  String get joinRequestsAdminError => '操作失敗';

  @override
  String get requestJoinModeByCode => '我有邀請碼';

  @override
  String get requestJoinModeByPhone => '我認識某位成員的手機號';

  @override
  String get requestJoinNoFamilySubmit => '提交申請';

  @override
  String get requestJoinByCodeHint => '如已拿到邀請碼，可使用邀請碼加入。';

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
  String get profileJoinRequestsRow => '加入申請';

  @override
  String get profileJoinRequestsAdminOnly => '僅管理員可見';

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
  String get momentDetailAudioPlay => '播放';

  @override
  String get momentDetailAudioPause => '暫停';

  @override
  String publishMomentRecordingInProgress(int seconds) {
    return '錄音中 $seconds 秒 — 點一下停止';
  }

  @override
  String get publishMomentRecordingStopInline => '停止';

  @override
  String get publishMomentCompressing => '正在壓縮…';

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
  String get profileClearLocalChatRow => '刪除本機聊天記錄';

  @override
  String get profileClearLocalChatSubtitle => '僅清除本機快取的訊息';

  @override
  String get profileClearLocalChatConfirmTitle => '刪除本機聊天記錄？';

  @override
  String get profileClearLocalChatConfirmBody =>
      '僅清除本機快取的訊息，不會刪除伺服器上的記錄，重新開啟聊天會從伺服器重新載入。';

  @override
  String get profileClearLocalChatSuccess => '本機聊天記錄已刪除';
}
