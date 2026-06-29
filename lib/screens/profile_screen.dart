import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('王家'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFamilyBanner(context),
            const SizedBox(height: 16),
            _buildFamilyTree(context),
            const SizedBox(height: 16),
            _buildMembersList(context),
            const SizedBox(height: 16),
            _buildSettings(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyBanner(BuildContext context) {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight, Color(0xFF6B8CAE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.house_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '王家',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '成立于 2008年 · 6位成员',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '🏆 家庭积分：2,840分',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTree(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '家庭族谱',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Grandparents
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTreeNode(mockFamily[4]), // grandpa
                      const SizedBox(width: 8),
                      _buildTreeConnector(horizontal: true),
                      const SizedBox(width: 8),
                      _buildTreeNode(mockFamily[5]), // grandma
                    ],
                  ),
                  _buildTreeConnector(horizontal: false, height: 20),
                  // Parents
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTreeNode(mockFamily[0]), // dad
                      const SizedBox(width: 8),
                      _buildTreeConnector(horizontal: true),
                      const SizedBox(width: 8),
                      _buildTreeNode(mockFamily[1]), // mom
                    ],
                  ),
                  _buildTreeConnector(horizontal: false, height: 20),
                  // Children
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTreeNode(mockFamily[2]), // son
                      const SizedBox(width: 32),
                      _buildTreeNode(mockFamily[3]), // daughter
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(FamilyMember member) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: member.avatarColor,
          child: Text(
            member.avatarLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          member.name,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary),
        ),
        Text(
          member.role,
          style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTreeConnector({required bool horizontal, double height = 1}) {
    if (horizontal) {
      return SizedBox(
        width: 20,
        child: Divider(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          thickness: 1.5,
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          width: 1.5,
          color: AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildMembersList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '家庭成员',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('邀请', style: TextStyle(fontSize: 12)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: mockFamily.asMap().entries.map((entry) {
                final i = entry.key;
                final member = entry.value;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: member.avatarColor,
                            child: Text(member.avatarLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (member.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Text(member.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.avatarColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(member.role,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: member.avatarColor,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${member.age}岁 · ${member.currentLocation}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                      onTap: () {},
                    ),
                    if (i < mockFamily.length - 1)
                      const Divider(
                          height: 0, indent: 72, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final settings = [
      {'icon': Icons.lock_outline, 'label': '隐私与权限', 'color': const Color(0xFF2196F3)},
      {'icon': Icons.cloud_download_outlined, 'label': '数据备份导出', 'color': AppColors.success},
      {'icon': Icons.notifications_outlined, 'label': '通知设置', 'color': AppColors.warning},
      {'icon': Icons.child_care_outlined, 'label': '儿童管控', 'color': const Color(0xFF9C27B0)},
      {'icon': Icons.info_outline, 'label': '关于过家家', 'color': AppColors.textSecondary},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '家庭设置',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: settings.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (s['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s['icon'] as IconData,
                            color: s['color'] as Color, size: 18),
                      ),
                      title: Text(s['label'] as String,
                          style: const TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary, size: 18),
                      onTap: () {},
                    ),
                    if (i < settings.length - 1)
                      const Divider(height: 0, indent: 68, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text('过家家 Sweet Home',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text('版本 1.0.0 Beta',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
