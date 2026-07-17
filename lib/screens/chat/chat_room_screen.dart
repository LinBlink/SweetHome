import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/error_messages.dart';
import '../../core/home_widgets.dart';
import '../../core/image_mime.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_exception.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/emoji_picker.dart';
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
  final _textFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;
  bool _uploadingImage = false;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final canSend = _textCtrl.text.trim().isNotEmpty;
      if (canSend != _canSend) setState(() => _canSend = canSend);
    });
    // Hide the emoji picker as soon as the user focuses the text
    // field (which brings the soft keyboard up). Without this, the
    // picker would double-stack under the keyboard.
    _textFocus.addListener(() {
      if (_textFocus.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      chat.loadMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    // So a `NEW_MESSAGE` pushed for this conversation after the user
    // navigates away doesn't get auto-marked read by ChatProvider — see
    // ChatProvider.clearActiveConversation.
    context.read<ChatProvider>().clearActiveConversation(widget.conversationId);
    _textCtrl.dispose();
    _textFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    // §4.4 server validation rejects > 2000 chars with
    // `MESSAGE_TOO_LONG`; gate locally too so the user gets a
    // localized snack instead of an opaque server message.
    if (text.length > 2000) {
      _showSnack(AppLocalizations.of(context)!.chatMessageTooLong);
      return;
    }
    _textCtrl.clear();
    setState(() => _canSend = false);
    await context.read<ChatProvider>().sendMessage(widget.conversationId, text);
    if (!mounted) return;
    _scrollToBottom();
  }

  /// Image-send path. The picker feeds us bytes which the provider
  /// uploads via `POST /users/upload/image` (§2.4) and then sends as
  /// a message via §4.4 (REST) or §5.2 (WS) with `type = "image"` and
  /// `content = <r2-url>`. Disables the picker while an upload is in
  /// flight so the user can't double-tap and queue two uploads for
  /// the same conversation.
  Future<void> _pickAndSendImage() async {
    if (_uploadingImage) return;
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.chatRoomImageUploadFailed);
      return;
    }
    if (picked == null) return; // user cancelled
    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final contentType =
          detectImageMimeType(bytes) ?? picked.mimeType ?? 'image/jpeg';
      final messenger = ScaffoldMessenger.of(context);
      final ok = await context.read<ChatProvider>().sendImageMessage(
            widget.conversationId,
            bytes: bytes,
            filename: picked.name,
            contentType: contentType,
          );
      if (!mounted) return;
      if (ok) {
        _scrollToBottom();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatRoomImageUploadFailed)),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(localizeErrorMessage(e.message, l10n));
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.chatRoomImageUploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Cursor-aware emoji insertion. Replaces any selected text with
  /// [emoji] and drops the caret just after the inserted character
  /// so consecutive taps append without losing position. Emoji are
  /// surrogate pairs in Dart's UTF-16 String — `replaceRange` /
  /// index arithmetic work correctly because we never split a
  /// pair: we always insert a complete grapheme sequence from the
  /// curated list, and use `selection.baseOffset` /
  /// `selection.extentOffset` (which Flutter already exposes in
  /// UTF-16 code units).
  void _insertEmoji(String emoji) {
    final value = _textCtrl.value;
    final text = value.text;
    final start = value.selection.start.clamp(0, text.length);
    final end = value.selection.end.clamp(0, text.length);
    final newText = text.replaceRange(start, end, emoji);
    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _toggleEmojiPicker() {
    final wasShown = _showEmoji;
    setState(() => _showEmoji = !_showEmoji);
    if (!wasShown) {
      // Hide the soft keyboard so the emoji picker doesn't stack
      // underneath it. The user can re-focus by tapping the input.
      _textFocus.unfocus();
    }
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
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(
        title: widget.conversationName,
        subtitle: Consumer<ChatProvider>(
          builder: (context, chat, child) {
            final count = chat.messagesFor(widget.conversationId).length;
            final text = count > 0
                ? l10n.chatRoomMessageCount(count)
                : l10n.chatRoomDefaultSubtitle;
            return Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.inkFaded,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: l10n.chatRoomMoreTooltip,
            onPressed: () {},
          ),
        ],
      ),
      body: PaperBackground(
        child: Column(
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
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: _showEmoji
                ? EmojiPicker(onEmojiSelected: _insertEmoji)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
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
          // "+" image picker — replaces the old placeholder "More"
          // button. While an upload is in flight we swap to a small
          // spinner so the user sees the action was picked up.
          _uploadingImage
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  onPressed: _pickAndSendImage,
                  tooltip: l10n.chatRoomSendImageTooltip,
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
                focusNode: _textFocus,
                maxLines: null,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.chatRoomInputHint,
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  counterText: '',
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
                    icon: Icon(
                      _showEmoji
                          ? Icons.keyboard_alt_outlined
                          : Icons.emoji_emotions_outlined,
                      color: _showEmoji
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    tooltip: _showEmoji
                        ? l10n.chatRoomKeyboardTooltip
                        : l10n.chatRoomEmojiTooltip,
                    onPressed: _toggleEmojiPicker,
                  ),
          ),
        ],
      ),
    );
  }
}
