import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String label;
  final Color color;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.label,
    required this.color,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        label.length > 1 ? label.substring(0, 1) : label,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class GroupAvatarWidget extends StatelessWidget {
  final String label;
  final int memberCount;
  final double radius;

  const GroupAvatarWidget({
    super.key,
    required this.label,
    required this.memberCount,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.75,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$memberCount',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
