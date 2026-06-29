import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('家庭账本'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '账单'),
              Tab(text: '预算'),
              Tab(text: '儿童'),
            ],
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),
        ),
        body: const TabBarView(
          children: [
            _BillTab(),
            _BudgetTab(),
            _ChildTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: 账单 ──────────────────────────────────────────────────────────────

class _BillTab extends StatelessWidget {
  const _BillTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 12),
        _buildSpendingBars(),
        const SizedBox(height: 16),
        const Text(
          '近期账单',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...mockTransactions.map((t) => _buildTransactionItem(t)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '6月支出',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              '¥8,432',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('收入', '¥18,500', Colors.white70),
                ),
                const SizedBox(
                    height: 30,
                    child: VerticalDivider(color: Colors.white24)),
                Expanded(
                  child: _buildSummaryItem('结余', '+¥10,068', AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSpendingBars() {
    final categories = [
      ('餐饮', 0.35, AppColors.warning),
      ('教育', 0.40, AppColors.danger),
      ('交通', 0.05, const Color(0xFF00BCD4)),
      ('娱乐', 0.08, const Color(0xFFE91E63)),
      ('百货', 0.12, const Color(0xFF2196F3)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支出构成',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: categories.map((cat) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 80 * cat.$2,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: cat.$3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(cat.$1,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: t.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(t.icon, color: t.color, size: 22),
        ),
        title: Text(t.title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${t.category} · ${t.time}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${t.isExpense ? '-' : '+'}¥${t.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.isExpense ? AppColors.danger : AppColors.success,
              ),
            ),
            Text(
              t.payer,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: 预算 ──────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  const _BudgetTab();

  @override
  Widget build(BuildContext context) {
    final overBudget =
        mockBudgets.where((b) => b.ratio > 1.0).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overBudget.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${overBudget.map((b) => b.name).join('、')} 超支 ¥${(overBudget.fold(0.0, (a, b) => a + (b.spent - b.budget))).toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        const Text(
          '本月预算使用情况',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...mockBudgets.map((b) => _buildBudgetItem(b)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBudgetItem(BudgetCategory b) {
    final isOver = b.ratio > 1.0;
    final ratio = isOver ? 1.0 : b.ratio;
    final barColor = isOver ? AppColors.danger : b.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(b.icon, color: barColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${b.spent.toStringAsFixed(0)} / ¥${b.budget.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isOver ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                    if (isOver)
                      Text(
                        '超出 ¥${(b.spent - b.budget).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.danger),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: 儿童 ──────────────────────────────────────────────────────────────

class _ChildTab extends StatelessWidget {
  const _ChildTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '儿童财商',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildChildCard(
          name: '王小明',
          avatarLabel: '明',
          avatarColor: const Color(0xFF2196F3),
          allowance: 200,
          used: 120,
          savingGoal: 'Switch游戏机',
          savingTarget: 500,
          savingSaved: 280,
          coins: 45,
        ),
        const SizedBox(height: 10),
        _buildChildCard(
          name: '王小雨',
          avatarLabel: '雨',
          avatarColor: const Color(0xFF9C27B0),
          allowance: 100,
          used: 38,
          savingGoal: '芭比娃娃套装',
          savingTarget: 200,
          savingSaved: 72,
          coins: 28,
        ),
        const SizedBox(height: 16),
        _buildLearnSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildChildCard({
    required String name,
    required String avatarLabel,
    required Color avatarColor,
    required double allowance,
    required double used,
    required String savingGoal,
    required double savingTarget,
    required double savingSaved,
    required int coins,
  }) {
    final remaining = allowance - used;
    final savingRatio = savingSaved / savingTarget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor,
                  child: Text(avatarLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: AppColors.warning, size: 14),
                      const SizedBox(width: 3),
                      Text('$coins 金币',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 赚-存-花 indicator
            Row(
              children: [
                Expanded(
                  child: _buildMoneySection('赚', '任务奖励', const Color(0xFF4CAF50)),
                ),
                Expanded(
                  child: _buildMoneySection('存', '¥${savingSaved.toStringAsFixed(0)}', const Color(0xFF2196F3)),
                ),
                Expanded(
                  child: _buildMoneySection('花', '¥${used.toStringAsFixed(0)}', AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 本月零花钱
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('本月零花钱',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('¥${used.toStringAsFixed(0)} / ¥${allowance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: used / allowance,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('剩余 ¥${remaining.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            // 储蓄目标
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.savings, size: 16, color: Color(0xFF2196F3)),
                      const SizedBox(width: 6),
                      Text(
                        '储蓄目标：$savingGoal',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBBCFFF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: savingRatio.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${savingSaved.toStringAsFixed(0)} / ¥${savingTarget.toStringAsFixed(0)} (${(savingRatio * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneySection(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLearnSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
                SizedBox(width: 6),
                Text(
                  '财商小课堂',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildLearnItem('💰', '小明完成了「认识钱币」课程', '昨天'),
            _buildLearnItem('🛒', '小雨学会了「比价购物」技巧', '3天前'),
            _buildLearnItem('🏦', '小明解锁「银行存款」知识章节', '1周前'),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnItem(String emoji, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
          Text(time,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
