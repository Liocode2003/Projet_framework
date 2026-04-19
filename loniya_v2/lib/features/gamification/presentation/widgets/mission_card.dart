import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/daily_mission.dart';

class MissionCard extends StatelessWidget {
  final DailyMission mission;
  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final color = mission.color;
    final done  = mission.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.success.withOpacity(0.4)
              : color.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Icon circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: done
                ? AppColors.success.withOpacity(0.1)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            done ? Icons.check_circle_rounded : mission.icon,
            color: done ? AppColors.success : color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    mission.title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: done
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  '+${mission.xpReward} XP',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: done ? AppColors.success : AppColors.xpGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: mission.progress,
                  backgroundColor: AppColors.grey200,
                  color: done ? AppColors.success : color,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                done
                    ? 'Mission accomplie !'
                    : '${mission.current} / ${mission.target}',
                style: AppTextStyles.caption.copyWith(
                  color: done
                      ? AppColors.success
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
