import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_colors.dart';
import '../core/home_widgets.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/chat_export_pdf_service.dart';
import '../services/chat_export_service.dart';

enum _ExportFormat { txt, pdf }

enum _Step { selecting, generating, done }

/// Exports the locally-cached chat history (`ChatLocalCache`). Reached
/// from the profile tab's settings section. Two-step flow:
/// 1. Pick which conversations to include and a format — plain text
///    (no images) or PDF (images embedded inline, via
///    `ChatExportPdfService`).
/// 2. Generated result: copy-to-clipboard (txt only, always works —
///    including web), share to another app (`share_plus`, works with
///    in-memory bytes so it doesn't depend on a writable filesystem),
///    and on native platforms the file is also written under the
///    app's documents directory (path shown so it's findable in a
///    file manager).
class ChatExportScreen extends StatefulWidget {
  const ChatExportScreen({super.key});

  @override
  State<ChatExportScreen> createState() => _ChatExportScreenState();
}

class _ChatExportScreenState extends State<ChatExportScreen> {
  static const _txtService = ChatExportService();
  static final _pdfService = ChatExportPdfService();

  /// Beyond this span, `_generate` confirms with the user first —
  /// PDF generation in particular fetches every image message's
  /// bytes over the network, and a wide date range can mean a lot of
  /// them.
  static const _longRangeThreshold = Duration(days: 30);

  _Step _step = _Step.selecting;
  bool _loadingSummaries = true;
  List<ChatExportConversationSummary> _summaries = [];
  final Set<int> _selectedIds = {};
  _ExportFormat _format = _ExportFormat.txt;
  DateTimeRange? _dateRange;

