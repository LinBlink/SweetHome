import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/health_record.dart';
import '../../providers/health_provider.dart';

/// Modal bottom sheet for §8.3 — editing an existing health record.
///
/// The metric type is fixed (the server doesn't accept a
/// `metricType` field on the update endpoint), but value,
/// [valueSecondary] (BP only), and date can all be changed. The
/// form is pre-filled from the source [record] and a "save" calls
/// [HealthProvider.updateRecord]; success dismisses the sheet,
/// failure surfaces the specific error (409 conflict, 404 not
/// found, 403 not owner) inline rather than swallowing it.
class HealthEditRecordSheet extends StatefulWidget {
  final HealthRecord record;

  const HealthEditRecordSheet({super.key, required this.record});

  static Future<void> show(BuildContext context, HealthRecord record) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HealthEditRecordSheet(record: record),
    );
  }

  @override
  State<HealthEditRecordSheet> createState() => _HealthEditRecordSheetState();
}

class _HealthEditRecordSheetState extends State<HealthEditRecordSheet> {
  late final TextEditingController _valueController;
  late final TextEditingController _valueSecondaryController;
  late final TextEditingController _dateController;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: _formatForField(widget.record.metricType, widget.record.value,
          isSecondary: false),
    );
    _valueSecondaryController = TextEditingController(
      text: widget.record.valueSecondary == null
          ? ''
          : widget.record.valueSecondary!.toInt().toString(),
    );
    _dateController = TextEditingController(
      text: widget.record.recordedAt,
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _valueSecondaryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatForField(
    HealthMetricType t,
    double value, {
    required bool isSecondary,
  }) {
    if (t == HealthMetricType.bloodPressure) {
      return value.toInt().toString();
    }
    // Strip trailing zero if integer (e.g. "175" not "175.0") so the
    // user sees the same precision they originally typed.
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Future<void> _save(AppLocalizations l10n) async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      setState(() => _localError = l10n.healthValueRequired);
      return;
    }
    final value = double.tryParse(valueText);
    if (value == null) {
      setState(() => _localError = l10n.healthValueInvalid);
      return;
    }

    double? valueSecondary;
    if (widget.record.metricType == HealthMetricType.bloodPressure) {
      final secText = _valueSecondaryController.text.trim();
      if (secText.isEmpty) {
        setState(() => _localError = l10n.healthBloodPressureBothRequired);
        return;
      }
      valueSecondary = double.tryParse(secText);
      if (valueSecondary == null) {
        setState(() => _localError = l10n.healthValueInvalid);
        return;
      }
    }

    setState(() => _localError = null);

    final health = context.read<HealthProvider>();
    final dateStr = _dateController.text;
    final newDate =
        dateStr == widget.record.recordedAt ? null : dateStr;

    final updated = await health.updateRecord(
      recordId: widget.record.id,
      value: value,
      valueSecondary: valueSecondary,
      recordedAt: newDate,
    );

    if (!mounted) return;
    if (updated != null) {
      Navigator.of(context).pop();
    }
  }

  String _errorMessageForCode(int? code, AppLocalizations l10n) {
    switch (code) {
      case 409:
        return l10n.healthEditDateConflict;
      case 404:
        return l10n.healthEditRecordNotFound;
      case 403:
        return l10n.healthEditNotOwner;
      default:
        return l10n.healthEditFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final health = context.watch<HealthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    _iconFor(widget.record.metricType),
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _metricLabel(widget.record.metricType, l10n),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    widget.record.recordedAt,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Value fields.
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: _valueLabel(widget.record.metricType),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ),
                  if (widget.record.metricType ==
                      HealthMetricType.bloodPressure) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _valueSecondaryController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.healthBloodPressureDiastolic,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.healthRecordDate,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _parseDate(widget.record.recordedAt),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    final y = picked.year.toString().padLeft(4, '0');
                    final m = picked.month.toString().padLeft(2, '0');
                    final d = picked.day.toString().padLeft(2, '0');
                    _dateController.text = '$y-$m-$d';
                  }
                },
              ),
              if (_localError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _localError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ],
              if (health.editError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessageForCode(
                            health.editErrorCode,
                            l10n,
                          ),
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: health.isEditing
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.commonCancel,
                        style: TextStyle(color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: health.isEditing
                          ? null
                          : () => _save(l10n),
                      child: health.isEditing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.healthEditSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  String _valueLabel(HealthMetricType t) {
    final l10n = AppLocalizations.of(context)!;
    switch (t) {
      case HealthMetricType.height:
        return l10n.healthHeightCm;
      case HealthMetricType.weight:
        return l10n.healthWeightKg;
      case HealthMetricType.bloodPressure:
        return l10n.healthBloodPressureSystolic;
    }
  }

  IconData _iconFor(HealthMetricType t) {
    switch (t) {
      case HealthMetricType.height:
        return Icons.height_rounded;
      case HealthMetricType.weight:
        return Icons.monitor_weight_rounded;
      case HealthMetricType.bloodPressure:
        return Icons.favorite_rounded;
    }
  }

  String _metricLabel(HealthMetricType t, AppLocalizations l10n) {
    switch (t) {
      case HealthMetricType.height:
        return l10n.healthHeight;
      case HealthMetricType.weight:
        return l10n.healthWeight;
      case HealthMetricType.bloodPressure:
        return l10n.healthBloodPressure;
    }
  }
}