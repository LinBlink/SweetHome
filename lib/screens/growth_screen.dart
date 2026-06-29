import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  String _selectedMemberId = 'son';

  FamilyMember get _selectedMember =>
      mockFamily.firstWhere((m) => m.id == _selectedMemberId);

  List<GrowthRecord> get _selectedRecords =>
      mockGrowthRecords.where((r) => r.memberId == _selectedMemberId).toList();

  List<MedicationReminder> get _memberMeds =>
      mockMedications.where((m) => m.memberId == _selectedMemberId).toList();

  List<VaccineItem> get _memberVaccines =>
      mockVaccines.where((v) => v.memberId == _selectedMemberId).toList();

  final List<String> _selectableIds = [
    'son',
    'daughter',
    'grandpa',
    'grandma'
  ];

  @override
  Widget build(BuildContext context) {
    final isElder = _selectedMember.isElder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('成长健康'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMemberSelector(),
            const SizedBox(height: 16),
            if (isElder)
              _buildElderContent()
            else
              _buildChildContent(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _selectableIds.map((id) {
          final member = mockFamily.firstWhere((m) => m.id == id);
          final isSelected = _selectedMemberId == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMemberId = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : member.avatarColor.withValues(alpha: 0.15),
                      child: Text(
                        member.avatarLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : member.avatarColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Child Content ─────────────────────────────────────────────────────────

  Widget _buildChildContent() {
    final records = _selectedRecords;
    if (records.isEmpty) return const Center(child: Text('暂无数据'));

    final latest = records.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGrowthStatsCard(latest),
        const SizedBox(height: 12),
        _buildGrowthChart(records),
        const SizedBox(height: 16),
        _buildVaccineSection(),
        const SizedBox(height: 16),
        _buildMedicationSection(),
        const SizedBox(height: 16),
        _buildHabitSection(),
      ],
    );
  }

  Widget _buildGrowthStatsCard(GrowthRecord latest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_selectedMember.name}的生长记录',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 12),
                      SizedBox(width: 3),
                      Text('WHO标准: 正常',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    '身高',
                    '${latest.height}',
                    'cm',
                    Icons.height,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    '体重',
                    '${latest.weight}',
                    'kg',
                    Icons.monitor_weight_outlined,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    '年龄',
                    '${_selectedMember.age}',
                    '岁',
                    Icons.cake_outlined,
                    AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(List<GrowthRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();

    final minHeight = records.map((r) => r.height).reduce((a, b) => a < b ? a : b);
    final maxHeight = records.map((r) => r.height).reduce((a, b) => a > b ? a : b);
    final heightRange = maxHeight - minHeight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '身高趋势',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: records.take(5).map((record) {
                  final ratio = heightRange > 0
                      ? (record.height - minHeight) / heightRange
                      : 0.5;
                  final barHeight = 40 + ratio * 60;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${record.height}',
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2196F3),
                                  Color(0xFF64B5F6)
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.date,
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineSection() {
    final vaccines = _memberVaccines;
    if (vaccines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '疫苗计划',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...vaccines.map((v) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: v.isDone
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  v.isDone ? Icons.check_circle : Icons.schedule,
                  color: v.isDone ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
              ),
              title: Text(v.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: v.isDone
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      decoration: v.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none)),
              subtitle: Text(v.dueDate,
                  style: const TextStyle(fontSize: 11)),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: v.isDone
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  v.isDone ? '已接种' : '即将到期',
                  style: TextStyle(
                    fontSize: 11,
                    color: v.isDone ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMedicationSection() {
    final meds = _memberMeds;
    if (meds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '用药提醒',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...meds.map((med) {
          final isLow = med.remainingDays < 7;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isLow
                  ? const BorderSide(color: AppColors.danger, width: 1)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isLow
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: isLow ? AppColors.danger : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        Text('${med.dosage} · ${med.times.join(' / ')}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '剩余 ${med.remainingDays} 天',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLow ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                      if (isLow)
                        const Text('请及时补药',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.danger)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHabitSection() {
    final habits =
        mockHabits.where((h) => h.memberId == _selectedMemberId).toList();
    if (habits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '习惯打卡',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...habits.map((habit) => _buildHabitCard(habit)),
      ],
    );
  }

  Widget _buildHabitCard(HabitChallenge habit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habit.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(habit.icon, color: habit.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      Text(habit.description,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: habit.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔥 ${habit.streakDays}天',
                    style: TextStyle(
                        fontSize: 12,
                        color: habit.color,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: habit.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: habit.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: habit.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已坚持 ${habit.streakDays} / ${habit.targetDays} 天',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  '${(habit.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11,
                      color: habit.color,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Elder Content ──────────────────────────────────────────────────────────

  Widget _buildElderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepsCard(),
        const SizedBox(height: 12),
        _buildBloodPressureCard(),
        const SizedBox(height: 12),
        _buildMedicationSection(),
        const SizedBox(height: 12),
        _buildFallDetectionCard(),
        const SizedBox(height: 12),
        _buildVaccineSection(),
      ],
    );
  }

  Widget _buildStepsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_walk,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_selectedMember.name}的运动记录',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('8,432',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('步 / 目标10,000步',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.843,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF95D5B2)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('已完成 84.3%，继续加油！',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite_outline, color: AppColors.danger, size: 20),
                SizedBox(width: 8),
                Text('血压记录',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Spacer(),
                Text('今天 08:30',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text('收缩压',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('125',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger)),
                        Text('mmHg',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('/',
                      style: TextStyle(
                          fontSize: 28,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w300)),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text('舒张压',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('82',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2196F3))),
                        Text('mmHg',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      SizedBox(height: 2),
                      Text('正常',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallDetectionCard() {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.personal_injury_outlined,
              color: AppColors.success, size: 22),
        ),
        title: const Text('跌倒检测',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: const Text('实时监测异常跌倒动作',
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 14),
              SizedBox(width: 4),
              Text('已开启 · 正常',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
