import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'core/brand_colors.dart';
import 'core/home_widgets.dart';
import 'core/tab_visibility.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/health_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/location_provider.dart';
import 'providers/moment_provider.dart';
import 'providers/theme_provider.dart';
import 'services/chat_service.dart';
import 'services/health_service.dart';
import 'services/location_service.dart';
import 'services/moment_service.dart';
import 'services/push_notification_router.dart';
import 'services/push_service.dart';
import 'services/websocket_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat/conversation_list_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/family_feed_screen.dart';
import 'screens/my_home_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  final pushService = PushService();
  // Kick off JPush setup in parallel with theme/locale restore. The
  // service is no-op on web/desktop, so this is cheap regardless.
  unawaited(pushService.restoreCachedRegistrationId());
  unawaited(pushService.setup(production: !AppConfig.mockMode));
  await Future.wait([localeProvider.restore(), themeProvider.restore()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(push: pushService)),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const SweetHomeApp(),
    ),
  );
}

/// Shared navigator key for deep-link handling from outside the
/// widget tree (notification taps, JPush callback fires). Held at
/// file scope so [PushNotificationRouter] can resolve it without a
/// BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

class SweetHomeApp extends StatelessWidget {
  const SweetHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    // Watching (not reading) subscribes this widget to every
    // `ThemeProvider.notifyListeners()` call — including the ones
    // `didChangePlatformBrightness` fires while following "system".
    // `AppColors.isDark` is kept in sync with this same provider (see
    // `ThemeProvider`/`AppColors.applyBrightness`) before any of those
    // notifications fire, so it's always current by the time this
    // widget rebuilds.
    final palette = context.watch<ThemeProvider>().palette;
    return MaterialApp(
      title: 'Sweet Home',
      theme: AppTheme.build(palette, isDark: AppColors.isDark),
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  PushNotificationRouter? _pushRouter;

  /// Tracks the previous `isAuthenticated` value across rebuilds so a
  /// true→false transition (session expired — `AuthProvider.logout()`
  /// called from the reactive-401 path, the periodic proactive refresh,
  /// or the profile screen's own logout button) can be told apart from
  /// "was already logged out" or "just logged in". Starts false: at
  /// `initState` the provider hasn't finished `_restoreSession()` yet
  /// (`isLoading` is true, `currentUser` is still null), so the very
  /// first real value is never a false→false no-op read as a login.
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Wire the JPush tap router to the same PushService the
    // AuthProvider owns. Listens for the entire app lifetime —
    // taps arriving during the unauthenticated splash window are
    // parked until `flushPending()` runs from `didChangeDependencies`
    // below once auth resolves.
    final push = context.read<AuthProvider>().pushService;
    if (push != null) {
      _pushRouter = PushNotificationRouter(
        onTap: push.onTap,
        tokenProvider: () {
          final user = context.read<AuthProvider>().currentUser;
          return user?.token;
        },
        isAuthenticated: () => context.read<AuthProvider>().isAuthenticated,
      )..start();
    }
  }

