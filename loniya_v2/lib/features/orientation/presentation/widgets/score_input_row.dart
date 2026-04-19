import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ScoreInputRow extends StatelessWidget {
  final String subject;
  final double score;
  final int coefficient;
  final void Function(double) onChanged;

  const ScoreInputRow({
    super.key,
    required this.subject,
    required this.score,
    required this.coefficient,
    required this.onChanged,
  });

  Color get _scoreColor {
    if (score >= 16) return AppColors.success;
    if (score >= 14) return AppColors.secondaryLight;
    if (score >= 12) return AppColors.info;
    if (score >= 10) return AppColors.warning;
    return AppColors.error;
  }

  String get _mention {
    if (score >= 16) return 'TB';
    if (score >= 14) return 'B';
    if (score >= 12) return 'AB';
    if (score >= 10) return 'P';
    return 'I';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(subject, style: AppTextStyles.labelMedium),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('coeff $coefficient',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey500)),
            ),
            const SizedBox(width: 10),
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _scoreColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: _scoreColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _mention,
                    style: AppTextStyles.caption.copyWith(
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: _scoreColor,
              inactiveTrackColor: _scoreColor.withOpacity(0.15),
              thumbColor: _scoreColor,
              overlayColor: _scoreColor.withOpacity(0.1),
            ),
            child: Slider(
              value: score,
              min: 0,
              max: 20,
              divisions: 40, // 0.5 steps
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
