import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/home_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member_vm.dart';
import '../../models/health_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../widgets/health_chart.dart';
import 'health_edit_record_sheet.dart';

class HealthHomeScreen extends StatelessWidget {
  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.healthTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                l10n.healthSubtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.inkFaded,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.healthTabMyRecords),
              Tab(text: l10n.healthTabFamily),
              Tab(text: l10n.healthTabSettings),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkFaded,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: PaperBackground(
          child: const TabBarView(
            children: [
              _MyRecordsTab(),
              _FamilyRecordsTab(),
              _SettingsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRecordsTab extends StatefulWidget {
  const _MyRecordsTab();

  @override
  State<_MyRecordsTab> createState() => _MyRecordsTabState();
}

class _MyRecordsTabState extends State<_MyRecordsTab> {
  HealthMetricType _selectedMetric = HealthMetricType.weight;
  HealthMetricType _historyMetric = HealthMetricType.weight;
  final _valueController = TextEditingController();
  final _valueSecondaryController = TextEditingController();
  final _dateController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _valueController.dispose();
    _valueSecondaryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final health = context.watch<HealthProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SizedBox(height: 12),
        HomeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.healthRecordNew,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              _MetricTypeSelector(
                selected: _selectedMetric,
                onChanged: (v) => setState(() {
                  _selectedMetric = v;
                  _localError = null;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _valueLabel(_selectedMetric),
                        hintText: _valueHint(_selectedMetric),
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
                  if (_selectedMetric == HealthMetricType.bloodPressure) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _valueSecondaryController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.healthBloodPressureDiastolic,
                          hintText: '80',
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
                  hintText: _todayString(),
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
                    initialDate: DateTime.now(),
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
              if (health.submitError != null) ...[
                const SizedBox(height: 8),
                Text(
                  health.submitError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: health.isSubmitting
                      ? null
                      : () => _submit(health, l10n),
                  child: health.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.healthRecordSubmit),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── History / Chart section ──
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.healthHistoryTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            _HistoryMetricSelector(
              selected: _historyMetric,
              onChanged: (v) => setState(() => _historyMetric = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (health.ownRecordsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (health.ownRecordsError != null)
          _ErrorCard(message: health.ownRecordsError!, l10n: l10n)
        else ...[
          HomeCard(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: HealthChart(
              records: health.ownRecords,
              metricType: _historyMetric,
            ),
          ),
          const SizedBox(height: 16),
          ...health.ownRecords
              .where((r) => r.metricType == _historyMetric)
              .map(
                (r) => _RecordTile(
                  record: r,
                  onTap: () => HealthEditRecordSheet.show(context, r),
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _submit(HealthProvider health, AppLocalizations l10n) async {
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
    if (_selectedMetric == HealthMetricType.bloodPressure) {
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
    final dateStr = _dateController.text.isNotEmpty
        ? _dateController.text
        : null;
    final result = await health.submitRecord(
      metricType: _selectedMetric,
      value: value,
      valueSecondary: valueSecondary,
      recordedAt: dateStr,
    );

    if (result != null && mounted) {
      _valueController.clear();
      _valueSecondaryController.clear();
    }
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

  String _valueHint(HealthMetricType t) {
    switch (t) {
      case HealthMetricType.height:
        return '170';
      case HealthMetricType.weight:
        return '65';
      case HealthMetricType.bloodPressure:
        return '120';
    }
  }

  String _todayString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _FamilyRecordsTab extends StatefulWidget {
  const _FamilyRecordsTab();

  @override
  State<_FamilyRecordsTab> createState() => _FamilyRecordsTabState();
}

class _FamilyRecordsTabState extends State<_FamilyRecordsTab> {
  int? _selectedMemberId;
  HealthMetricType? _selectedMetric;
  late final Future<List<FamilyMemberVm>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _load();
  }

  Future<List<FamilyMemberVm>> _load() {
    return context.read<AuthProvider>().loadFamilyMembers();
  }

  void _selectMember(FamilyMemberVm member) {
    setState(() => _selectedMemberId = member.userId);
    context
        .read<HealthProvider>()
        .loadFamilyRecords(member.userId, metricType: _selectedMetric);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final health = context.watch<HealthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SizedBox(height: 12),
        HomeCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.healthSelectMember,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<FamilyMemberVm>>(
                future: _membersFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snap.hasError || !snap.hasData) {
                    return Text(
                      snap.error?.toString() ?? l10n.healthSelectMemberHint,
                      style: TextStyle( fontSize: 12, color: AppColors.inkFaded, ),
                    );
                  }
                  final members = snap.data!
                      .where((m) => m.relationCode != 'SELF')
                      .toList();
                  if (members.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.contactsEmpty,
                        style: TextStyle( fontSize: 12, color: AppColors.inkFaded, ),
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members.map((m) {
                      final isSelected = _selectedMemberId == m.userId;
                      return ChoiceChip(
                        label: Text(
                          m.name,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        onSelected: (_) => _selectMember(m),
                      );
                    }).toList(),
                  );
                },
              ),
              if (_selectedMemberId != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.healthFilterByMetric,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricFilterChip(
                      label: l10n.healthTabAll,
                      selected: _selectedMetric == null,
                      onSelected: () {
                        setState(() => _selectedMetric = null);
                        health.loadFamilyRecords(_selectedMemberId!);
                      },
                    ),
                    for (final t in HealthMetricType.values)
                      _MetricFilterChip(
                        label: _metricTypeLabel(t, l10n),
                        selected: _selectedMetric == t,
                        onSelected: () {
                          setState(() => _selectedMetric = t);
                          health.loadFamilyRecords(_selectedMemberId!,
                              metricType: t);
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedMemberId == null)
          _EmptyCard(message: l10n.healthSelectMemberHint)
        else if (health.familyRecordsLoading(_selectedMemberId!))
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (health.familyRecordsError(_selectedMemberId!) != null)
          _ErrorCard(
            message: health.familyRecordsError(_selectedMemberId!)!,
            l10n: l10n,
          )
        else if (health.familyRecordsOf(_selectedMemberId!).isEmpty)
          _EmptyCard(message: l10n.healthNoRecords)
        else ...[
          // Chart only renders when a specific metric is picked —
          // a single chart can't combine all 3 metrics meaningfully.
          if (_selectedMetric != null)
            HomeCard(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: HealthChart(
                records: health.familyRecordsOf(_selectedMemberId!),
                metricType: _selectedMetric!,
              ),
            )
          else
            _EmptyCard(message: l10n.healthChartSelectMetric),
          const SizedBox(height: 16),
          ...health
              .familyRecordsOf(_selectedMemberId!)
              .map((r) => _RecordTile(record: r)),
        ],
      ],
    );
  }

  String _metricTypeLabel(HealthMetricType t, AppLocalizations l10n) {
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

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final health = context.watch<HealthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SizedBox(height: 12),
        HomeSectionHeader(
          title: l10n.healthVisibilityTitle,
          accentIcon: Icons.visibility_rounded,
        ),
        const SizedBox(height: 8),
        if (health.visibilitiesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          ...health.visibilities.map((v) {
            return HomeCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _metricIcon(v.metricType),
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _metricTypeLabel(v.metricType, l10n),
                      style: TextStyle( fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink, ),
                    ),
                  ),
                  Switch(
                    value: v.visible,
                    activeColor: AppColors.primary,
                    onChanged: (on) {
                      health.toggleVisibility(v.metricType, on);
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        HomeSectionHeader(
          title: l10n.healthReminderTitle,
          accentIcon: Icons.notifications_rounded,
        ),
        const SizedBox(height: 8),
        HomeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.healthReminderEnable,
                      style: TextStyle( fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink, ),
                    ),
                  ),
                  Switch(
                    value: health.reminder.enabled,
                    activeColor: AppColors.primary,
                    onChanged: (on) {
                      final time =
                          health.reminder.remindTime ?? '20:00:00';
                      health.updateReminder(
                          remindTime: time, enabled: on);
                    },
                  ),
                ],
              ),
              if (health.reminder.enabled) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.healthReminderTime,
                  style: TextStyle( fontSize: 13, color: AppColors.inkFaded, ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _parseRemindTime(
                          health.reminder.remindTime),
                    );
                    if (time != null && context.mounted) {
                      final formatted =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                      health.updateReminder(
                        remindTime: formatted,
                        enabled: true,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayTime(health.reminder.remindTime),
                            style: TextStyle( fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink, ),
                          ),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.healthReminderHint,
                  style: TextStyle( fontSize: 11, color: AppColors.inkFaded, ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  TimeOfDay _parseRemindTime(String? time) {
    if (time == null) return const TimeOfDay(hour: 20, minute: 0);
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _displayTime(String? time) {
    if (time == null) return '20:00';
    final parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  IconData _metricIcon(HealthMetricType t) {
    switch (t) {
      case HealthMetricType.height:
        return Icons.height_rounded;
      case HealthMetricType.weight:
        return Icons.monitor_weight_rounded;
      case HealthMetricType.bloodPressure:
        return Icons.favorite_rounded;
    }
  }

  String _metricTypeLabel(HealthMetricType t, AppLocalizations l10n) {
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

class _MetricTypeSelector extends StatelessWidget {
  final HealthMetricType selected;
  final ValueChanged<HealthMetricType> onChanged;

  const _MetricTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in HealthMetricType.values)
          ChoiceChip(
            label: Text(
              _label(t, l10n),
              style: TextStyle(
                fontSize: 13,
                color: selected == t ? Colors.white : AppColors.ink,
              ),
            ),
            selected: selected == t,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceVariant,
            onSelected: (_) => onChanged(t),
          ),
      ],
    );
  }

  String _label(HealthMetricType t, AppLocalizations l10n) {
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

class _MetricFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _MetricFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.sage,
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Compact horizontal chip row used in the chart header — keeps the
/// same visual language as the form's metric selector but uses the
/// sage palette so it doesn't compete visually with the form
/// (which uses primary-terracotta).
class _HistoryMetricSelector extends StatelessWidget {
  final HealthMetricType selected;
  final ValueChanged<HealthMetricType> onChanged;

  const _HistoryMetricSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final t in HealthMetricType.values)
          ChoiceChip(
            label: Text(
              _label(t, l10n),
              style: TextStyle(
                fontSize: 11,
                color: selected == t ? Colors.white : AppColors.ink,
              ),
            ),
            selected: selected == t,
            selectedColor: AppColors.sage,
            backgroundColor: AppColors.surfaceVariant,
            onSelected: (_) => onChanged(t),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }

  String _label(HealthMetricType t, AppLocalizations l10n) {
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

class _RecordTile extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback? onTap;
  const _RecordTile({required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tappable = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HomeCard(
        padding: const EdgeInsets.all(12),
        onTap: tappable
            ? () {
                // Clear any stale edit error from a previous failed
                // attempt so the sheet doesn't open with a banner
                // already showing.
                context.read<HealthProvider>().clearEditError();
                onTap!();
              }
            : null,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(record.metricType),
                color: AppColors.sage,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _metricLabel(record.metricType, l10n),
                    style: TextStyle( fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatValue(record.metricType, record),
                    style: TextStyle( fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary, ),
                  ),
                ],
              ),
            ),
            Text(
              record.recordedAt,
              style: TextStyle( fontSize: 11, color: AppColors.inkFaded, ),
            ),
            if (tappable) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaded,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
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

  String _formatValue(HealthMetricType t, HealthRecord r) {
    switch (t) {
      case HealthMetricType.height:
        return '${r.value.toStringAsFixed(1)} cm';
      case HealthMetricType.weight:
        return '${r.value.toStringAsFixed(1)} kg';
      case HealthMetricType.bloodPressure:
        if (r.valueSecondary != null) {
          return '${r.value.toInt()}/${r.valueSecondary!.toInt()} mmHg';
        }
        return '${r.value.toInt()} mmHg';
    }
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: AppColors.inkFaded, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle( fontSize: 13, color: AppColors.inkFaded, ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final AppLocalizations l10n;
  const _ErrorCard({required this.message, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle( fontSize: 12, color: AppColors.danger, ),
            ),
          ),
        ],
      ),
    );
  }
}
