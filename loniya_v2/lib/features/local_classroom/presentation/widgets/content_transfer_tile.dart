import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/shared_content.dart';

class ContentTransferTile extends StatelessWidget {
  final SharedContent content;
  final double? progress;     // null = idle, 0.0..1.0 = downloading
  final bool isDownloaded;
  final VoidCallback? onDownload;

  const ContentTransferTile({
    super.key,
    required this.content,
    this.progress,
    this.isDownloaded = false,
    this.onDownload,
  });

  bool get _isDownloading => progress != null;

  Color get _typeColor {
    switch (content.type) {
      case 'lesson':
        return AppColors.learning;
      case 'exercise':
        return AppColors.warning;
      case 'video':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  IconData get _typeIcon {
    switch (content.type) {
      case 'lesson':
        return Icons.menu_book_rounded;
      case 'exercise':
        return Icons.edit_note_rounded;
      case 'video':
        return Icons.play_circle_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.title,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${content.subject} · ${content.gradeLevel} · ${content.formattedSize}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ActionWidget(
                isDownloaded: isDownloaded,
                isDownloading: _isDownloading,
                onDownload: onDownload,
              ),
            ]),
            if (_isDownloading) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.grey200,
                  color: AppColors.localNetwork,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${((progress ?? 0) * 100).round()}%',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.localNetwork),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionWidget extends StatelessWidget {
  final bool isDownloaded;
  final bool isDownloading;
  final VoidCallback? onDownload;

  const _ActionWidget({
    required this.isDownloaded,
    required this.isDownloading,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloaded) {
      return const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 28);
    }
    if (isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.localNetwork,
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download_rounded,
          color: AppColors.localNetwork),
      onPressed: onDownload,
      tooltip: 'Recevoir',
    );
  }
}
