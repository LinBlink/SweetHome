import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import '../core/app_colors.dart';
import '../core/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../providers/auth_provider.dart';
import '../providers/moment_provider.dart';
import '../services/moment_draft_store.dart';
import '../widgets/error_banner.dart';
import '../widgets/fullscreen_video_player.dart';

/// Composer screen for the family-feed (§7.1 publish flow).
///
/// Three media pipelines:
/// 1. Photos via `image_picker` (gallery or camera). Picked images
///    are compressed via `flutter_image_compress` before they hit
///    the upload pipeline so the upload size stays reasonable.
/// 2. Video via `image_picker` then `video_compress` to re-encode
///    down to a sane bitrate. If the result still exceeds 50 MB the
///    user is told the file is too large; otherwise it's added to
///    the drafts list.
/// 3. Audio via the `record` package. Mobile/desktop write an
///    opus file to a temp path; web isn't supported in this
///    iteration (`kIsWeb` hides the audio button).
///
/// While a recording is in flight the composer surfaces a live
/// banner at the top with a blinking red dot and an elapsed-second
/// counter, so the user always knows audio capture is live.
enum _ExitChoice { cancel, saveDraft, discard }

class PublishMomentScreen extends StatefulWidget {
  const PublishMomentScreen({super.key});

  @override
  State<PublishMomentScreen> createState() => _PublishMomentScreenState();
}

