import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.tealLight.withOpacity(0.3),
      onSecondaryContainer: AppColors.tealDark,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      background: AppColors.background,
      onBackground: AppColors.onBackground,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.grey200,
      shadow: AppColors.shadow,
      scrim: AppColors.shadowMedium,
      inverseSurface: AppColors.grey900,
      onInverseSurface: AppColors.grey50,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Nunito',
      textTheme: _buildTextTheme(AppColors.onSurface),

      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.onSurface, size: 24),
      ),

      // ── Bottom Navigation ────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            );
          }
          return AppTextStyles.labelSmall.copyWith(color: AppColors.grey500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: AppColors.grey400, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Cards: shadow, no border ─────────────────────────────────────
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        shadowColor: AppColors.shadow,
      ),

      // ── Filled Button: pill shape ────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // ── Input ────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
        labelStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.onSurfaceVariant,
      ),

      // ── Chip ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.12),
        labelStyle: AppTextStyles.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
      ),

      // ── Progress ─────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
        linearMinHeight: 6,
      ),

      // ── Divider ──────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),

      // ── Dialog ───────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      scaffoldBackgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: AppColors.onSurface, size: 24),

      // ── Switch ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.grey400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.35);
          }
          return AppColors.grey200;
        }),
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.tealLight,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: AppColors.tealDark,
      onSecondaryContainer: AppColors.tealLight,
      tertiary: AppColors.accentLight,
      onTertiary: Colors.white,
      error: const Color(0xFFFF6B80),
      onError: AppColors.backgroundDark,
      errorContainer: const Color(0xFF6B0020),
      onErrorContainer: const Color(0xFFFF6B80),
      background: AppColors.backgroundDark,
      onBackground: AppColors.onBackgroundDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceVariant: AppColors.surfaceVariantDark,
      onSurfaceVariant: const Color(0xFFBBB3E0),
      outline: AppColors.outlineDark,
      outlineVariant: const Color(0xFF2A2448),
      shadow: Colors.black38,
      scrim: Colors.black54,
      inverseSurface: AppColors.grey100,
      onInverseSurface: AppColors.grey900,
      inversePrimary: AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Nunito',
      textTheme: _buildTextTheme(AppColors.onSurfaceDark),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onSurfaceDark,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primaryLight.withOpacity(0.15),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w800,
            );
          }
          return AppTextStyles.labelSmall.copyWith(color: AppColors.grey600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 24);
          }
          return const IconThemeData(color: AppColors.grey600, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color defaultColor) {
    return TextTheme(
      displayLarge:  AppTextStyles.displayLarge.copyWith(color: defaultColor),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: defaultColor),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: defaultColor),
      headlineMedium:AppTextStyles.headlineMedium.copyWith(color: defaultColor),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: defaultColor),
      titleLarge:    AppTextStyles.titleLarge.copyWith(color: defaultColor),
      titleMedium:   AppTextStyles.titleMedium.copyWith(color: defaultColor),
      titleSmall:    AppTextStyles.titleSmall.copyWith(color: defaultColor),
      bodyLarge:     AppTextStyles.bodyLarge.copyWith(color: defaultColor),
      bodyMedium:    AppTextStyles.bodyMedium.copyWith(color: defaultColor),
      bodySmall:     AppTextStyles.bodySmall,
      labelLarge:    AppTextStyles.labelLarge.copyWith(color: defaultColor),
      labelMedium:   AppTextStyles.labelMedium.copyWith(color: defaultColor),
      labelSmall:    AppTextStyles.labelSmall,
    );
  }
}
