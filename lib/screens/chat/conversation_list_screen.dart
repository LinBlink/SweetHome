import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/conversation_tile.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: '搜索',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
            tooltip: '新建对话',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (ctx, chat, _) {
          if (chat.connectionError != null) {
            return _ConnectionErrorBanner(
              message: chat.connectionError!,
              onRetry: chat.reconnect,
              onDismiss: chat.dismissConnectionError,
              child: _buildBody(ctx, chat),
            );
          }
          return _buildBody(ctx, chat);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatProvider chat) {
    if (chat.isLoadingConversations) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (chat.conversations.isEmpty) {
      return _EmptyState();
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 72, color: AppColors.primaryLight.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          const Text(
            '还没有消息',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '邀请家人加入，开始聊天吧',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _ConnectionErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  final Widget child;

  const _ConnectionErrorBanner({
    required this.message,
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
                child: const Text('重试',
                    style: TextStyle(
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
