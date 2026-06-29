import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class OAScreen extends StatelessWidget {
  const OAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('家庭审批'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '待处理'),
              Tab(text: '历史记录'),
            ],
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingTab(),
            _HistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('发起审批',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── Quick Templates Row ──────────────────────────────────────────────────────

class _QuickTemplates extends StatelessWidget {
  const _QuickTemplates();

  @override
  Widget build(BuildContext context) {
    final templates = ['申请零花钱', '出行申请', '购物申请', '学费申请', '家庭会议'];
    final icons = [
      Icons.savings,
      Icons.luggage,
      Icons.shopping_bag,
      Icons.school,
      Icons.groups,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速发起',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(templates.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(icons[i], size: 16, color: AppColors.primary),
                    label: Text(templates[i],
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    onPressed: () {},
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: 待处理 ────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    final pendingRequests =
        mockOARequests.where((r) => r.status == 'pending').toList();
    final toReview =
        pendingRequests.where((r) => r.approvers.contains('dad')).toList();
    final myRequests =
        pendingRequests.where((r) => r.applicantId == 'dad').toList();

    return ListView(
      children: [
        const _QuickTemplates(),
        const Divider(height: 1),
        if (toReview.isNotEmpty) ...[
          _buildSectionHeader('待我审批', toReview.length),
          ...toReview.map((r) => _buildOACard(context, r, showActions: true)),
        ],
        if (myRequests.isNotEmpty) ...[
          _buildSectionHeader('我的申请', myRequests.length),
          ...myRequests.map((r) => _buildOACard(context, r, showActions: false)),
        ],
        if (toReview.isEmpty && myRequests.isEmpty)
          const _EmptyState(message: '暂无待处理的审批'),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
            child: Center(
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: 历史记录 ──────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final historyRequests =
        mockOARequests.where((r) => r.status != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (historyRequests.isEmpty)
          const _EmptyState(message: '暂无历史记录')
        else
          ...historyRequests
              .map((r) => _buildOACard(context, r, showActions: false)),
      ],
    );
  }
}

// ─── OA Card ─────────────────────────────────────────────────────────────────

Widget _buildOACard(BuildContext context, OARequest request,
    {required bool showActions}) {
  final bool isDualSign = request.approvers.length > 1;
  final bool isLargeAmount = request.amount != null &&
      double.tryParse(request.amount!
              .replaceAll('¥', '')
              .replaceAll(',', '')
              .split('/')[0]) !=
          null &&
      (double.tryParse(request.amount!
                  .replaceAll('¥', '')
                  .replaceAll(',', '')
                  .split('/')[0]) ??
              0) >
          1000;

  final statusConfig = {
    'pending': {'label': '待审批', 'color': AppColors.warning},
    'approved': {'label': '已通过', 'color': AppColors.success},
    'rejected': {'label': '已驳回', 'color': AppColors.danger},
  };

  final config = statusConfig[request.status]!;
  final member = mockFamily.firstWhere(
    (m) => m.id == request.applicantId,
    orElse: () => mockFamily[0],
  );

  return Card(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: isLargeAmount && request.status == 'pending'
          ? const BorderSide(color: AppColors.warning, width: 1.5)
          : BorderSide.none,
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.category,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 6),
              if (isDualSign && request.status == 'pending')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user,
                          size: 10, color: AppColors.danger),
                      SizedBox(width: 3),
                      Text('双签',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (config['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  config['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: config['color'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            request.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Applicant row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: member.avatarColor,
                child: Text(member.avatarLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text(request.applicant,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text('发起',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              if (request.amount != null)
                Text(
                  request.amount!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Reason
          Text(
            request.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.submittedTime,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          if (showActions && request.status == 'pending') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已驳回申请'),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('驳回'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已批准申请'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success.withValues(alpha: 0.15),
                      foregroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('通过',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
          if (!showActions && request.status != 'pending') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  request.status == 'approved'
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 14,
                  color: config['color'] as Color,
                ),
                const SizedBox(width: 4),
                Text(
                  request.status == 'approved' ? '已批准 · 王建国' : '已驳回 · 王建国',
                  style: TextStyle(
                      fontSize: 11, color: config['color'] as Color),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
