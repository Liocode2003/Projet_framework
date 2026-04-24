import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../gamification/data/models/gamification_model.dart';
import '../../../auth/data/models/user_model.dart';

final _childrenProvider =
    FutureProvider.autoDispose<List<_ChildData>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  final students = db
      .getAllUsers()
      .where((u) => u.role == AppConstants.roleStudent)
      .toList();

  return students.map((u) {
    final g = db.getOrCreateGamification(u.id);
    final completed = db.getCompletedLessons(u.id).length;
    return _ChildData(user: u, gamification: g, completedLessons: completed);
  }).toList()
    ..sort((a, b) => b.gamification.totalXp.compareTo(a.gamification.totalXp));
});

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_childrenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suivi des enfants'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (children) => children.isEmpty
            ? _EmptyState()
            : _Body(children: children),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<_ChildData> children;
  const _Body({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.info, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tous les élèves enregistrés sur cet appareil sont affichés.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ...children.map((c) => _ChildCard(data: c)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ChildCard extends StatelessWidget {
  final _ChildData data;
  const _ChildCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final g = data.gamification;
    final name = data.user.name ?? data.user.phone;
    final hasActivity = g.lastActivityDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary.withOpacity(0.15),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppTextStyles.titleSmall),
              Text(
                hasActivity
                    ? 'Dernière activité : ${g.lastActivityDate}'
                    : 'Pas encore actif',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.levelPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Niv. ${g.level}',
              style: const TextStyle(
                color: AppColors.levelPurple,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ]),

        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatItem(
                icon: Icons.star_rounded,
                color: AppColors.xpGold,
                label: '${g.totalXp} XP'),
            _StatItem(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                label: '${data.completedLessons} leçons'),
            _StatItem(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.streakOrange,
                label: '${g.currentStreak} j. série'),
          ],
        ),

        const SizedBox(height: 12),

        // XP progress bar
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression vers niv. ${g.level + 1}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.onSurfaceVariant)),
              Text(
                  '${g.xpInCurrentLevel}/${g.xpToNextLevel} XP',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.levelPurple)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: g.levelProgress,
              backgroundColor: AppColors.grey200,
              color: AppColors.levelPurple,
              minHeight: 8,
            ),
          ),
        ]),

        // Subject XP
        if (g.xpBySubject.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: g.xpBySubject.entries
                .where((e) => e.value > 0)
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${e.key.length > 6 ? e.key.substring(0, 5) : e.key}: ${e.value} XP',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.secondary),
                      ),
                    ))
                .toList(),
          ),
        ],
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _StatItem({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(label,
          style:
              AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.child_care_rounded,
                size: 72, color: AppColors.grey400),
            const SizedBox(height: 20),
            Text('Aucun enfant enregistré',
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Les enfants utilisant yikri sur cet appareil '
              'apparaîtront ici automatiquement.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildData {
  final UserModel user;
  final GamificationModel gamification;
  final int completedLessons;

  const _ChildData({
    required this.user,
    required this.gamification,
    required this.completedLessons,
  });
}
