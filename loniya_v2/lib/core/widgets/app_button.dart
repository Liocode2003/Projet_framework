import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { filled, outlined, text }

/// Reusable button — consistent style across all screens.
/// Supports loading state, icon prefix, and full-width layout.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? prefixIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.isLoading = false,
    this.fullWidth = true,
    this.prefixIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = Size(fullWidth ? double.infinity : 0, height ?? 52);

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.filled
                    ? colorScheme.onPrimary
                    : colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.button),
            ],
          );

    switch (variant) {
      case AppButtonVariant.filled:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
          child: child,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            foregroundColor: foregroundColor ?? colorScheme.primary,
          ),
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: size,
            foregroundColor: foregroundColor ?? colorScheme.primary,
          ),
          child: child,
        );
    }
  }
}