  @override
  void dispose() {
    _pushRouter?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        // After every rebuild triggered by auth state changing
        // (login completes, restore-from-cache finishes), flush
        // any push tap that arrived during the unauthenticated
        // window. Idempotent — flushPending is a no-op if nothing
        // is pending.
        if (auth.isAuthenticated) _pushRouter?.flushPending();
        // A session that just ended (true→false) can leave screens
        // pushed on top of this route (a chat room, an open dialog,
        // several levels of `Navigator.push`) — swapping *this*
        // widget for `LoginScreen` below only changes what the base
        // route renders, it doesn't clear whatever's stacked above
        // it, so the user would still be staring at the old screen.
        // Pop everything back to that base route so the login screen
        // this build is about to return is actually what's on screen.
        if (_wasAuthenticated && !auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
          });
        }
        _wasAuthenticated = auth.isAuthenticated;
        if (auth.isLoading) return const _SplashScreen();
        if (auth.isAuthenticated) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => ChatProvider(
                  ws: AppConfig.mockMode
                      ? MockWebSocketService()
                      : WebSocketService(
                          tokenProvider: () => auth.currentUser!.token,
                        ),
                  chatService: ChatService(() => auth.currentUser!.token),
                  currentUser: auth.currentUser!,
                  onUnauthorized: auth.handleUnauthorized,
                )..loadConversations(),
              ),
              // App-scoped (not screen-scoped) so the §6.1 sharing
              // toggle/timer survives navigating away from and back
              // to LocationScreen — previously LocationScreen owned
              // and disposed its own LocationProvider on unmount, so
              // reopening the screen always showed sharing as off
              // even if the user had just turned it on. Lives exactly
              // as long as ChatProvider (created on login, torn down
              // on logout via this same subtree leaving/re-entering
              // the widget tree). `restoreSharingState()` also resumes
              // sharing across a full app restart (not just navigation)
              // by reading the on/off flag it persists to
              // SharedPreferences on every toggle.
              ChangeNotifierProvider(
                create: (_) => LocationProvider(
                  service: LocationService(() => auth.currentUser!.token),
                  mockMode: AppConfig.mockMode,
                )..restoreSharingState(),
              ),
              // Family-feed state (§7). Lives in the same auth-gated
              // scope as ChatProvider / LocationProvider so a logout
              // tears it down and a fresh login starts with a clean
              // feed; `loadInitial()` runs eagerly to fill the first
              // page before the user taps the Family Feed tab.
              ChangeNotifierProvider(
                create: (_) => MomentProvider(
                  currentUser: auth.currentUser!,
                  service: MomentService(
                      () => auth.currentUser!.token),
                )..loadInitial(),
              ),
              ChangeNotifierProvider(
                create: (_) => HealthProvider(
                  service: HealthService(() => auth.currentUser!.token),
                  mockMode: AppConfig.mockMode,
                )..loadInitial(),
              ),
            ],
            child: const MainShell(),
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 5 tab indices, laid out as
  //   [0] Messages     [1] Contacts    [2] MyHome (raised center)
  //   [3] FamilyFeed   [4] Profile
  // _kMyHomeIndex is the center slot — the nav row leaves a gap for
  // it and the raised FAB sits on top of that gap.
  static const int _kMyHomeIndex = 2;
  static const int _kProfileIndex = 4;

  int _currentIndex = 0;

  /// Drives the cross-finger swipe between tabs. `PageView` is used
  /// instead of `IndexedStack` so left/right drag swipes between
  /// screens, while `PageView(children: ...)` (as opposed to
  /// `.builder`) keeps every page mounted off-screen the way
  /// `IndexedStack` did — so a tab's scroll position / map camera /
  /// in-progress upload cycle survives a swipe-away-and-back.
  final PageController _pageController = PageController();

  /// Page widgets are built per-build (instead of `static const`)
  /// because [FamilyFeedScreen] needs two callbacks that close over
  /// `_pageController` so it can hand off its boundary horizontal
  /// swipes ("自个儿家 right-fling → MyHome", "串串门 left-fling →
  /// Profile") back to this outer PageView. The other four children
  /// are const-constructed the same way they used to be — they live
  /// in the same list so the index↔tab mapping (0 Messages,
  /// 1 Contacts, 2 MyHome, 3 FamilyFeed, 4 Profile) stays put.
  List<Widget> get _screens => [
        const ConversationListScreen(),
        const ContactsScreen(),
        const MyHomeScreen(),
        FamilyFeedScreen(
          // Right-drag from 自个儿家 → animate the outer PageView to
          // the MyHome slot (index _kMyHomeIndex = 2).
          onSwipeToPrevPage: () => _goTo(_kMyHomeIndex),
          // Left-drag from 串串门 → animate the outer PageView to
          // the Profile slot (last tab).
          onSwipeToNextPage: () => _goTo(_kProfileIndex),
        ),
        const ProfileScreen(),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Switch tabs from code (FAB tap or nav-bar tap). Updates the
  /// reactive `_currentIndex` so the nav highlights follow, and
  /// animates the PageView to the same index so a tap looks like
  /// a swipe. `onPageChanged` will fire again from the animation
  /// and re-set `_currentIndex` — same value, so this is just a
  /// double-setState no-op for the index.
  void _goTo(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: PageView is mounted in place of IndexedStack — drag
      // left/right anywhere on a tab body to switch tabs. PageView's
      // internal horizontal gesture wins on bare body areas;
      // per-screen scrollables (vertical ListView, the map's
      // pan handler) still consume their own gestures normally
      // because Flutter's gesture arena resolves conflicts per
      // pointer-down.
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        // Each page wrapped in its own `TabVisibility` so widgets that
        // own playback (family-feed inline video/audio tiles) can tell
        // "off-screen because another tab is selected" apart from
        // "on-screen" and pause accordingly — see tab_visibility.dart.
        // Rebuilding this list on every `_currentIndex` change is
        // cheap and doesn't disturb the underlying screens' State: same
        // widget type + implicit index-based key at each position, so
        // Flutter keeps reusing the same Elements.
        children: [
          for (var i = 0; i < _screens.length; i++)
            TabVisibility(visible: i == _currentIndex, child: _screens[i]),
        ],
      ),
      // bottomNavigationBar is the visible bar with 4 regular tabs;
      // the raised MyHome button is overlaid on top of it via
      // floatingActionButtonLocation.centerDocked. FAB sits *above*
      // the bar's top edge (negative offset), giving the WeChat /
      // TikTok-style "raised center" look.
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _buildCenterFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCenterFab() {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _currentIndex == _kMyHomeIndex;
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        // `centerDocked` leaves the FAB half-inside the bar; nudge
        // it up so the circle sits clearly above the bar line.
        onPressed: () => _goTo(_kMyHomeIndex),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        tooltip: l10n.navMyHome,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [context.brandPrimary, context.brandPrimaryDark]
                  : [context.brandAccent, context.brandPrimary],
            ),
            border: Border.all(color: AppColors.linen, width: 3),
            boxShadow: [
              BoxShadow(
                color: context.brandPrimaryDark.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.cottage_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  /// A wooden tray at the bottom of the screen — the "shelf" the
  /// rest of the app is sitting on. Grain tone follows the active
  /// theme (`primaryDark`) rather than a fixed brown, so switching
  /// palettes recolors the shelf along with everything else. White
  /// labels, accent highlight bar under the active tab.
  Widget _buildNavBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          // Soft inner highlight on the top edge so the bar reads
          // as a wooden plank with a chamfered lip, not a flat
          // strip.
          const BoxShadow(
            color: Color(0x33FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: l10n.navMessages,
                  isSelected: _currentIndex == 0,
                  onTap: () => _goTo(0),
                  badgeCount: _getUnreadCount(),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.people_alt_outlined,
                  activeIcon: Icons.people_alt_rounded,
                  label: l10n.navContacts,
                  isSelected: _currentIndex == 1,
                  onTap: () => _goTo(1),
                ),
              ),
              // Notch for the raised center FAB.
              const SizedBox(width: 64),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.timeline_outlined,
                  activeIcon: Icons.timeline_rounded,
                  label: l10n.navFamilyFeed,
                  isSelected: _currentIndex == 3,
                  onTap: () => _goTo(3),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: l10n.navProfile,
                  isSelected: _currentIndex == 4,
                  onTap: () => _goTo(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getUnreadCount() {
    try {
      // `watch`, not `read` — the nav bar's badge count (and the
      // shake it drives on the Messages icon) needs to update the
      // moment a message arrives or gets read, not just whenever
      // `_MainShellState` happens to rebuild for some other reason.
      final chat = context.watch<ChatProvider>();
      return chat.conversations.fold(0, (sum, c) => sum + c.unreadCount);
    } catch (_) {
      return 0;
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final fg = isSelected ? Colors.white : const Color(0xCCEFE0D0);
    return InkWell(
      onTap: onTap,
      highlightColor: Colors.transparent,
      splashColor: context.brandAccent.withValues(alpha: 0.18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _ShakingIcon(
                  shaking: badgeCount > 0,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: fg,
                    size: 23,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.brandAccent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primaryDark, width: 1.4),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: fg,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          // Active-tab indicator: a small terracotta pill under the
          // label — the same color as the FAB so the two feel like
          // the same control.
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 2.5,
            width: isSelected ? 18 : 0,
            decoration: BoxDecoration(
              color: context.brandAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a nav-bar icon with a periodic "cute" wiggle whenever
/// [shaking] is true (i.e. there's something unread) — a quick
/// few-degree rock left-right-left, then a pause, on repeat. Stops
/// and snaps back to upright the moment [shaking] flips to false
/// (the badge clears once everything's read).
class _ShakingIcon extends StatefulWidget {
  final bool shaking;
  final Widget child;
  const _ShakingIcon({required this.shaking, required this.child});

  @override
  State<_ShakingIcon> createState() => _ShakingIconState();
}

class _ShakingIconState extends State<_ShakingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  // One full period: hold upright, rock through a few quick swings,
  // then hold upright again for a beat before the next repeat —
  // reads as a little "psst, look at me" nudge rather than a
  // constant nervous twitch.
  late final Animation<double> _angle = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: -0.16).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 6,
    ),
    TweenSequenceItem(
      tween: Tween(begin: -0.16, end: 0.16).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.16, end: -0.10).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 9,
    ),
    TweenSequenceItem(
      tween: Tween(begin: -0.10, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 5,
    ),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    if (widget.shaking) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _ShakingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shaking && !oldWidget.shaking) {
      _controller.repeat();
    } else if (!widget.shaking && oldWidget.shaking) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      child: widget.child,
      builder: (context, child) => Transform.rotate(
        angle: _angle.value,
        child: child,
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: PaperBackground(child: SizedBox.shrink())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.linen,
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cottage_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.brandName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
