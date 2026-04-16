import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Expandable panel that reveals hints one by one.
class HintPanel extends StatefulWidget {
  final List<String> hints;

  const HintPanel({super.key, required this.hints});

  @override
  State<HintPanel> createState() => _HintPanelState();
}

class _HintPanelState extends State<HintPanel> {
  int _revealed = 0;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Header / toggle
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Text(
                  _revealed == 0
                      ? 'Indices disponibles (${widget.hints.length})'
                      : 'Indices ($_revealed/${widget.hints.length})',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.info),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.info, size: 20,
                ),
              ]),
            ),
          ),

          // Revealed hints
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0x22000000)),
            ...List.generate(
              _revealed,
              (i) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.info)),
                    Expanded(
                      child: Text(widget.hints[i],
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.onSurface)),
                    ),
                  ],
                ),
              ),
            ),

            // "Show next hint" button
            if (_revealed < widget.hints.length)
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextButton.icon(
                  onPressed: () => setState(() => _revealed++),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text(
                    _revealed == 0 ? 'Voir le 1er indice' : 'Indice suivant',
                    style: AppTextStyles.labelMedium,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.info,
                  ),
                ),
              ),
            if (_revealed > 0)
              const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
