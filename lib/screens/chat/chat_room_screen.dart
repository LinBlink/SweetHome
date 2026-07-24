import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
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
import '../redpacket/send_redpacket_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String conversationName;

  /// The `clientId` of a message to scroll to and briefly highlight
  /// on open — set when this screen is pushed from a chat-search hit
  /// (search only ever matches messages already sitting in
  /// `ChatProvider`'s in-memory cache, so no extra pagination is
  /// needed to find it; see `SearchMessagesScreen._openChat`).
  final String? targetMessageClientId;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.conversationName,
    this.targetMessageClientId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const int _maxVideoBytes = 50 * 1024 * 1024;
  static const _uuid = Uuid();

  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;
  bool _uploadingImage = false;
  bool _uploadingVideo = false;
  bool _showEmoji = false;

  AudioRecorder? _recorder;
  bool _isRecording = false;
  bool _sendingVoice = false;
  int? _recordingStartMs;
  int _recordingElapsedSec = 0;
  Timer? _elapsedTimer;

  /// One `GlobalKey` per message bubble currently built, keyed by
  /// `clientId` — lets `_jumpToMessage` locate a bubble's render
  /// object (via `Scrollable.ensureVisible`) once `ListView.builder`
  /// has actually built it, since a lazy list won't have realized an
  /// off-screen item's Element yet.
  final Map<String, GlobalKey> _bubbleKeys = {};
  String? _highlightClientId;

  /// Captured in [didChangeDependencies] — NOT looked up fresh inside
  /// [dispose]. `context.read<ChatProvider>()` does an ancestor
  /// `InheritedWidget` lookup, which asserts if the element is already
  /// deactivated by the time it runs; when this whole screen and its
  /// `ChatProvider` ancestor get torn down together in the same frame
  /// (e.g. a logout mid-session recreates `ChatProvider`, per
  /// `CLAUDE.md`'s "torn down/recreated on every login/logout cycle"),
  /// `dispose()` running after `deactivate()` hits exactly that "Looking
  /// up a deactivated widget's ancestor is unsafe" assertion. Storing
  /// the reference while the widget is still active sidesteps it
  /// entirely — `ChatProvider` itself isn't `BuildContext`-bound, so
  /// holding onto it is safe.
  ChatProvider? _chatProviderRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProviderRef = context.read<ChatProvider>();
  }

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
      final target = widget.targetMessageClientId;
      if (target != null) _jumpToMessage(target);
    });
  }

  /// Scrolls the (`reverse: true`) message list to the bubble whose
  /// `clientId` is [clientId] and flashes it briefly so the user can
  /// spot it. Two-step because `ListView.builder` only realizes
  /// items near the current viewport: first a coarse `jumpTo` using
  /// an estimated per-bubble extent to force the target's region to
  /// get built, then `Scrollable.ensureVisible` on its now-attached
  /// `GlobalKey` for exact placement (bubbles have variable height,
  /// so the estimate alone would rarely land precisely).
  Future<void> _jumpToMessage(String clientId) async {
    final chat = context.read<ChatProvider>();
    final messages = chat.messagesFor(widget.conversationId);
    final idx = messages.indexWhere((m) => m.clientId == clientId);
    if (idx < 0) return;
    final fromBottom = messages.length - 1 - idx;
    if (!mounted) return;
    setState(() => _highlightClientId = clientId);
    if (_scrollCtrl.hasClients) {
      final estimate = (fromBottom * 78.0)
          .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.jumpTo(estimate);
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final targetContext = _bubbleKeys[clientId]?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _highlightClientId = null);
  }

  @override
  void dispose() {
    // So a `NEW_MESSAGE` pushed for this conversation after the user
    // navigates away doesn't get auto-marked read by ChatProvider — see
    // ChatProvider.clearActiveConversation. Uses the reference captured
    // in `didChangeDependencies`, not a fresh `context.read` — see that
    // field's doc comment for why a fresh lookup here is unsafe.
    _chatProviderRef?.clearActiveConversation(widget.conversationId);
    _textCtrl.dispose();
    _textFocus.dispose();
    _scrollCtrl.dispose();
    _elapsedTimer?.cancel();
    _recorder?.dispose();
    VideoCompress.dispose();
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
  ///
  /// `pickMultiImage` lets the user select several photos at once;
  /// each one becomes its own independent message (own bubble, own
  /// upload, own `clientId`) sent one after another — there's no
  /// "album" message type on the wire (§4.4/§5.2 only ever carry one
  /// `content` URL per message), so a multi-select is just a
  /// shorthand for "send these N images in a row" rather than a
  /// single grouped message.
  Future<void> _pickAndSendImage() async {
    if (_uploadingImage) return;
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.chatRoomImageUploadFailed);
      return;
    }
    if (picked.isEmpty) return; // user cancelled
    setState(() => _uploadingImage = true);
    var anyFailed = false;
    try {
      for (final file in picked) {
        if (!mounted) return;
        try {
          final bytes = await file.readAsBytes();
          if (!mounted) return;
          final contentType =
              detectImageMimeType(bytes) ?? file.mimeType ?? 'image/jpeg';
          final ok = await context.read<ChatProvider>().sendImageMessage(
                widget.conversationId,
                bytes: bytes,
                filename: file.name,
                contentType: contentType,
              );
          if (!ok) anyFailed = true;
        } on ApiException {
          anyFailed = true;
        } catch (_) {
          anyFailed = true;
        }
      }
      if (!mounted) return;
      _scrollToBottom();
      if (anyFailed) {
        _showSnack(l10n.chatRoomImageUploadFailed);
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  /// Video-send path — picks from [source] (camera or gallery),
  /// re-encodes via `video_compress` (same pipeline as the moments
  /// composer) so a phone-camera clip doesn't blow past the §2.5 size
  /// cap, then uploads + sends as a `type = "video"` message.
  Future<void> _pickAndSendVideo(ImageSource source) async {
    if (_uploadingVideo) return;
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    XFile? raw;
    try {
      raw = await picker.pickVideo(source: source);
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.chatRoomVideoUploadFailed);
      return;
    }
    if (raw == null) return; // user cancelled
    setState(() => _uploadingVideo = true);

    // See the matching comment in publish_moment_screen.dart's
    // _pickVideo — `video_compress` wraps a flaky native transcoder;
    // a failure here doesn't mean the video is too large, so fall
    // back to the original file rather than misreporting it as
    // oversized. The timeout keeps a stuck transcode from blocking
    // the send indefinitely.
    File uploadFile = File(raw.path);
    var wasCompressed = false;
    try {
      final info = await VideoCompress.compressVideo(
        raw.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        frameRate: 30,
        includeAudio: true,
      ).timeout(const Duration(seconds: 25));
      if (info?.file != null && await info!.file!.exists()) {
        uploadFile = info.file!;
        wasCompressed = true;
      }
    } catch (_) {
      unawaited(VideoCompress.cancelCompression());
    }

    final size = await uploadFile.length().catchError((_) => 0);
    if (size > _maxVideoBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      if (wasCompressed) {
        try {
          await uploadFile.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _uploadingVideo = false);
      _showSnack(
        wasCompressed
            ? l10n.publishMomentVideoTooLarge(sizeMb)
            : l10n.publishMomentVideoTooLargeRaw(sizeMb),
      );
      return;
    }
    try {
      final bytes = await uploadFile.readAsBytes();
      if (!mounted) return;
      final ok = await context.read<ChatProvider>().sendVideoMessage(
            widget.conversationId,
            bytes: bytes,
            filename: raw.name,
          );
      if (!mounted) return;
      if (ok) {
        _scrollToBottom();
      } else {
        _showSnack(l10n.chatRoomVideoUploadFailed);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(localizeErrorMessage(e.message, l10n));
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.chatRoomVideoUploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  /// Voice-message record/stop toggle — mirrors the moments composer's
  /// recording flow (`record` package, opus @16kHz mono), except a
  /// chat voice message uploads and sends immediately on stop instead
  /// of sitting in a draft list.
  Future<void> _toggleVoiceRecording() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isRecording) {
      _elapsedTimer?.cancel();
      String? stopped;
      try {
        stopped = await _recorder?.stop();
      } catch (e) {
        _toastFromException(e, l10n);
      }
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingStartMs = null;
        _recordingElapsedSec = 0;
      });
      if (stopped == null || stopped.isEmpty) return;
      setState(() => _sendingVoice = true);
      try {
        final file = File(stopped);
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        final ok = await context.read<ChatProvider>().sendVoiceMessage(
              widget.conversationId,
              bytes: bytes,
              filename: stopped.split(Platform.pathSeparator).last,
            );
        if (!mounted) return;
        if (ok) {
          _scrollToBottom();
        } else {
          _showSnack(l10n.chatRoomVoiceUploadFailed);
        }
      } on ApiException catch (e) {
        // Surfaces the actual §2.6 upload error (e.g. `FILE_TYPE_ILLEGAL`,
        // `FILE_SIZE_ILLEGAL`, `EMPTY_FILE`, `401 UNAUTHORIZED`) instead of
        // the generic fallback below — mirrors `_pickAndSendVideo`'s
        // handling, now reachable because `ChatProvider._sendMediaMessage`
        // rethrows instead of swallowing the exception.
        if (!mounted) return;
        _showSnack(localizeErrorMessage(e.message, l10n));
      } catch (_) {
        if (!mounted) return;
        _showSnack(l10n.chatRoomVoiceUploadFailed);
      } finally {
        if (mounted) setState(() => _sendingVoice = false);
      }
      return;
    }
    try {
      final recorder = _recorder ??= AudioRecorder();
      final hasPerm = await recorder.hasPermission();
      if (!hasPerm) {
        _toastFromException(
          Exception(l10n.publishMomentRecordingPermissionBody),
          l10n,
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${_uuid.v4()}.opus';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 32000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingStartMs = DateTime.now().millisecondsSinceEpoch;
        _recordingElapsedSec = 0;
      });
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _elapsedTimer?.cancel();
          return;
        }
        final start = _recordingStartMs;
        if (start == null) return;
        final elapsed = (DateTime.now().millisecondsSinceEpoch - start) ~/ 1000;
        if (elapsed != _recordingElapsedSec) {
          setState(() => _recordingElapsedSec = elapsed);
        }
      });
    } catch (e) {
      _toastFromException(e, l10n);
    }
  }

  void _toastFromException(Object e, AppLocalizations l10n) {
    final msg = e is ApiException ? e.message : e.toString();
    _showSnack(localizeErrorMessage(msg, l10n));
  }

  void _openMediaSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            ListTile(
              leading: Icon(Icons.photo_outlined, color: AppColors.primary),
              title: Text(l10n.chatRoomSendImageTooltip),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam_outlined, color: AppColors.primary),
              title: Text(l10n.chatRoomRecordVideoOption),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library_outlined, color: AppColors.primary),
              title: Text(l10n.chatRoomGalleryVideoOption),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendVideo(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: Icon(Icons.mic_none_rounded, color: AppColors.primary),
                title: Text(l10n.chatRoomVoiceOption),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleVoiceRecording();
                },
              ),
            // §9 red packet — same sheet, same chat-room scope.
            // Per the user's choice the red packet entry point lives
            // *only* on the chat room (not as a separate hub tile for
            // sending); the MyHome "My Redpackets" hub tile is
            // view-only. Available for both group and direct chats —
            // the server enforces `totalCount <= memberCount` and the
            // send form prefills the limit accordingly.
            ListTile(
              leading: Icon(Icons.redeem_rounded, color: AppColors.danger),
              title: Text(l10n.chatRoomRedpacketOption),
              onTap: () {
                Navigator.pop(ctx);
                _openSendRedpacketScreen();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  /// Pushes the §9.1 send form. We pull the conversation's member
  /// count + is-group flag off the chat provider (it's loaded with
  /// every §4.1 conversation); a missing member count is treated as
  /// `2` (the direct-chat minimum) rather than crashing. The
  /// `isGroup` flag drives the share-count field — direct chats force
  /// it to 1 and hide the input entirely.
  Future<void> _openSendRedpacketScreen() async {
    final chat = context.read<ChatProvider>();
    final conv = chat.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => chat.conversations.first,
    );
    final memberCount = conv.memberCount > 0 ? conv.memberCount : 2;
    if (!mounted) return;
    // `ChatProvider` lives in the auth-gated `MultiProvider` built inside
    // `AuthGate`'s own route content, not above the app's single
    // `Navigator` — so a plain `Navigator.push` here would hand
    // `SendRedpacketScreen` a `BuildContext` with no `ChatProvider`
    // ancestor at all (`ProviderNotFoundError` the moment `_submit` calls
    // `context.read<ChatProvider>()`). Every other screen pushed this way
    // that needs `ChatProvider` (`ChatRoomScreen` itself, from
    // `ConversationListScreen`; `SearchMessagesScreen`) re-injects the
    // same instance via `ChangeNotifierProvider.value` for exactly this
    // reason — this was the one call site missing that wrapper.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: chat,
          child: SendRedpacketScreen(
            conversationId: widget.conversationId,
            conversationMemberCount: memberCount,
            isGroup: conv.isGroup,
          ),
        ),
      ),
    );
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
              style: TextStyle(
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
          if (_isRecording)
            _RecordingBanner(
              elapsedSec: _recordingElapsedSec,
              onStop: _toggleVoiceRecording,
              label: l10n.publishMomentRecordingInProgress(_recordingElapsedSec),
              stopLabel: l10n.publishMomentRecordingStopInline,
            ),
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
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (messages.isEmpty) {
          return Center(
            child: Text(
              l10n.chatRoomEmptyHint,
              style: TextStyle(color: AppColors.textHint),
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
                return Padding(
                  padding: const EdgeInsets.all(16),
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
              final key =
                  _bubbleKeys.putIfAbsent(msg.clientId, () => GlobalKey());
              return AnimatedContainer(
                key: key,
                duration: const Duration(milliseconds: 300),
                color: _highlightClientId == msg.clientId
                    ? AppColors.accent.withValues(alpha: 0.22)
                    : Colors.transparent,
                child: MessageBubble(message: msg),
              );
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
          // "+" media picker (image / video / voice) — while any
          // upload is in flight we swap to a small spinner so the
          // user sees the action was picked up.
          (_uploadingImage || _uploadingVideo || _sendingVoice)
              ? Padding(
                  padding: const EdgeInsets.all(12),
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
                  icon: Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  onPressed: _openMediaSheet,
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
                style: TextStyle(
                    fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.chatRoomInputHint,
                  hintStyle: TextStyle(color: AppColors.textHint),
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

/// Live "recording…" strip shown above the input bar while a voice
/// message is being captured — elapsed seconds + an inline stop
/// button, mirroring the moments composer's recording banner.
class _RecordingBanner extends StatelessWidget {
  final int elapsedSec;
  final VoidCallback onStop;
  final String label;
  final String stopLabel;
  const _RecordingBanner({
    required this.elapsedSec,
    required this.onStop,
    required this.label,
    required this.stopLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: onStop,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(stopLabel),
          ),
        ],
      ),
    );
  }
}
