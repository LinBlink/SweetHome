import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/error_messages.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String conversationName;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.conversationName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final canSend = _textCtrl.text.trim().isNotEmpty;
      if (canSend != _canSend) setState(() => _canSend = canSend);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      chat.loadMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _canSend = false);
    await context.read<ChatProvider>().sendMessage(widget.conversationId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      context.read<ChatProvider>().loadMessages(
            widget.conversationId,
            loadMore: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversationName),
            Consumer<ChatProvider>(
              builder: (context, chat, child) {
                final count = chat.messagesFor(widget.conversationId).length;
                return Text(
                  count > 0 ? l10n.chatRoomMessageCount(count) : l10n.chatRoomDefaultSubtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                );
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: l10n.chatRoomMoreTooltip,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<ChatProvider>(
            builder: (ctx, chat, _) {
              if (chat.error == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.all(12),
                child: ErrorBanner(
                  message: localizeErrorMessage(chat.error!, l10n),
                  onDismiss: chat.clearError,
                ),
              );
            },
          ),
          Expanded(child: _buildMessageList(l10n)),
          _buildInputBar(l10n),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppLocalizations l10n) {
    return Consumer<ChatProvider>(
      builder: (ctx, chat, _) {
        final messages = chat.messagesFor(widget.conversationId);
        if (chat.isLoadingMessages(widget.conversationId) && messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (messages.isEmpty) {
          return Center(
            child: Text(
              l10n.chatRoomEmptyHint,
              style: const TextStyle(color: AppColors.textHint),
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification) _onScroll();
            return false;
          },
          child: ListView.builder(
            controller: _scrollCtrl,
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: messages.length +
                (chat.isLoadingMessages(widget.conversationId) ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == messages.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                );
              }
              // Convention: messages are stored ASC (oldest first, newest
              // last). With reverse: true, item i=0 paints at the visual
              // bottom — so the list's last element (newest) sits there.
              final msg = messages[messages.length - 1 - i];
              return MessageBubble(message: msg);
            },
          ),
        );
      },
    );
  }

  Widget _buildInputBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        // Note: do NOT add `MediaQuery.of(context).viewInsets.bottom`
        // here. `Scaffold.resizeToAvoidBottomInset` is `true` by
        // default and already resizes the body so the input bar sits
        // just above the soft keyboard. Adding the keyboard height
        // again as bottom padding double-resizes the body on Android,
        // shoving the input bar toward the top of the screen and
        // crushing the message list. `MediaQuery.padding.bottom`
        // (system gesture inset) is the only extra inset worth adding.
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {},
            tooltip: l10n.chatRoomMoreOption,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.chatRoomInputHint,
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _canSend
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('emoji'),
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
          ),
        ],
      ),
    );
  }
}
