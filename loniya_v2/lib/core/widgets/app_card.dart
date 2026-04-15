import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable card widget — consistent border-radius and shadow across all features.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 16,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: showBorder
              ? BoxDecoration(
                  border: Border.all(color: AppColors.outline, width: 1),
                  borderRadius: BorderRadius.circular(borderRadius),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}
