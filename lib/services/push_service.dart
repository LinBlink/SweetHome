import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import 'api_client.dart';
import '../models/auth_models.dart';

/// 极光推送集成，用于 §2.7 推送令牌注册。负责插件生命周期管理
/// （初始化、事件监听、注册ID获取），并为认证提供者提供轻量级的
/// REST 接口，以便在登录/登出时注册或注销设备的 `registrationId`。
///
/// **平台配置：**
///   - Android：`android/app/build.gradle.kts` 中的 `JPUSH_APPKEY`
///     清单占位符需设置为与后端 `JPUSH_APP_KEY`（docs/API.md §2.7）
///     相同的极光控制台应用密钥。
///   - iOS Xcode 项目仍需启用推送通知功能并上传 APNs 证书/密钥 ——
///     无法通过 Dart/Gradle 完成。Web 平台不支持极光推送，因此该服务
///     的所有方法在非移动平台上均为空操作（参见 [PushService.setup]）。
///
/// **连接方式：** [PushService] 在应用启动时创建一次，并在首帧渲染前
/// 调用 `setup()`。[registerForUser] 由 `AuthProvider.login`/`register`
/// 在成功认证后调用；[deregisterForUser] 由 `AuthProvider.logout` 在
/// 清除本地凭证*之前*调用（此时 JWT 仍在 Authorization 头中）。
class PushService {
  PushService();

  final JPushFlutterInterface _jpush = JPush.newJPush();

  /// 在 [setup] 成功运行于底层插件后为 true。
  bool _initialized = false;

  /// 缓存的注册ID — 在 SDK 报告之前为 null（通常在 [setup] 后
  /// 几秒内获取）。持久化到 `SharedPreferences`，以便令牌在应用
  /// 重启后仍然存在，并可在下次 `logout()` 时注销，即使 SDK 尚未
  /// 完成初始化。
  String? _registrationId;
  String? get registrationId => _registrationId;

  /// 一次性完成器，UI 可等待以了解设备是否已准备好接收推送。
  /// 当极光推送不支持（Web/桌面）或 `setup` 失败时立即完成，
  /// 以便调用者永远不会阻塞。
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  /// 点击处理流。发送被点击通知的 `extras` 映射 —— 服务端围栏告警
  /// 推送携带 `{"type": "fence_alarm", "alarmId": "..."}`，导航器
  /// 监听器使用它来深度链接到 `FenceAlarmScreen`。
  final _onTapController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTap => _onTapController.stream;

  /// 在 SDK 返回 registrationId 之前调用 [registerForUser] 时设置，
  /// 以便 [_refreshRegistrationId] 在实际获取到 ID 后重试 §2.7.1 调用，
  /// 而不是让该登录/注册的注册操作悄无声息地永不发生。
  AuthUser? _pendingRegisterUser;

  static const _prefKeyRegistrationId = 'jpush_registration_id';

