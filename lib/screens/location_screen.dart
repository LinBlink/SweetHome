import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置守护'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapPlaceholder(context),
            const SizedBox(height: 12),
            _buildMemberLocationCards(context),
            const SizedBox(height: 12),
            _buildRecentEvents(context),
            const SizedBox(height: 12),
            _buildGeofences(context),
            const SizedBox(height: 12),
            _buildSOSButton(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B8CAE), Color(0xFF8FA8C5), Color(0xFFB8CCD8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Grid lines simulating map
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 250),
            painter: _MapGridPainter(),
          ),
          // Geofence circle (home area)
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5), width: 2),
                color: AppColors.success.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Member dots
          _buildMemberDot(0.15, 0.25, mockFamily[0]),   // dad - company
          _buildMemberDot(0.5, 0.45, mockFamily[1]),    // mom - home
          _buildMemberDot(0.25, 0.65, mockFamily[2]),   // son - school
          _buildMemberDot(0.3, 0.7, mockFamily[3]),     // daughter - school
          _buildMemberDot(0.62, 0.35, mockFamily[4]),   // grandpa - park
          _buildMemberDot(0.55, 0.48, mockFamily[5]),   // grandma - home
          // Watermark
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '模拟地图',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ),
          ),
          // Safe zone label
          const Positioned(
            top: 12,
            left: 12,
            child: _MapBadge(
              icon: Icons.home,
              label: '家庭安全区',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDot(
      double relX, double relY, FamilyMember member) {
    return Positioned(
      left: relX * 350,
      top: relY * 230,
      child: Tooltip(
        message: '${member.name} · ${member.currentLocation}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: member.avatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  member.avatarLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                member.name,
                style:
                    const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberLocationCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '成员位置',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...mockFamily.map((member) => _buildMemberLocationCard(member)),
        ],
      ),
    );
  }

  Widget _buildMemberLocationCard(FamilyMember member) {
    final isHome = member.currentLocation == '家';
    final isSafe = member.currentLocation != '未知';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: member.avatarColor,
                  child: Text(member.avatarLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.role,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        member.currentLocation,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (!isHome) ...[
                        const SizedBox(width: 6),
                        const Text(
                          '距家约2.3公里',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSafe
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSafe ? Icons.check_circle : Icons.warning,
                    size: 12,
                    color:
                        isSafe ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isSafe ? '安全' : '注意',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSafe ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEvents(BuildContext context) {
    final events = [
      {
        'icon': Icons.school,
        'color': AppColors.success,
        'text': '王小明 已到达学校',
        'time': '08:30',
      },
      {
        'icon': Icons.school,
        'color': AppColors.success,
        'text': '王小雨 已到达学校',
        'time': '08:45',
      },
      {
        'icon': Icons.directions_walk,
        'color': AppColors.warning,
        'text': '王福海 已离开小区 → 小区公园',
        'time': '09:15',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '安全事件',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: events.map((e) {
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            (e['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e['icon'] as IconData,
                          color: e['color'] as Color, size: 18),
                    ),
                    title: Text(e['text'] as String,
                        style: const TextStyle(fontSize: 13)),
                    trailing: Text(
                      e['time'] as String,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofences(BuildContext context) {
    final fences = [
      {'name': '学校', 'icon': Icons.school, 'active': true},
      {'name': '家', 'icon': Icons.home, 'active': true},
      {'name': '小明游泳馆', 'icon': Icons.pool, 'active': true},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '安全围栏',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加', style: TextStyle(fontSize: 12)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: fences.map((f) {
              return Expanded(
                child: Card(
                  margin: const EdgeInsets.only(right: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(f['icon'] as IconData,
                              color: AppColors.success, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '已开启',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('紧急SOS · 模拟触发（实际功能开发中）'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sos, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                '紧急 SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Road lines
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 6;
    canvas.drawLine(
        Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), roadPaint);
    canvas.drawLine(
        Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MapBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
