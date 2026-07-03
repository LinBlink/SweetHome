import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sweethome_flutter/data/mock_data.dart';
import 'package:sweethome_flutter/l10n/app_localizations.dart';
import 'package:sweethome_flutter/models/chat_models.dart';
import 'package:sweethome_flutter/providers/auth_provider.dart';
import 'package:sweethome_flutter/providers/chat_provider.dart';
import 'package:sweethome_flutter/providers/locale_provider.dart';
import 'package:sweethome_flutter/screens/chat/chat_room_screen.dart';
import 'package:sweethome_flutter/screens/chat/new_conversation_screen.dart';
import 'package:sweethome_flutter/services/chat_service.dart';
import 'package:sweethome_flutter/services/websocket_service.dart';

// A WebSocket stand-in with no background timers, so the test has no pending
// timers to trip the flutter_test teardown.
class _NoopWs extends WebSocketService {
  final _c = StreamController<WsInboundMessage>.broadcast();
  @override
  Stream<WsInboundMessage> get stream => _c.stream;
  @override
  void connect(String token) {}
  @override
  void send(WsOutboundMessage msg) {}
  @override
  void disconnect() {
    if (!_c.isClosed) _c.close();
  }
}

// Run with: flutter test --dart-define=MOCK_MODE=true test/new_conversation_flow_test.dart
void main() {
  testWidgets('tapping a member navigates into the chat room', (tester) async {
    final chat = ChatProvider(
      ws: _NoopWs(),
      chatService: ChatService(() => MockDataSource.mockUser.token),
      currentUser: MockDataSource.mockUser,
    );
    await chat.loadConversations();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Mirror how the app pushes NewConversationScreen: the route
          // re-provides ChatProvider below the root Navigator.
          home: ChangeNotifierProvider.value(
            value: chat,
            child: const NewConversationScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The member list should render (excludes the logged-in mock user).
    expect(find.text('张美玲'), findsOneWidget);
    expect(find.byType(ChatRoomScreen), findsNothing);

    await tester.tap(find.text('张美玲'));
    // Don't pumpAndSettle: the chat room shows a perpetual loading spinner,
    // which never settles. Pump a fixed span long enough for the mock
    // startDirectConversation (300ms) + loadMessages (300ms) to complete.
    await tester.pump(); // process the tap
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ChatRoomScreen), findsOneWidget);
    // The app bar shows the target member's name.
    expect(find.text('张美玲'), findsWidgets);
  });
}
