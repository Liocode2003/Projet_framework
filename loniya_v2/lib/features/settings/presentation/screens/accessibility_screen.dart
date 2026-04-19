import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';

class AccessibilityScreen extends ConsumerWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Accessibilité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Visual ────────────────────────────────────────────────────
          _Card(
            icon: Icons.contrast_rounded,
            iconColor: AppColors.onBackground,
            title: 'Contraste élevé',
            subtitle:
                'Fond noir avec texte jaune — optimal pour malvoyants',
            trailing: Switch(
              value: settings.isHighContrast,
              onChanged: (_) => notifier.toggleHighContrast(),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.text_increase_rounded,
            iconColor: AppColors.primary,
            title: 'Texte agrandi',
            subtitle: 'Augmente la taille du texte de 30 % dans toute l\'app',
            trailing: Switch(
              value: settings.isLargeText,
              onChanged: (_) => notifier.toggleLargeText(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Audio / Voice ─────────────────────────────────────────────
          _Card(
            icon: Icons.record_voice_over_rounded,
            iconColor: AppColors.aiTutor,
            title: 'Navigation vocale',
            subtitle:
                'Le tuteur IA lit automatiquement chaque réponse à voix haute',
            trailing: Switch(
              value: settings.voiceReadingEnabled,
              onChanged: (_) => notifier.toggleVoiceReading(),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.volume_up_rounded,
            iconColor: AppColors.secondary,
            title: 'Lecture TTS',
            subtitle: 'Lit le contenu des leçons à voix haute',
            trailing: Switch(
              value: settings.ttsEnabled,
              onChanged: (_) => notifier.toggleTts(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Info ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ces paramètres sont conçus pour les élèves malvoyants. '
                    'Le mode contraste élevé remplace toute la palette de couleurs '
                    'par un thème à fort contraste.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _Card({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: AppTextStyles.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
        trailing,
      ]),
    );
  }
}
