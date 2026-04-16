import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/gamification_model.dart';

class StreakCard extends StatelessWidget {
  final GamificationModel g;
  const StreakCard({super.key, required this.g});

  @override
  Widget build(BuildContext context) {
    final today = _todayStr();
    final isActiveToday = g.lastActivityDate == today;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Flame icon with glow
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isActiveToday
                ? AppColors.streakOrange.withOpacity(0.12)
                : AppColors.grey100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              isActiveToday ? '🔥' : '💤',
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActiveToday
                    ? 'Série active !'
                    : 'Apprenez aujourd\'hui !',
                style: AppTextStyles.titleSmall.copyWith(
                  color: isActiveToday
                      ? AppColors.streakOrange
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isActiveToday
                    ? 'Continue comme ça — ${g.currentStreak} jour${g.currentStreak > 1 ? 's' : ''} de suite !'
                    : 'Ta série s\'arrêtera si tu n\'apprends pas aujourd\'hui.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // Streak numbers
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${g.currentStreak}',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: isActiveToday
                        ? AppColors.streakOrange
                        : AppColors.grey400,
                    fontSize: 30,
                  ),
                ),
                Text(
                  ' j',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              'Record : ${g.longestStreak}j',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  static String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
  }
}
