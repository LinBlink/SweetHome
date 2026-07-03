import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/error_messages.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/conversation_tile.dart';
import '../../widgets/error_banner.dart';
import 'chat_room_screen.dart';
import 'new_conversation_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.navMessages),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: l10n.conversationsSearchTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // ChatProvider lives below the root Navigator (created in
              // AuthGate), so a pushed route can't inherit it — re-provide it
              // explicitly, same as the ChatRoomScreen navigation below.
              final chat = context.read<ChatProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: chat,
                    child: const NewConversationScreen(),
                  ),
                ),
              );
            },
            tooltip: l10n.conversationsNewTooltip,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (ctx, chat, _) {
          Widget body = _buildBody(ctx, chat, l10n);
          if (chat.connectionError != null) {
            body = _ConnectionErrorBanner(
              message: chat.connectionError!,
              retryLabel: l10n.connectionErrorRetry,
              onRetry: chat.reconnect,
              onDismiss: chat.dismissConnectionError,
              child: body,
            );
          }
          if (chat.error != null) {
            body = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ErrorBanner(
                    message: localizeErrorMessage(chat.error!, l10n),
                    onDismiss: chat.clearError,
                  ),
                ),
                Expanded(child: body),
              ],
            );
          }
          return body;
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatProvider chat, AppLocalizations l10n) {
    if (chat.isLoadingConversations) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (chat.conversations.isEmpty) {
      return _EmptyState(l10n: l10n);
    }
    return ListView.separated(
      itemCount: chat.conversations.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 70,
        endIndent: 0,
      ),
      itemBuilder: (ctx, i) {
        final conv = chat.conversations[i];
        return ConversationTile(
          conversation: conv,
          onTap: () {
            chat.setActiveConversation(conv.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: chat,
                  child: ChatRoomScreen(
                    conversationId: conv.id,
                    conversationName: conv.name,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 72, color: AppColors.primaryLight.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            l10n.conversationsEmptyTitle,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.conversationsEmptySubtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _ConnectionErrorBanner extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  final Widget child;

  const _ConnectionErrorBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.warning.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary)),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 28)),
                child: Text(retryLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 16),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
