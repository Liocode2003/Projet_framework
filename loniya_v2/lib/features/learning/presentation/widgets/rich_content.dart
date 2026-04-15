import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

/// Renders lesson content with simple **bold** and `code` markdown.
class RichContent extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const RichContent(this.text, {super.key, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parse(text, baseStyle ?? AppTextStyles.bodyMedium),
    );
  }

  TextSpan _parse(String raw, TextStyle base) {
    final children = <InlineSpan>[];
    final segments = raw.split('\n');

    for (int si = 0; si < segments.length; si++) {
      if (si > 0) children.add(const TextSpan(text: '\n'));
      final line = segments[si];
      children.addAll(_parseLine(line, base));
    }

    return TextSpan(children: children, style: base);
  }

  List<InlineSpan> _parseLine(String line, TextStyle base) {
    // Handle $$ math blocks (show as monospace highlighted box)
    if (line.trim().startsWith(r'$$') && line.trim().endsWith(r'$$')) {
      final formula = line.trim().replaceAll(r'$$', '').trim();
      return [
        WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              formula,
              style: base.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ];
    }

    return _parseInline(line, base);
  }

  List<InlineSpan> _parseInline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    // Regex: **bold** parts
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: base.copyWith(fontWeight: FontWeight.w800),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }
}