  /// 初始化极光推送 SDK。幂等操作 —— 多次调用无效果。
  /// 在不支持极光推送的平台（Web、桌面）上立即返回，不会抛出异常。
  Future<void> setup({required bool production}) async {
    if (_initialized) return;
    if (!_isSupportedPlatform) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    try {
      // `appKey` 从原生清单占位符（Android）/ Info.plist（iOS）读取
      // 在插件层面 —— 此处传入空字符串让 SDK 读取其内置密钥。
      _jpush.setup(
        appKey: '',
        production: production,
        channel: 'developer-default',
        debug: !production,
      );
      _jpush.addEventHandler(
        // 收到通知调用
        onReceiveNotification: (event) async {
          debugPrint('JPush onReceiveNotification: $event');
        },

        // 打开通知调用
        onOpenNotification: (event) async {
          final extras = _extractExtras(event);
          if (extras != null) _onTapController.add(extras);
        },

        //
        onReceiveMessage: (event) async {
          final extras = _extractExtras(event);
          if (extras != null) _onTapController.add(extras);
        },

        // 成功连接到
        onConnected: (_) async {
          await _refreshRegistrationId();
        },
      );
      // 在 Android 13+ / iOS 上请求运行时权限 —— 没有此操作，
      // 通知将静默触发（无系统托盘横幅）。插件的 `applyPushAuthority`
      // 接受单个 `NotificationSettingsIOS` 形状并应用于两个平台
      //（Android 复用相同类型用于声音/提醒/角标）。
      try {
        _jpush.applyPushAuthority(
          const NotificationSettingsIOS(
            sound: true,
            alert: true,
            badge: true,
          ),
        );
      } catch (e) {
        debugPrint('JPush applyPushAuthority failed: $e');
      }
      await _refreshRegistrationId();
      _initialized = true;
      if (!_ready.isCompleted) _ready.complete();
    } catch (e) {
      debugPrint('JPush setup failed: $e');
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// 从 SDK 获取注册 ID 并缓存（内存和 `SharedPreferences` 中）。
  /// 如果极光推送尚未就绪则返回 null —— 下一个 `onConnected` 事件
  /// 将触发重新获取。根据极光文档，当清单占位符缺失时，Android 上
  /// ID 可能为字符串 `"null"`；我们过滤掉该值，以免服务器接收到它。
  Future<String?> _refreshRegistrationId() async {
    if (!_isSupportedPlatform) return null;
    try {
      final id = await _jpush.getRegistrationID();
      if (id.isEmpty || id == 'null') return null;
      _registrationId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRegistrationId, id);
      // 在 SDK 尚未获取 registrationId 时（冷启动 + 快速登录/注册，
      // 原生极光推送握手仍在进行中）调用的 `registerForUser` 会存放到
      // `_pendingRegisterUser` 中，而不是让 §2.7.1 调用永远静默丢失。
      // 现在 ID 终于存在了，重试该调用。
      final pending = _pendingRegisterUser;
      if (pending != null) {
        _pendingRegisterUser = null;
        unawaited(registerForUser(pending));
      }
      return id;
    } catch (e) {
      debugPrint('JPush getRegistrationID failed: $e');
      return null;
    }
  }

  /// 将之前持久化的注册 ID（如果有）加载到内存中。在应用启动时调用，
  /// 以便在进程被杀死后执行 `logout()` 时，即使极光推送尚未完成重连，
  /// 仍然可以注销。
  Future<void> restoreCachedRegistrationId() async {
    if (!_isSupportedPlatform) return;
    final prefs = await SharedPreferences.getInstance();
    _registrationId = prefs.getString(_prefKeyRegistrationId);
  }

  /// `POST /users/push-token`（§2.7.1）。尽力而为 —— 认证流程不阻塞
  /// 推送注册，此处失败仅记录日志但不会暴露给 UI（用户已登录并使用应用）。
  /// 使用用户当前的 JWT 作为 Bearer 令牌 —— 该调用必须在获取到 JWT
  /// *之后*进行，而非之前。
  Future<void> registerForUser(AuthUser user) async {
    if (!_isSupportedPlatform) return;
    if (AppConfig.mockMode) return;
    final id = _registrationId;
    if (id == null) {
      // 冷启动时常见情况：登录/注册可能在极光推送自身的异步握手
      // 产生 registrationId 之前完成。暂存用户，以便 `_refreshRegistrationId`
      // 在 ID 出现时立即重试此调用，而不是让设备在此会话中从未注册。
      _pendingRegisterUser = user;
      debugPrint(
          'JPush registerForUser: no registrationId yet, will retry once available');
      return;
    }
    _pendingRegisterUser = null;
    try {
      final resp = await http
          .post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/push-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'registrationId': id,
          'platform': _platformName,
        }),
      )
          .timeout(const Duration(seconds: 10));
      ApiClient.unwrap(resp);
    } catch (e) {
      debugPrint('JPush registerForUser failed: $e');
    }
  }

  /// `DELETE /users/push-token`（§2.7.2）。在清除本地凭证*之前*调用，
  /// 以便 JWT 对此单次请求仍然有效。容忍网络故障（即使无法到达服务器，
  /// 登出也必须继续）。
  Future<void> deregisterForUser(AuthUser user) async {
    if (!_isSupportedPlatform) return;
    if (AppConfig.mockMode) return;
    final id = _registrationId;
    if (id == null) return;
    try {
      final resp = await http
          .delete(
        Uri.parse('${AppConfig.apiBaseUrl}/users/push-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({'registrationId': id}),
      )
          .timeout(const Duration(seconds: 10));
      ApiClient.unwrap(resp);
    } catch (e) {
      debugPrint('JPush deregisterForUser failed: $e');
    }
    _registrationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRegistrationId);
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'unknown';
  }

  Map<String, dynamic>? _extractExtras(dynamic event) {
    if (event is! Map) return null;
    final raw = event['extras'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}