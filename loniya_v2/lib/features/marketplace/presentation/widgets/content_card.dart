import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/content_entity.dart';
import '../providers/marketplace_provider.dart';

class ContentCard extends ConsumerWidget {
  final ContentEntity content;
  final VoidCallback? onTap;

  const ContentCard({super.key, required this.content, this.onTap});

  static const _subjectColors = {
    'Mathématiques':      AppColors.primary,
    'Français':           AppColors.secondary,
    'Sciences':           AppColors.orientation,
    'Histoire-Géographie': AppColors.tertiary,
    'Physique-Chimie':    AppColors.aiTutor,
    'Anglais':            AppColors.teacher,
  };

  Color get _color => _subjectColors[content.subject] ?? AppColors.grey500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlState = ref.watch(downloadNotifierProvider)[content.id];
    final isDownloading = dlState?.isDownloading ?? false;
    final progress = dlState?.progress ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Subject icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  content.subject.substring(0, 1),
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: _color, fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + download badge
                  Row(children: [
                    Expanded(
                      child: Text(content.title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    ),
                    if (content.isDownloaded)
                      const Icon(Icons.download_done_rounded,
                          color: AppColors.success, size: 18),
                  ]),
                  const SizedBox(height: 4),

                  // Chips row
                  Wrap(spacing: 6, children: [
                    _Chip(content.gradeLevel, AppColors.grey600),
                    _Chip(content.typeLabel, _color),
                    _Chip(content.formattedSize, AppColors.grey500),
                  ]),

                  // Download progress bar
                  if (isDownloading) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.grey200,
                        color: _color,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Rating
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.xpGold, size: 14),
                const SizedBox(width: 2),
                Text(content.rating.toStringAsFixed(1),
                    style: AppTextStyles.labelSmall),
              ]),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.grey400, size: 20),
            ]),
          ]),
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
