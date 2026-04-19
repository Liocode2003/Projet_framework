import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ScoreBarChart extends StatelessWidget {
  final Map<String, double> scores;

  const ScoreBarChart({super.key, required this.scores});

  Color _barColor(double score) {
    if (score >= 14) return AppColors.success;
    if (score >= 10) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RepaintBoundary(
      child: Column(
      children: sorted.map((e) {
        final color = _barColor(e.value);
        final pct   = e.value / 20;
        // Abbreviate long subject names
        final label = e.key.length > 16
            ? '${e.key.substring(0, 14)}.'
            : e.key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.grey200,
                    color: color,
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${e.value.toStringAsFixed(0)}/20',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
    );
  }
}