class _PublishMomentScreenState extends State<PublishMomentScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxMediaItems = 9;
  static const int _maxVideoBytes = 50 * 1024 * 1024;
  static const _uuid = Uuid();

  final TextEditingController _contentCtrl = TextEditingController();
  final List<MomentDraft> _drafts = [];
  final List<StreamSubscription> _subs = [];
  AudioRecorder? _recorder;
  bool _isRecording = false;
  bool _isCompressingMedia = false;
  bool _hasUnsavedContent = false;
  int? _recordingStartMs;
  int _recordingElapsedSec = 0;
  Timer? _elapsedTimer;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(_onContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestoreDraft());
  }

  @override
  void dispose() {
    _contentCtrl.removeListener(_onContentChanged);
    _contentCtrl.dispose();
    _elapsedTimer?.cancel();
    _recorder?.dispose();
    VideoCompress.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _onContentChanged() {
    final has = _contentCtrl.text.trim().isNotEmpty || _drafts.isNotEmpty;
    if (has != _hasUnsavedContent) {
      setState(() => _hasUnsavedContent = has);
    }
  }

  bool get _anyDraftUploading =>
      _drafts.any((d) => d.uploadStatus == MomentUploadStatus.uploading);

  int? get _userId => context.read<AuthProvider>().currentUser?.userId;

  /// Restores a previously-saved draft, if any, into the composer.
  /// Media can only be restored on native platforms — on web,
  /// `image_picker`'s `XFile.path` is a `blob:` URL scoped to the
  /// page's lifetime, so it's already invalid the moment the app is
  /// reloaded; only the caption text survives there.
  Future<void> _maybeRestoreDraft() async {
    final userId = _userId;
    if (userId == null) return;
    final snapshot = await MomentDraftStore.load(userId);
    if (snapshot == null || !mounted) return;
    final restored = <MomentDraft>[];
    if (!kIsWeb) {
      for (final m in snapshot.media) {
        final draft = _draftFromSnapshot(m);
        if (draft != null) restored.add(draft);
      }
    }
    if (snapshot.content.trim().isEmpty && restored.isEmpty) return;
    setState(() {
      _contentCtrl.text = snapshot.content;
      _drafts.addAll(restored);
      _draftRestored = true;
    });
    _onContentChanged();
    for (final d in restored) {
      if (d.uploadStatus != MomentUploadStatus.done) {
        unawaited(_startUpload(d));
      }
    }
  }

  /// Rebuilds one [MomentDraft] from its persisted snapshot, or
  /// `null` if there's nothing usable left (the local file is gone
  /// and it was never successfully uploaded, so there's no way to
  /// recover the media).
  MomentDraft? _draftFromSnapshot(MomentDraftMediaSnapshot m) {
    final path = m.localPath;
    final hasFile = path != null && File(path).existsSync();
    if (!hasFile && m.remoteUrl == null) return null;
    MomentDraft draft;
    switch (m.kind) {
      case 'photo':
      case 'video':
        final safePath = hasFile ? path : (path ?? '');
        final name = safePath.split(Platform.pathSeparator).last;
        draft = MomentDraft.fromXFile(
          XFile(safePath, name: name.isEmpty ? 'media' : name),
          m.kind == 'photo' ? MomentDraftKind.photo : MomentDraftKind.video,
        );
        break;
      case 'audio':
        Uint8List bytes;
        try {
          bytes = hasFile ? File(path).readAsBytesSync() : Uint8List(0);
        } catch (_) {
          bytes = Uint8List(0);
        }
        final safePath = path ?? '';
        draft = MomentDraft.fromAudio(MomentRecordedAudio(
          bytes: bytes,
          filename: safePath.isEmpty
              ? 'voice.opus'
              : safePath.split(Platform.pathSeparator).last,
          path: safePath,
          durationSec: m.durationSec,
        ));
        break;
      default:
        return null;
    }
    if (m.remoteUrl != null) {
      draft.remoteUrl = m.remoteUrl;
      draft.uploadStatus = MomentUploadStatus.done;
    } else if (!hasFile) {
      // Never finished uploading and the local file is gone too.
      return null;
    }
    return draft;
  }

  String _snapshotKind(MomentDraftKind kind) => switch (kind) {
        MomentDraftKind.photo => 'photo',
        MomentDraftKind.video => 'video',
        MomentDraftKind.audio => 'audio',
      };

  Future<void> _saveDraft() async {
    final userId = _userId;
    if (userId == null) return;
    final content = _contentCtrl.text;
    if (content.trim().isEmpty && _drafts.isEmpty) {
      await MomentDraftStore.clear(userId);
      return;
    }
    await MomentDraftStore.save(
      userId,
      MomentDraftSnapshot(
        content: content,
        media: [
          for (final d in _drafts)
            MomentDraftMediaSnapshot(
              kind: _snapshotKind(d.kind),
              localPath: d.fromPicked?.path ?? d.fromRecorded?.path,
              remoteUrl: d.remoteUrl,
              durationSec: d.fromRecorded?.durationSec,
            ),
        ],
      ),
    );
  }

  Future<void> _clearSavedDraft() async {
    final userId = _userId;
    if (userId == null) return;
    await MomentDraftStore.clear(userId);
  }

  Future<void> _onClearRestoredDraft() async {
    await _clearSavedDraft();
    if (!mounted) return;
    setState(() {
      _contentCtrl.clear();
      _drafts.clear();
      _draftRestored = false;
    });
    _onContentChanged();
  }

  /// Kicks off §2.4/§2.5/§2.6 upload for [draft] the moment it's added
  /// to the composer — the whole point being that by the time the
  /// user finishes writing a caption and taps "发布", the media is
  /// already sitting on the server and publish just has to stitch the
  /// URLs together (see `MomentProvider.publish`). Tapping a failed
  /// tile calls this again to retry, so this doesn't assume it's only
  /// ever invoked once per draft.
  Future<void> _startUpload(MomentDraft draft) async {
    if (!mounted) return;
    setState(() => draft.uploadStatus = MomentUploadStatus.uploading);
    try {
      final url = await context.read<MomentProvider>().uploadDraftMedia(draft);
      if (!mounted || !_drafts.contains(draft)) return;
      setState(() {
        draft.remoteUrl = url;
        draft.uploadStatus = MomentUploadStatus.done;
      });
    } catch (_) {
      if (!mounted || !_drafts.contains(draft)) return;
      setState(() => draft.uploadStatus = MomentUploadStatus.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MomentProvider>();
    final anyUploading = _anyDraftUploading;
    return PopScope(
      canPop: !_hasUnsavedContent && !provider.isPublishing && !_isCompressingMedia,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscard(l10n);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.publishMomentTitle),
          actions: [
            TextButton(
              onPressed: (provider.isPublishing ||
                      _isCompressingMedia ||
                      anyUploading ||
                      !_hasUnsavedContent)
                  ? null
                  : _submit,
              child: provider.isPublishing
                  ? Text(
                      provider.publishTotal > 0
                          ? l10n.publishMomentUploading(
                              provider.publishUploaded,
                              provider.publishTotal,
                            )
                          : l10n.publishMomentPublishing,
                      style: TextStyle(color: AppColors.primary),
                    )
                  : Text(
                      l10n.publishMomentPublish,
                      style: TextStyle(
                        color: (_hasUnsavedContent && !anyUploading)
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_draftRestored)
                _DraftRestoredBanner(
                  onClear: _onClearRestoredDraft,
                  onDismiss: () => setState(() => _draftRestored = false),
                ),
              if (anyUploading)
                _CompressingBanner(label: l10n.publishMomentMediaUploading),
              if (_isRecording)
                _RecordingBanner(
                  elapsedSec: _recordingElapsedSec,
                  onStop: _toggleRecording,
                ),
              if (_isCompressingMedia)
                _CompressingBanner(label: l10n.publishMomentCompressing),
              if (provider.publishError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ErrorBanner(
                    message: provider.publishError!,
                    onDismiss: () =>
                        context.read<MomentProvider>().clearError(),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _contentCtrl,
                        maxLines: 6,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.publishMomentContentHint,
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      if (_drafts.isNotEmpty)
                        _DraftsStrip(
                          drafts: _drafts,
                          onRemove: _onRemoveDraft,
                          onReorder: _onReorderDrafts,
                          onTapDraft: _onTapDraft,
                        ),
                      if (_drafts.length > 1) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.drag_indicator_rounded,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.publishMomentReorderHint,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_drafts.length < _maxMediaItems)
                        _AddMediaButton(
                          isRecording: _isRecording,
                          disabled: _isCompressingMedia,
                          onPickImage: _pickImage,
                          onPickVideo: _pickVideo,
                          onToggleRecording: _toggleRecording,
                          audioSupported: !kIsWeb,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.publishMomentMaxMedia,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<MomentProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await provider.publish(content: _contentCtrl.text, drafts: _drafts);
    if (!mounted) return;
    if (provider.publishError != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.publishError!)),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.publishMomentSuccess)));
    await _clearSavedDraft();
    _contentCtrl.clear();
    _drafts.clear();
    _hasUnsavedContent = false;
    navigator.pop();
  }

  Future<void> _confirmDiscard(AppLocalizations l10n) async {
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.publishMomentDiscardTitle),
        content: Text(l10n.publishMomentDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.cancel),
            child: Text(l10n.publishMomentDiscardCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.saveDraft),
            child: Text(l10n.publishMomentDraftSaveAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.discard),
            child: Text(
              l10n.publishMomentDiscardConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == _ExitChoice.cancel) return;
    if (choice == _ExitChoice.saveDraft) {
      await _saveDraft();
    } else {
      await _clearSavedDraft();
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    if (_drafts.length >= _maxMediaItems || _isCompressingMedia) return;
    final picker = ImagePicker();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final List<XFile> picked;
    try {
      final result = await picker.pickMultiImage(
        imageQuality: 100,
        maxWidth: 4096,
        maxHeight: 4096,
      );
      picked = result;
    } catch (e) {
      _toastFromException(e, l10n, messenger);
      return;
    }
    if (picked.isEmpty) return;
    setState(() => _isCompressingMedia = true);
    final compressed = <XFile>[];
    try {
      for (final f in picked) {
        if (compressed.length + _drafts.length >= _maxMediaItems) break;
        try {
          final compressed1 = await _compressImage(f);
          if (compressed1 != null) {
            compressed.add(compressed1);
          } else {
            compressed.add(f);
          }
        } catch (_) {
          compressed.add(f);
        }
      }
    } finally {
      if (mounted) setState(() => _isCompressingMedia = false);
    }
    if (!mounted) return;
    final added = <MomentDraft>[];
    setState(() {
      for (final f in compressed) {
        if (_drafts.length >= _maxMediaItems) break;
        final draft = MomentDraft.fromXFile(f, MomentDraftKind.photo);
        _drafts.add(draft);
        added.add(draft);
      }
      _hasUnsavedContent = true;
    });
    for (final draft in added) {
      unawaited(_startUpload(draft));
    }
  }

  /// Image compression shim — re-encodes a picked JPEG/PNG into a
  /// 1080×1080 JPEG at quality 80 via `flutter_image_compress`. The
  /// typical picked-from-gallery JPEG drops from ~4 MB to ~700 kB.
  /// Failure paths fall back to the original (no cancel — the user
  /// picked a photo, we should still try to upload it).
  static Future<XFile?> _compressImage(XFile picked) async {
    final inputBytes = await picked.readAsBytes();
    final ext = picked.name.toLowerCase();
    final format = ext.endsWith('.png')
        ? CompressFormat.png
        : CompressFormat.jpeg;
    final out = await FlutterImageCompress.compressWithList(
      inputBytes,
      minWidth: 1080,
      minHeight: 1080,
      quality: 80,
      format: format,
    );
    final dir = await getTemporaryDirectory();
    final base = picked.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final newPath =
        '${dir.path}/img_${_uuid.v4()}_$base.${format == CompressFormat.png ? 'png' : 'jpg'}';
    final tmp = File(newPath);
    await tmp.writeAsBytes(out, flush: true);
    return XFile(newPath, name: '$base.jpg', mimeType: 'image/jpeg');
  }

  Future<void> _pickVideo() async {
    if (_drafts.length >= _maxMediaItems || _isCompressingMedia) return;
    final picker = ImagePicker();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    XFile? raw;
    try {
      raw = await picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      _toastFromException(e, l10n, messenger);
      return;
    }
    if (raw == null) return;
    setState(() => _isCompressingMedia = true);
    MediaInfo? info;
    try {
      info = await VideoCompress.compressVideo(
        raw.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        frameRate: 30,
        includeAudio: true,
      );
    } catch (_) {
      info = null;
    }
    final rawSize = await File(raw.path).length().catchError((_) => 0);
    if (info == null || info.file == null || !await info.file!.exists()) {
      if (mounted) setState(() => _isCompressingMedia = false);
      final sizeMb = (rawSize / (1024 * 1024)).toStringAsFixed(1);
      messenger.showSnackBar(SnackBar(
        content: Text(
          l10n.publishMomentVideoTooLargeRaw(sizeMb),
        ),
      ));
      return;
    }
    final compressedSize =
        info.filesize ?? await info.file!.length().catchError((_) => 0);
    if (compressedSize > _maxVideoBytes) {
      final sizeMb = (compressedSize / (1024 * 1024)).toStringAsFixed(1);
      try {
        await info.file!.delete();
      } catch (_) {}
      if (mounted) setState(() => _isCompressingMedia = false);
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.publishMomentVideoTooLarge(sizeMb)),
      ));
      return;
    }
    final finalPath = info.file!.path;
    if (!mounted) {
      try {
        await File(finalPath).delete();
      } catch (_) {}
      return;
    }
    final draft = MomentDraft.fromXFile(
      XFile(finalPath, name: raw.name),
      MomentDraftKind.video,
    );
    setState(() {
      _drafts.add(draft);
      _hasUnsavedContent = true;
      _isCompressingMedia = false;
    });
    unawaited(_startUpload(draft));
  }

  Future<void> _toggleRecording() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_isRecording) {
      try {
        _elapsedTimer?.cancel();
        final stopped = await _recorder?.stop();
        if (stopped != null && stopped.isNotEmpty) {
          final file = File(stopped);
          final bytes = await file.readAsBytes();
          final durMs = DateTime.now().millisecondsSinceEpoch -
              (_recordingStartMs ?? 0);
          final durSec = (durMs / 1000).clamp(1, 600).toInt();
          final draft = MomentDraft.fromAudio(
            MomentRecordedAudio(
              bytes: bytes,
              filename: stopped.split(Platform.pathSeparator).last,
              path: stopped,
              durationSec: durSec,
            ),
          );
          setState(() {
            _drafts.add(draft);
            _isRecording = false;
            _hasUnsavedContent = true;
            _recordingStartMs = null;
            _recordingElapsedSec = 0;
          });
          unawaited(_startUpload(draft));
          return;
        }
        setState(() {
          _isRecording = false;
          _recordingStartMs = null;
          _recordingElapsedSec = 0;
        });
      } catch (e) {
        _toastFromException(e, l10n, messenger);
        setState(() {
          _isRecording = false;
          _recordingStartMs = null;
          _recordingElapsedSec = 0;
        });
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
          messenger,
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
        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - start) ~/ 1000;
        if (elapsed != _recordingElapsedSec) {
          setState(() => _recordingElapsedSec = elapsed);
        }
      });
    } catch (e) {
      _toastFromException(e, l10n, messenger);
    }
  }

  void _onRemoveDraft(int index) {
    _drafts.removeAt(index);
    setState(() {});
    _onContentChanged();
  }

  /// Long-press-drag reorder handler (see `_DraggableDraftTile`).
  /// [newIndex] is the target tile's index in the list *before* the
  /// dragged item is removed — same convention as
  /// `ReorderableListView.onReorder`, so the shift-by-one when moving
  /// forward is handled the same way here.
  void _onReorderDrafts(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _drafts.removeAt(oldIndex);
      final insertAt = oldIndex < newIndex ? newIndex - 1 : newIndex;
      _drafts.insert(insertAt, item);
    });
  }

  /// Tapping a tile previews it full-screen — unless the upload
  /// failed, in which case tapping retries instead (a second
  /// affordance for the same tile would be one tap too many on a
  /// small thumbnail).
  void _onTapDraft(MomentDraft draft) {
    if (draft.uploadStatus == MomentUploadStatus.failed) {
      unawaited(_startUpload(draft));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _DraftPreviewScreen(draft: draft),
    ));
  }

  void _toastFromException(
    Object e,
    AppLocalizations l10n,
    ScaffoldMessengerState messenger,
  ) {
    final msg = e is ApiException ? e.message : e.toString();
    final localized = localizeErrorMessage(msg, l10n);
    messenger.showSnackBar(
      SnackBar(content: Text(localized)),
    );
  }
}

