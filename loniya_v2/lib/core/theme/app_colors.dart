import 'package:flutter/material.dart';

/// LONIYA V2 Color Palette
/// Inspired by Burkina Faso cultural colors — warm, vibrant, accessible
class AppColors {
  AppColors._();

  // ─── Brand Colors ────────────────────────────────────────────────────
  /// Primary: Warm amber/gold — represents knowledge, sun, education
  static const Color primary = Color(0xFFE8A020);
  static const Color primaryDark = Color(0xFFC4841A);
  static const Color primaryLight = Color(0xFFFFC84A);
  static const Color onPrimary = Color(0xFF1A1A1A);

  /// Secondary: Deep green — represents growth, learning, nature
  static const Color secondary = Color(0xFF2D7D32);
  static const Color secondaryDark = Color(0xFF1B5E20);
  static const Color secondaryLight = Color(0xFF4CAF50);
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Tertiary: Warm terracotta — African earth tones
  static const Color tertiary = Color(0xFFBF360C);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // ─── Surface Colors ──────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F0E8);
  static const Color onBackground = Color(0xFF1C1B19);
  static const Color onSurface = Color(0xFF1C1B19);
  static const Color onSurfaceVariant = Color(0xFF4E4639);

  // ─── Dark Theme Surfaces ─────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF1A1812);
  static const Color surfaceDark = Color(0xFF252018);
  static const Color surfaceVariantDark = Color(0xFF332D22);
  static const Color onBackgroundDark = Color(0xFFEDE8E0);
  static const Color onSurfaceDark = Color(0xFFEDE8E0);

  // ─── Semantic Colors ─────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFB71C1C);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ─── Gamification Colors ─────────────────────────────────────────────
  static const Color xpGold = Color(0xFFFFD700);
  static const Color xpSilver = Color(0xFFC0C0C0);
  static const Color xpBronze = Color(0xFFCD7F32);
  static const Color streakOrange = Color(0xFFFF6D00);
  static const Color levelPurple = Color(0xFF6A1B9A);

  // ─── Feature Colors ──────────────────────────────────────────────────
  static const Color marketplace = Color(0xFF1565C0);
  static const Color learning = Color(0xFF2D7D32);
  static const Color aiTutor = Color(0xFF6A1B9A);
  static const Color gamification = Color(0xFFE65100);
  static const Color orientation = Color(0xFF00695C);
  static const Color teacher = Color(0xFF0277BD);
  static const Color localNetwork = Color(0xFF37474F);

  // ─── Neutral Scale ───────────────────────────────────────────────────
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ─── Outline ─────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFD4C8B8);
  static const Color outlineDark = Color(0xFF4A4030);

  // ─── Shadow ──────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
}
