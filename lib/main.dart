import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'core/home_widgets.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/location_provider.dart';
import 'services/chat_service.dart';
import 'services/location_service.dart';
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
  await localeProvider.restore();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const SweetHomeApp(),
    ),
  );
}

class SweetHomeApp extends StatelessWidget {
  const SweetHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      title: 'Sweet Home',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
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

  int _currentIndex = 0;

  /// Drives the cross-finger swipe between tabs. `PageView` is used
  /// instead of `IndexedStack` so left/right drag swipes between
  /// screens, while `PageView(children: ...)` (as opposed to
  /// `.builder`) keeps every page mounted off-screen the way
  /// `IndexedStack` did — so a tab's scroll position / map camera /
  /// in-progress upload cycle survives a swipe-away-and-back.
  final PageController _pageController = PageController();

  static const _screens = [
    ConversationListScreen(),
    ContactsScreen(),
    MyHomeScreen(),
    FamilyFeedScreen(),
    ProfileScreen(),
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
        children: _screens,
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
                  ? [AppColors.primary, AppColors.primaryDark]
                  : [AppColors.accent, AppColors.primary],
            ),
            border: Border.all(color: AppColors.linen, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
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
  /// rest of the app is sitting on. Dark wood grain, white
  /// labels, terracotta highlight bar under the active tab.
  Widget _buildNavBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.wood,
        boxShadow: [
          // Soft inner highlight on the top edge so the bar reads
          // as a wooden plank with a chamfered lip, not a flat
          // strip.
          BoxShadow(
            color: Color(0x33FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, -2),
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
      final chat = context.read<ChatProvider>();
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
      splashColor: AppColors.accent.withValues(alpha: 0.18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: fg,
                  size: 23,
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
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.wood, width: 1.4),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: AppColors.wood,
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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
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
                    gradient: const LinearGradient(
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
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
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