class _RecordingBanner extends StatelessWidget {
  final int elapsedSec;
  final VoidCallback onStop;
  const _RecordingBanner({
    required this.elapsedSec,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          _BlinkingDot(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.publishMomentRecordingInProgress(elapsedSec),
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
            child: Text(l10n.publishMomentRecordingStopInline),
          ),
        ],
      ),
    );
  }
}

/// Shown when `_maybeRestoreDraft` finds and loads a saved draft, so
/// the user knows why the composer isn't blank — with a way to wipe
/// it back to a blank slate (`onClear`) or just dismiss the notice
/// while keeping the restored content (`onDismiss`).
class _DraftRestoredBanner extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onDismiss;
  const _DraftRestoredBanner({required this.onClear, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: AppColors.sage.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.restore_rounded, size: 16, color: AppColors.sage),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.publishMomentDraftRestored,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 28),
            ),
            child: Text(
              l10n.publishMomentDraftClear,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 16, color: AppColors.inkFaded),
          ),
        ],
      ),
    );
  }
}

class _CompressingBanner extends StatelessWidget {
  final String label;
  const _CompressingBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_ctl),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DraftsStrip extends StatelessWidget {
  final List<MomentDraft> drafts;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<MomentDraft> onTapDraft;
  const _DraftsStrip({
    required this.drafts,
    required this.onRemove,
    required this.onReorder,
    required this.onTapDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < drafts.length; i++)
          _DraggableDraftTile(
            key: ValueKey(drafts[i].id),
            index: i,
            draft: drafts[i],
            onRemove: () => onRemove(i),
            onTap: () => onTapDraft(drafts[i]),
            onReorder: onReorder,
          ),
      ],
    );
  }
}

