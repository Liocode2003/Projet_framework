import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/cache/cache_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final storageAsync = ref.watch(storageReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // ── Apparence ─────────────────────────────────────────────────
          _SectionHeader('Apparence'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: const Text('Mode sombre'),
            value: settings.darkMode,
            onChanged: (_) => notifier.toggleDarkMode(),
          ),

          // ── Accessibilité ─────────────────────────────────────────────
          _SectionHeader('Accessibilité'),
          ListTile(
            leading: const Icon(Icons.accessibility_new_rounded,
                color: AppColors.aiTutor),
            title: const Text('Options d\'accessibilité'),
            subtitle: const Text('Contraste élevé, grands textes, voix'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RouteNames.accessibility),
          ),

          // ── Audio / TTS ────────────────────────────────────────────────
          _SectionHeader('Audio'),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over_rounded),
            title: const Text('Lecture vocale (TTS)'),
            subtitle: const Text('Lit les réponses de l\'IA à voix haute'),
            value: settings.ttsEnabled,
            onChanged: (_) => notifier.toggleTts(),
          ),
          if (settings.ttsEnabled)
            ListTile(
              leading: const Icon(Icons.speed_rounded),
              title: const Text('Vitesse de lecture'),
              subtitle: Slider(
                value: settings.ttsSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '×${settings.ttsSpeed.toStringAsFixed(1)}',
                onChanged: (v) => notifier.setTtsSpeed(v),
              ),
            ),

          // ── Langue ────────────────────────────────────────────────────
          _SectionHeader('Langue'),
          RadioListTile<String>(
            title: const Text('Français'),
            value: 'fr',
            groupValue: settings.language,
            onChanged: (v) => notifier.setLanguage(v!),
          ),
          RadioListTile<String>(
            title: const Text('Bambara (bm)'),
            value: 'bm',
            groupValue: settings.language,
            onChanged: (v) => notifier.setLanguage(v!),
          ),

          // ── Stockage ──────────────────────────────────────────────────
          _SectionHeader('Stockage'),
          storageAsync.when(
            loading: () => const ListTile(
              title: Text('Calcul en cours…'),
              leading: Icon(Icons.storage_rounded),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (report) => ListTile(
              leading: const Icon(Icons.storage_rounded),
              title: const Text('Espace utilisé'),
              subtitle:
                  Text('${report.formattedTotal} (contenus + rapports)'),
            ),
          ),

          // ── Compte ────────────────────────────────────────────────────
          _SectionHeader('Compte'),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Se déconnecter',
                style: TextStyle(color: AppColors.error)),
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'LONIYA V2.0.0 — Burkina Faso',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vos données locales seront conservées. Vous devrez vous reconnecter.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
