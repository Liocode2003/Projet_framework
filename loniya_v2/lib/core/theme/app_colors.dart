import 'package:flutter/material.dart';

/// Palette ocre-terres — identité visuelle yikri (Burkina Faso)
class AppColors {
  AppColors._();

  // ── Primaire : Ocre tradition ─────────────────────────────────────────
  static const Color primary      = Color(0xFFCC7722);
  static const Color primaryDark  = Color(0xFF8B5200);
  static const Color primaryLight = Color(0xFFE8A057);
  static const Color onPrimary    = Colors.white;

  // ── Accent : Rouge-terre vibrant ─────────────────────────────────────
  static const Color accent       = Color(0xFFD64B2A);
  static const Color accentDark   = Color(0xFF9E2F14);
  static const Color accentLight  = Color(0xFFEF8570);

  // ── Le Sage : Vert sagesse / savane ──────────────────────────────────
  static const Color sage         = Color(0xFF4A7C59);
  static const Color sageDark     = Color(0xFF2E5239);
  static const Color sageLight    = Color(0xFF7CB990);

  // ── Or : Crédits / récompenses ────────────────────────────────────────
  static const Color gold         = Color(0xFFF4A21C);
  static const Color goldDark     = Color(0xFFB87718);
  static const Color goldLight    = Color(0xFFFAC859);

  // ── Bleu céleste : info / achat ───────────────────────────────────────
  static const Color sky          = Color(0xFF3A82C4);
  static const Color skyDark      = Color(0xFF245F96);
  static const Color skyLight     = Color(0xFF72AFDF);

  // ── Surfaces (fond sable chaud) ───────────────────────────────────────
  static const Color background       = Color(0xFFFDF6ED);
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceVariant   = Color(0xFFF5E8D4);
  static const Color onBackground     = Color(0xFF1A0F06);
  static const Color onSurface        = Color(0xFF1A0F06);
  static const Color onSurfaceVariant = Color(0xFF6B4F30);

  // ── Surfaces sombres (nuit africaine) ─────────────────────────────────
  static const Color backgroundDark     = Color(0xFF1A0F06);
  static const Color surfaceDark        = Color(0xFF2A1A0A);
  static const Color surfaceVariantDark = Color(0xFF3D2A14);
  static const Color onBackgroundDark   = Color(0xFFFDF6ED);
  static const Color onSurfaceDark      = Color(0xFFFDF6ED);

  // ── Sémantiques ───────────────────────────────────────────────────────
  static const Color success      = Color(0xFF4A7C59);
  static const Color successLight = Color(0xFFD6EDDD);
  static const Color warning      = Color(0xFFF4A21C);
  static const Color warningLight = Color(0xFFFEF3D8);
  static const Color error        = Color(0xFFD64B2A);
  static const Color errorLight   = Color(0xFFFBE0D8);
  static const Color info         = Color(0xFF3A82C4);
  static const Color infoLight    = Color(0xFFD8EBFB);

  // ── Gamification ──────────────────────────────────────────────────────
  static const Color xpGold       = Color(0xFFF4A21C);
  static const Color xpSilver     = Color(0xFFC0C0C0);
  static const Color xpBronze     = Color(0xFFCD7F32);
  static const Color streakOrange = Color(0xFFD64B2A);
  static const Color levelPurple  = Color(0xFF7B5EA7);

  // ── Couleurs feature ──────────────────────────────────────────────────
  static const Color leSage       = Color(0xFF4A7C59);   // Le Sage IA
  static const Color marketplace  = Color(0xFFCC7722);   // Catalogue
  static const Color learning     = Color(0xFF3A82C4);   // Apprendre
  static const Color gamification = Color(0xFFF4A21C);   // Jeu / crédits
  static const Color orientation  = Color(0xFF7B5EA7);   // Orientation
  static const Color teacher      = Color(0xFF4A7C59);   // Enseignant
  static const Color localNetwork = Color(0xFFD64B2A);   // Wi-Fi Classe
  static const Color credits      = Color(0xFFF4A21C);   // Monnaie crédits
  static const Color aiTutor      = Color(0xFF4A7C59);   // alias Le Sage

  // ── Neutrals ──────────────────────────────────────────────────────────
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Teal (Classe Connectée / enseignant) ─────────────────────────────
  static const Color teal     = Color(0xFF00958A);
  static const Color tealDark = Color(0xFF006B62);

  // ── Outline / Shadow ──────────────────────────────────────────────────
  static const Color outline      = Color(0xFFE8D4BA);
  static const Color outlineDark  = Color(0xFF4A3020);
  static const Color shadow       = Color(0x28CC7722);
  static const Color shadowMedium = Color(0x44CC7722);
}