/// One tile in the composer's media strip — a thumbnail the user can
/// tap (preview, or retry if the upload failed), remove via the
/// corner button, and long-press to drag into a new position. Built
/// on [LongPressDraggable]/[DragTarget] rather than
/// `ReorderableListView` so the strip can stay a wrapping grid
/// instead of a single horizontally-scrolling row.
class _DraggableDraftTile extends StatelessWidget {
  final int index;
  final MomentDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _DraggableDraftTile({
    required super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onTap,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tile = SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(onTap: onTap, child: _DraftPreview(draft: draft)),
          ),
          if (draft.uploadStatus != MomentUploadStatus.done)
            Positioned.fill(
              child: IgnorePointer(
                child: _UploadStatusOverlay(status: draft.uploadStatus),
              ),
            ),
          Positioned(
            right: -4,
            top: -4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.65),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                    semanticLabel: l10n.publishMomentRemoveMedia,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.85, child: tile),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isDropTarget
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: tile,
          ),
        );
      },
    );
  }
}

/// Dims the thumbnail while its upload is in flight (spinner) or
/// shows a retry affordance if it failed — tapping the tile while
/// failed calls `_onTapDraft`'s retry branch instead of opening the
/// preview.
class _UploadStatusOverlay extends StatelessWidget {
  final MomentUploadStatus status;
  const _UploadStatusOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MomentUploadStatus.uploading:
        return Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        );
      case MomentUploadStatus.failed:
        return Container(
          color: Colors.black.withValues(alpha: 0.45),
          alignment: Alignment.center,
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 26,
          ),
        );
      case MomentUploadStatus.done:
        return const SizedBox.shrink();
    }
  }
}