  ChatExportResult? _txtResult;
  ChatExportPdfResult? _pdfResult;
  String? _savedPath;
  int _pdfProgressCurrent = 0;
  int _pdfProgressTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummaries());
  }

  Future<void> _loadSummaries() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) {
      setState(() => _loadingSummaries = false);
      return;
    }
    final summaries = await _txtService.loadConversationSummaries(currentUserId: userId);
    if (!mounted) return;
    setState(() {
      _summaries = summaries;
      _selectedIds
        ..clear()
        ..addAll(summaries.map((s) => s.id));
      _loadingSummaries = false;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _clearDateRange() => setState(() => _dateRange = null);

  Future<bool> _confirmLongRangeIfNeeded(AppLocalizations l10n) async {
    final range = _dateRange;
    if (range == null || range.duration <= _longRangeThreshold) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatExportLongRangeTitle),
        content: Text(l10n.chatExportLongRangeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatExportSelectAtLeastOne)),
      );
      return;
    }
    if (!await _confirmLongRangeIfNeeded(l10n)) return;
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;
    final range = _dateRange;
    setState(() {
      _step = _Step.generating;
      _pdfProgressCurrent = 0;
      _pdfProgressTotal = 0;
    });

    if (_format == _ExportFormat.txt) {
      final result = await _txtService.buildTranscript(
        currentUserId: userId,
        conversationIds: _selectedIds,
        startDate: range?.start,
        endDate: range?.end,
        meLabel: l10n.profileMe,
        imageLabel: l10n.chatMessageTypeImage,
        voiceLabel: l10n.chatMessageTypeVoice,
        videoLabel: l10n.chatMessageTypeVideo,
      );
      String? savedPath;
      if (result != null && !kIsWeb) {
        savedPath = await _saveTextToFile(result.text);
      }
      if (!mounted) return;
      setState(() {
        _txtResult = result;
        _pdfResult = null;
        _savedPath = savedPath;
        _step = _Step.done;
      });
    } else {
      final result = await _pdfService.build(
        currentUserId: userId,
        conversationIds: _selectedIds,
        startDate: range?.start,
        endDate: range?.end,
        meLabel: l10n.profileMe,
        imageLabel: l10n.chatMessageTypeImage,
        voiceLabel: l10n.chatMessageTypeVoice,
        videoLabel: l10n.chatMessageTypeVideo,
        imageLoadFailedLabel: l10n.chatExportImageLoadFailed,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _pdfProgressCurrent = current;
            _pdfProgressTotal = total;
          });
        },
      );
      String? savedPath;
      if (result != null && !kIsWeb) {
        savedPath = await _saveBytesToFile(result.bytes, 'pdf');
      }
      if (!mounted) return;
      setState(() {
        _pdfResult = result;
        _txtResult = null;
        _savedPath = savedPath;
        _step = _Step.done;
      });
    }
  }

  Future<String?> _saveTextToFile(String text) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${_exportFileName('txt')}');
      await file.writeAsString(text);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _saveBytesToFile(Uint8List bytes, String ext) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${_exportFileName(ext)}');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _formatDateRange(DateTimeRange range) {
    String fmt(DateTime d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)}';
    }

    return '${fmt(range.start)} ~ ${fmt(range.end)}';
  }

  String _exportFileName(String ext) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'sweethome_chat_export_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}.$ext';
  }

  Future<void> _copyAll() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _txtResult?.text;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.chatExportCopied)),
    );
  }

  Future<void> _share() async {
    if (_format == _ExportFormat.txt) {
      final text = _txtResult?.text;
      if (text == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(text.codeUnits),
              name: _exportFileName('txt'),
              mimeType: 'text/plain',
            ),
          ],
        ),
      );
    } else {
      final bytes = _pdfResult?.bytes;
      if (bytes == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: _exportFileName('pdf'),
              mimeType: 'application/pdf',
            ),
          ],
        ),
      );
    }
  }

  void _backToSelection() {
    setState(() {
      _step = _Step.selecting;
      _txtResult = null;
      _pdfResult = null;
      _savedPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.chatExportTitle),
      body: PaperBackground(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loadingSummaries) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_summaries.isEmpty) {
      return _EmptyState(message: l10n.chatExportEmpty);
    }
    switch (_step) {
      case _Step.selecting:
        return _buildSelectionStep(l10n);
      case _Step.generating:
        final showProgress = _format == _ExportFormat.pdf && _pdfProgressTotal > 0;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress)
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _pdfProgressCurrent / _pdfProgressTotal,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                showProgress
                    ? l10n.chatExportGeneratingProgress(
                        _pdfProgressCurrent,
                        _pdfProgressTotal,
                      )
                    : l10n.chatExportGenerating,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      case _Step.done:
        return _buildResultStep(l10n);
    }
  }

  Widget _buildSelectionStep(AppLocalizations l10n) {
    final allSelected = _selectedIds.length == _summaries.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.chatExportSelectConversationsTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (allSelected) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds
                        ..clear()
                        ..addAll(_summaries.map((s) => s.id));
                    }
                  });
                },
                child: Text(
                  allSelected ? l10n.chatExportDeselectAll : l10n.chatExportSelectAll,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
          child: InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateRange == null
                          ? l10n.chatExportDateRangeAll
                          : _formatDateRange(_dateRange!),
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  if (_dateRange != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: _clearDateRange,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final s in _summaries)
                CheckboxListTile(
                  value: _selectedIds.contains(s.id),
                  title: Text(s.name),
                  subtitle: Text(l10n.chatRoomMessageCount(s.messageCount)),
                  activeColor: AppColors.primary,
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _selectedIds.add(s.id);
                      } else {
                        _selectedIds.remove(s.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chatExportFormatSection,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              RadioGroup<_ExportFormat>(
                groupValue: _format,
                onChanged: (v) => setState(() => _format = v!),
                child: Column(
                  children: [
                    RadioListTile<_ExportFormat>(
                      value: _ExportFormat.txt,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(l10n.chatExportFormatTxt),
                    ),
                    RadioListTile<_ExportFormat>(
                      value: _ExportFormat.pdf,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(l10n.chatExportFormatPdf),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HomePrimaryButton(
                label: l10n.chatExportGenerateButton,
                leadingIcon: Icons.ios_share_rounded,
                onPressed: _generate,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep(AppLocalizations l10n) {
    final txt = _txtResult;
    final pdf = _pdfResult;
    final conversationCount = txt?.conversationCount ?? pdf?.conversationCount ?? 0;
    final messageCount = txt?.messageCount ?? pdf?.messageCount ?? 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _backToSelection,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.chatExportSummary(conversationCount, messageCount),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_savedPath != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.chatExportSavedTo(_savedPath!),
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_format == _ExportFormat.txt)
                    Expanded(
                      child: HomePrimaryButton(
                        label: l10n.chatExportCopy,
                        leadingIcon: Icons.copy_all_rounded,
                        onPressed: _copyAll,
                        fullWidth: true,
                      ),
                    ),
                  if (_format == _ExportFormat.txt) const SizedBox(width: 10),
                  Expanded(
                    child: HomePrimaryButton(
                      label: l10n.chatExportShare,
                      leadingIcon: Icons.share_rounded,
                      onPressed: _share,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: txt != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    txt.text,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                )
              : pdf != null
                  ? PdfPreview(
                      build: (format) async => pdf.bytes,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      allowSharing: false,
                      allowPrinting: false,
                      useActions: false,
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 56,
              color: AppColors.primaryLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
