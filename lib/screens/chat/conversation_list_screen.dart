import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/error_messages.dart';
import '../../core/home_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/conversation_tile.dart';
import '../../widgets/error_banner.dart';
import 'chat_room_screen.dart';

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
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(
        title: l10n.navMessages,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
            tooltip: l10n.conversationsSearchTooltip,
          ),
        ],
      ),
      body: PaperBackground(
        child: Consumer<ChatProvider>(
          builder: (ctx, chat, _) {
            Widget body = _buildBody(ctx, chat, l10n);
            if (chat.connectionError != null) {
              body = _ConnectionErrorBanner(
                // `connectionError` is a sentinel/code, not
                // pre-localized text — `localizeErrorMessage`
                // is what maps it to the active locale's
                // display string.
                message: localizeErrorMessage(
                  chat.connectionError!,
                  l10n,
                ),
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
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      itemCount: chat.conversations.length,
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

/// Small circular "compose" button in the app bar — a paper-craft
/// stamp, not the default Material + icon.
class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.linen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.forum_rounded,
                size: 44,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.conversationsEmptyTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.conversationsEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkFaded,
                height: 1.5,
              ),
            ),
          ],
        ),
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
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            border: Border(
              bottom: BorderSide(
                color: AppColors.warning.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 28),
                ),
                child: Text(
                  retryLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  color: AppColors.inkFaded,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