class _DraftPreview extends StatelessWidget {
  final MomentDraft draft;
  const _DraftPreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    switch (draft.kind) {
      case MomentDraftKind.photo:
        return _DraftPhotoTile(draft: draft);
      case MomentDraftKind.video:
        return _DraftVideoTile(draft: draft);
      case MomentDraftKind.audio:
        final a = draft.fromRecorded!;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.linen,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_none_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                a.durationSec == null ? '' : _formatSeconds(a.durationSec!),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        );
    }
  }

  static String _formatSeconds(int s) {
    final m = (s ~/ 60).toString();
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}

class _DraftPhotoTile extends StatelessWidget {
  final MomentDraft draft;
  const _DraftPhotoTile({required this.draft});

  @override
  Widget build(BuildContext context) {
    final f = draft.fromPicked!;
    final placeholder = Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: 28,
        color: AppColors.textHint,
      ),
    );
    Widget img;
    if (kIsWeb) {
      img = Image.network(f.path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
    } else {
      img = Image.file(
        File(f.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: img,
    );
  }
}

class _DraftVideoTile extends StatefulWidget {
  final MomentDraft draft;
  const _DraftVideoTile({required this.draft});

  @override
  State<_DraftVideoTile> createState() => _DraftVideoTileState();
}

class _DraftVideoTileState extends State<_DraftVideoTile> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final f = widget.draft.fromPicked;
    if (f == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final c = VideoPlayerController.file(File(f.path));
    _controller = c;
    try {
      await c.initialize();
      await c.pause();
      await c.seekTo(Duration.zero);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_failed) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                size: 22,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.momentDetailVideoLoadFailed,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final c = _controller;
    if (!_ready || c == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen preview for a not-yet-published draft, opened by
/// tapping its thumbnail in the composer. Always renders from the
/// local file/bytes (never the upload URL) so it works instantly
/// even while the upload is still in flight or has failed.
class _DraftPreviewScreen extends StatelessWidget {
  final MomentDraft draft;
  const _DraftPreviewScreen({required this.draft});

  @override
  Widget build(BuildContext context) {
    switch (draft.kind) {
      case MomentDraftKind.photo:
        return _DraftImagePreview(draft: draft);
      case MomentDraftKind.video:
        return _DraftVideoPreview(draft: draft);
      case MomentDraftKind.audio:
        return _DraftAudioPreview(draft: draft);
    }
  }
}

class _DraftImagePreview extends StatelessWidget {
  final MomentDraft draft;
  const _DraftImagePreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    final f = draft.fromPicked!;
    final image = kIsWeb
        ? Image.network(f.path, fit: BoxFit.contain)
        : Image.file(File(f.path), fit: BoxFit.contain);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 5.0,
          child: image,
        ),
      ),
    );
  }
}

