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
  String locationUpdatedMinutesAgo(int minutes) {
    return '$minutes 分钟前更新';
  }

  @override
  String locationBattery(int percent) {
    return '电量：$percent%';
  }

  @override
  String get locationBatteryUnknown => '电量：未知';

  @override
  String locationCoordinates(String lng, String lat) {
    return '经度 $lng，纬度 $lat';
  }

  @override
  String get locationNoData => '暂无位置数据';

  @override
  String get locationNoDataDesc => '家庭成员需要开启位置共享后，才能在此显示。';

  @override
  String locationTotalMembers(int total) {
    return '共 $total 位成员';
  }

  @override
  String locationOnlineCount(int online, int total) {
    return '$online/$total 位正在共享位置';
  }

  @override
  String get locationReportNow => '分享我的位置';

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
  String locationUpdatedMinutesAgo(int minutes) {
    return '$minutes 分钟前更新';
  }

  @override
  String locationBattery(int percent) {
    return '电量：$percent%';
  }

  @override
  String get locationBatteryUnknown => '电量：未知';

  @override
  String locationCoordinates(String lng, String lat) {
    return '经度 $lng，纬度 $lat';
  }

  @override
  String get locationNoData => '暂无位置数据';

  @override
  String get locationNoDataDesc => '家庭成员需要开启位置共享后，才能在此显示。';

  @override
  String locationTotalMembers(int total) {
    return '共 $total 位成员';
  }

  @override
  String locationOnlineCount(int online, int total) {
    return '$online/$total 位正在共享位置';
  }

  @override
  String get locationReportNow => '分享我的位置';

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
  String locationUpdatedMinutesAgo(int minutes) {
    return '$minutes 分鐘前更新';
  }

  @override
  String locationBattery(int percent) {
    return '電量：$percent%';
  }

  @override
  String get locationBatteryUnknown => '電量：未知';

  @override
  String locationCoordinates(String lng, String lat) {
    return '經度 $lng，緯度 $lat';
  }

  @override
  String get locationNoData => '暫無位置資料';

  @override
  String get locationNoDataDesc => '家庭成員需開啟位置共享後，才會在此顯示。';

  @override
  String locationTotalMembers(int total) {
    return '共 $total 位成員';
  }

  @override
  String locationOnlineCount(int online, int total) {
    return '位置共享中 $online/$total 位';
  }

  @override
  String get locationReportNow => '分享我的位置';

  @override
  String get locationReportFailed => '位置分享失敗';

  @override
  String get locationLocating => '正在定位…';

  @override
  String get locationPermissionTitle => '需要定位權限';

  @override
  String get locationPermissionBody => '如需向家庭成員共享你的位置，請允許過家家存取你的位置。';

  @override
  String get locationPermissionGrant => '授予權限';

  @override
  String get locationPermissionDenied => '權限被拒。請到系統設定中開啟後再嘗試分享位置。';

  @override
  String get locationPermissionOpenSettings => '打開設定';

  @override
  String get locationGpsOff => 'GPS 已關閉。開啟後可分享精確位置。';

  @override
  String get locationGpsTimeout => '無法及時取得 GPS 定位。請到開闊處或檢查訊號後重試。';

  @override
  String get locationGpsUnavailable =>
      '裝置目前無法取得位置。請檢查系統設定、開發者選項的模擬位置應用，或廠商隱私設定。';

  @override
  String get locationRefresh => '重新整理';

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
}
