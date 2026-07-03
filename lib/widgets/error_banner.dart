import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const ErrorBanner({super.key, required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppColors.danger, size: 16),
          ),
        ],
      ),
    );
  }
}
