import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/progress_model.dart';
import '../../domain/entities/lesson_entity.dart';

class LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final ProgressModel? progress;
  final Color subjectColor;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.subjectColor,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress?.isCompleted ?? false;
    final isStarted   = progress != null && !isCompleted;
    final pct         = progress != null
        ? progress!.completedSteps.length / lesson.totalSteps
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Subject icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      lesson.subject.substring(0, 1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: subjectColor,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(lesson.title,
                              style: AppTextStyles.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isCompleted)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 20),
                      ]),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: [
                        _Chip(lesson.gradeLevel, AppColors.grey600),
                        _Chip(lesson.subject, subjectColor),
                        _Chip(lesson.formattedDuration, AppColors.grey500),
                        _Chip('+${lesson.totalXp} XP', AppColors.xpGold),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey400, size: 22),
              ]),

              // Progress bar (if started)
              if (isStarted || isCompleted) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isCompleted ? 1.0 : pct,
                        backgroundColor: AppColors.grey200,
                        color: isCompleted
                            ? AppColors.success
                            : subjectColor,
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted
                        ? 'Terminé'
                        : '${(pct * 100).toInt()}%',
                    style: AppTextStyles.caption.copyWith(
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
