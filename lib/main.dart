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
  int _currentIndex = 0;

  static const _screens = [
    ConversationListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
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
      child: SafeArea(
        child: SizedBox(
          height: 60,
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
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: l10n.navProfile,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
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
