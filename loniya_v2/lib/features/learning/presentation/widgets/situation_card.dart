import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/lesson_entity.dart';

class SituationCard extends StatelessWidget {
  final LessonEntity lesson;
  final Color subjectColor;

  const SituationCard({
    super.key,
    required this.lesson,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            subjectColor.withOpacity(0.12),
            subjectColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subjectColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: subjectColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Situation de départ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              lesson.gradeLevel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            lesson.situation,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
          if (lesson.competencies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Compétences visées :',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...lesson.competencies.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: AppTextStyles.caption.copyWith(
                            color: subjectColor)),
                    Expanded(
                      child: Text(c,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