/// Full-screen draft video preview — same play/pause/scrubber/±10s
/// experience as the published feed's fullscreen video
/// ([FullscreenVideoPlayer]), just pointed at the local picked file
/// instead of a network URL so it works before the upload finishes.
class _DraftVideoPreview extends StatelessWidget {
  final MomentDraft draft;
  const _DraftVideoPreview({required this.draft});

  Future<VideoPlayerController> _open() async {
    final f = draft.fromPicked;
    if (f == null) throw StateError('video draft missing a picked file');
    return kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(f.path))
        : VideoPlayerController.file(File(f.path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FullscreenVideoPlayer(
      openController: _open,
      loadFailedLabel: l10n.momentDetailVideoLoadFailed,
    );
  }
}

class _DraftAudioPreview extends StatefulWidget {
  final MomentDraft draft;
  const _DraftAudioPreview({required this.draft});

  @override
  State<_DraftAudioPreview> createState() => _DraftAudioPreviewState();
}

class _DraftAudioPreviewState extends State<_DraftAudioPreview> {
  AudioPlayer? _player;
  bool _ready = false;
  bool _failed = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final a = widget.draft.fromRecorded;
    if (a == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final p = AudioPlayer();
    _player = p;
    try {
      final dur = await p.setFilePath(a.path);
      _duration = dur ?? Duration.zero;
      p.positionStream.listen((d) {
        if (!mounted) return;
        setState(() => _position = d);
      });
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget body;
    if (_failed) {
      body = Text(
        l10n.momentDetailAudioLoadFailed,
        style: TextStyle(color: AppColors.textHint),
      );
    } else if (!_ready || _player == null) {
      body = const CircularProgressIndicator();
    } else {
      final maxMs =
          _duration.inMilliseconds.toDouble().clamp(1, double.infinity).toDouble();
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          IconButton(
            iconSize: 56,
            color: AppColors.primary,
            icon: Icon(
              _player!.playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
            ),
            onPressed: () {
              setState(() {
                if (_player!.playing) {
                  _player!.pause();
                } else {
                  _player!.play();
                }
              });
            },
          ),
          SizedBox(
            width: 240,
            child: Slider(
              value: _position.inMilliseconds.toDouble().clamp(0, maxMs).toDouble(),
              min: 0,
              max: maxMs,
              onChanged: (v) => _player!.seek(Duration(milliseconds: v.toInt())),
              activeColor: AppColors.primary,
            ),
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.publishMomentMediaTypeAudio)),
      body: Center(child: body),
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  final bool isRecording;
  final bool disabled;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onToggleRecording;
  final bool audioSupported;
  const _AddMediaButton({
    required this.isRecording,
    required this.disabled,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onToggleRecording,
    required this.audioSupported,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: disabled
          ? null
          : () => showModalBottomSheet(
              context: context,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      l10n.publishMomentAddMediaSheet,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ListTile(
                      leading: Icon(
                        Icons.photo_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(l10n.publishMomentMediaTypeImage),
                      onTap: () {
                        Navigator.pop(ctx);
                        onPickImage();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.movie_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(l10n.publishMomentMediaTypeVideo),
                      onTap: () {
                        Navigator.pop(ctx);
                        onPickVideo();
                      },
                    ),
                    if (audioSupported)
                      ListTile(
                        leading: Icon(
                          Icons.mic_none_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          isRecording
                              ? l10n.publishMomentRecordingStop
                              : l10n.publishMomentMediaTypeAudio,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onToggleRecording();
                        },
                      ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surfaceVariant
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: disabled ? 0.15 : 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              disabled ? Icons.hourglass_top_rounded : Icons.add_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.publishMomentAddMedia,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
