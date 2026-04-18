import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/local_network_provider.dart';

class LocalClassroomScreen extends ConsumerWidget {
  const LocalClassroomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.localNetwork, Color(0xFF263238)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Row(children: [
                const Icon(Icons.wifi_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Classe locale',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
              ]),
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Info banner ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Partagez des cours via Wi-Fi sans connexion internet. '
                        'Les appareils doivent être sur le même réseau.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.info),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 32),
                Text('Choisir un rôle',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Comment voulez-vous utiliser la classe locale ?',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // ── Role cards ───────────────────────────────────────────
                _RoleCard(
                  icon: Icons.cast_for_education_rounded,
                  color: AppColors.teacher,
                  title: 'Enseignant',
                  description:
                      'Partagez vos cours téléchargés avec les élèves '
                      'à proximité via Wi-Fi.',
                  badge: 'Serveur',
                  onTap: () => context.go(RouteNames.localClassroomHost),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.school_rounded,
                  color: AppColors.learning,
                  title: 'Élève',
                  description:
                      'Recherchez un enseignant et recevez ses cours '
                      'directement sur votre appareil.',
                  badge: 'Client',
                  onTap: () => context.go(RouteNames.localClassroomJoin),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge,
                        style: AppTextStyles.caption
                            .copyWith(color: color)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: AppColors.grey400),
        ]),
      ),
    );
  }
}
