import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/locale_provider.dart';
import 'services/chat_service.dart';
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
      title: '过家家 · Sweet Home',
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
          return ChangeNotifierProvider(
            create: (_) => ChatProvider(
              ws: AppConfig.mockMode
                  ? MockWebSocketService()
                  : WebSocketService(),
              chatService: ChatService(() => auth.currentUser!.token),
              currentUser: auth.currentUser!,
              onUnauthorized: () async {
                final ok = await auth.refreshSession();
                if (!ok) await auth.logout();
                return ok;
              },
            )..loadConversations(),
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

  static const _screens = [
    ConversationListScreen(),
    ContactsScreen(),
    MyHomeScreen(),
    FamilyFeedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
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
      width: 60,
      height: 60,
      child: FloatingActionButton(
        // `centerDocked` leaves the FAB half-inside the bar; nudge
        // it up so the circle sits clearly above the bar line.
        onPressed: () => setState(() => _currentIndex = _kMyHomeIndex),
        backgroundColor:
            isSelected ? AppColors.primaryDark : AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: l10n.navMyHome,
        child: Icon(
          isSelected ? Icons.home_rounded : Icons.home_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // Leave a notch for the raised center button.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: l10n.navMessages,
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  badgeCount: _getUnreadCount(),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.contacts_outlined,
                  activeIcon: Icons.contacts_rounded,
                  label: l10n.navContacts,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              // Empty slot for the raised center FAB.
              const SizedBox(width: 60),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.timeline_outlined,
                  activeIcon: Icons.timeline_rounded,
                  label: l10n.navFamilyFeed,
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: l10n.navProfile,
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('家',
                    style: TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.brandName,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 3)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
