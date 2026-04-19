import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/badge_model.dart';

class BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  const BadgeCard({super.key, required this.badge});

  static const _categoryColors = {
    'streak':    AppColors.streakOrange,
    'subject':   AppColors.primary,
    'milestone': AppColors.levelPurple,
    'special':   AppColors.info,
  };

  static const _categoryIcons = {
    'streak':    Icons.local_fire_department_rounded,
    'subject':   Icons.book_rounded,
    'milestone': Icons.emoji_events_rounded,
    'special':   Icons.auto_awesome_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color  = _categoryColors[badge.category] ?? AppColors.grey500;
    final icon   = _categoryIcons[badge.category] ?? Icons.star_rounded;
    final locked = !badge.isUnlocked;

    return GestureDetector(
      onTap: () => _showDetail(context, color, icon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: locked ? AppColors.grey100 : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: locked
                ? AppColors.grey200
                : color.withOpacity(0.3),
            width: locked ? 1 : 1.5,
          ),
          boxShadow: locked
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.grey200
                    : color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: locked
                  ? const Icon(Icons.lock_rounded,
                      color: AppColors.grey400, size: 22)
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              badge.title,
              style: AppTextStyles.labelSmall.copyWith(
                color: locked
                    ? AppColors.grey400
                    : AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // XP or unlocked date
            if (!locked)
              Text(
                '+${badge.xpReward} XP',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.xpGold,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                badge.condition.length > 22
                    ? '${badge.condition.substring(0, 22)}…'
                    : badge.condition,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey400,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? color.withOpacity(0.12)
                    : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: badge.isUnlocked
                  ? Icon(icon, color: color, size: 30)
                  : const Icon(Icons.lock_rounded,
                      color: AppColors.grey400, size: 28),
            ),
            const SizedBox(height: 12),
            Text(badge.title,
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(badge.description,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (!badge.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Condition : ${badge.condition}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.warning),
                ),
              ),
            ] else ...[
              Text(
                '+${badge.xpReward} XP · Débloqué',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.success),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
