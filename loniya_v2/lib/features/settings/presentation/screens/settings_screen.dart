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
    final settings     = ref.watch(settingsNotifierProvider);
    final notifier     = ref.read(settingsNotifierProvider.notifier);
    final storageAsync = ref.watch(storageReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.outline),
        ),
      ),
      backgroundColor: const Color(0xFFF4F3FA),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Apparence ─────────────────────────────────────────────────
          _SectionTitle('Apparence'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              iconColor: AppColors.primary,
              title: 'Mode sombre',
              value: settings.darkMode,
              onChanged: (_) => notifier.toggleDarkMode(),
            ),
          ]),

          // ── Accessibilité ──────────────────────────────────────────────
          _SectionTitle('Accessibilité'),
          _SettingsCard(children: [
            _LinkTile(
              icon: Icons.accessibility_new_rounded,
              iconColor: AppColors.pink,
              title: 'Options d\'accessibilité',
              subtitle: 'Contraste élevé, grands textes, voix',
              onTap: () => context.push(RouteNames.accessibility),
            ),
          ]),

          // ── Audio ──────────────────────────────────────────────────────
          _SectionTitle('Audio'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.record_voice_over_rounded,
              iconColor: AppColors.teal,
              title: 'Lecture vocale (TTS)',
              subtitle: 'Lit les réponses de l\'IA à voix haute',
              value: settings.ttsEnabled,
              onChanged: (_) => notifier.toggleTts(),
            ),
            if (settings.ttsEnabled) ...[
              Divider(height: 1, color: AppColors.outline),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(children: [
                  Icon(Icons.speed_rounded,
                      color: AppColors.teal, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vitesse de lecture',
                            style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.onSurface)),
                        Slider(
                          value: settings.ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          label: '×${settings.ttsSpeed.toStringAsFixed(1)}',
                          activeColor: AppColors.teal,
                          onChanged: (v) => notifier.setTtsSpeed(v),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ]),

          // ── Langue ────────────────────────────────────────────────────
          _SectionTitle('Langue'),
          _SettingsCard(children: [
            _RadioTile(
              icon: Icons.translate_rounded,
              iconColor: AppColors.accent,
              title: 'Français',
              selected: settings.language == 'fr',
              onTap: () => notifier.setLanguage('fr'),
            ),
            Divider(height: 1, color: AppColors.outline),
            _RadioTile(
              icon: Icons.translate_rounded,
              iconColor: AppColors.accent,
              title: 'Bambara (bm)',
              selected: settings.language == 'bm',
              onTap: () => notifier.setLanguage('bm'),
            ),
          ]),

          // ── Stockage ──────────────────────────────────────────────────
          _SectionTitle('Stockage'),
          _SettingsCard(children: [
            storageAsync.when(
              loading: () => const _LoadingTile(),
              error: (_, __) => const SizedBox.shrink(),
              data: (report) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storage_rounded,
                      color: AppColors.gold, size: 20),
                ),
                title: Text('Espace utilisé',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.onSurface)),
                subtitle: Text(
                  '${report.formattedTotal} (contenus + rapports)',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
          ]),

          // ── Compte ────────────────────────────────────────────────────
          _SectionTitle('Compte'),
          _SettingsCard(children: [
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 20),
              ),
              title: Text('Se déconnecter',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.error)),
              onTap: () => _confirmLogout(context, ref),
            ),
          ]),

          const SizedBox(height: 32),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

// ─── Section helpers ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant))
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface)),
      subtitle: Text(subtitle,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}

class _RadioTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _RadioTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.onSurface)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22)
          : Icon(Icons.circle_outlined, color: AppColors.grey300, size: 22),
      onTap: onTap,
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2)),
      title: Text('Calcul en cours…'),
    );
  }
}
