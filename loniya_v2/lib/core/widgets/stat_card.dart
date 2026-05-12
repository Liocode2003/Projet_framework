import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared stat display card — replaces 4 near-identical private _StatCard widgets
/// across home, performance, lesson_result and profile screens.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.onSurface, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
