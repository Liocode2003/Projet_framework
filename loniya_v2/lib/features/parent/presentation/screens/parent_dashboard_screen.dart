import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../gamification/data/models/gamification_model.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ChildData {
  final UserModel user;
  final GamificationModel gamification;
  final int completedLessons;
  const _ChildData(
      {required this.user,
      required this.gamification,
      required this.completedLessons});
}

class _DashboardData {
  final List<_ChildData> found;    // children present on this device
  final List<String> pending;      // YK codes linked but not yet on device
  const _DashboardData({required this.found, required this.pending});
  bool get isEmpty => found.isEmpty && pending.isEmpty;
}

// ── Provider ──────────────────────────────────────────────────────────────────

// Same deterministic hash used in profile_screen and parent_link_screen
String _ykCodeOf(String userId) {
  if (userId.isEmpty) return 'YK-0000-BF';
  final hash = userId.hashCode.abs() % 10000;
  return 'YK-${hash.toString().padLeft(4, '0')}-BF';
}

final _dashboardProvider =
    FutureProvider.autoDispose<_DashboardData>((ref) async {
  final db       = ref.read(databaseServiceProvider);
  final parentId = ref.read(authNotifierProvider).userId ?? '';

  final box = Hive.box(HiveBoxes.settings);
  final raw = (box.get('parent_links_$parentId') as String?) ?? '';
  final linkedCodes = raw.isEmpty
      ? <String>[]
      : raw.split(',').where((s) => s.isNotEmpty).toList();

  if (linkedCodes.isEmpty) {
    return const _DashboardData(found: [], pending: []);
  }

  // Try to match each linked code against local students
  final allStudents = db
      .getAllUsers()
      .where((u) => u.role == AppConstants.roleStudent)
      .toList();

  final found = <_ChildData>[];
  final matchedCodes = <String>{};

  for (final student in allStudents) {
    final code = _ykCodeOf(student.id);
    if (linkedCodes.contains(code)) {
      matchedCodes.add(code);
      final g = db.getOrCreateGamification(student.id);
      final completed = db.getCompletedLessons(student.id).length;
      found.add(_ChildData(
          user: student, gamification: g, completedLessons: completed));
    }
  }
  found.sort(
      (a, b) => b.gamification.totalXp.compareTo(a.gamification.totalXp));

  // Codes that weren't matched locally → pending
  final pending =
      linkedCodes.where((c) => !matchedCodes.contains(c)).toList();

  return _DashboardData(found: found, pending: pending);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suivi des enfants'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link_rounded),
            tooltip: 'Lier un enfant',
            onPressed: () => context.push(RouteNames.parentLink),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (data) => data.isEmpty
            ? _EmptyState(
                onLink: () => context.push(RouteNames.parentLink))
            : _Body(data: data,
                onLink: () => context.push(RouteNames.parentLink)),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final _DashboardData data;
  final VoidCallback onLink;
  const _Body({required this.data, required this.onLink});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Children with data on this device
        if (data.found.isNotEmpty) ...[
          _SectionLabel('Enfants actifs (${data.found.length})'),
          ...data.found.map((c) => _ChildCard(data: c)),
        ],

        // Pending children (linked but on a different device)
        if (data.pending.isNotEmpty) ...[
          _SectionLabel('En attente de connexion (${data.pending.length})'),
          ...data.pending.map((code) => _PendingCard(ykCode: code)),
        ],

        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onLink,
          icon: const Icon(Icons.add_link_rounded, size: 18),
          label: const Text('Lier un autre enfant',
              style: TextStyle(fontFamily: 'Nunito')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ── Child card (data available) ───────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  final _ChildData data;
  const _ChildCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final g    = data.gamification;
    final name = data.user.name ?? data.user.phone;

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
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(name, style: AppTextStyles.titleSmall),
              Text(
                g.lastActivityDate != null
                    ? 'Dernière activité : ${g.lastActivityDate}'
                    : 'Pas encore actif',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.levelPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Niv. ${g.level}',
                style: const TextStyle(
                    color: AppColors.levelPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Nunito')),
          ),
        ]),

        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
              label: '${g.currentStreak} j.'),
        ]),

        const SizedBox(height: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Vers niv. ${g.level + 1}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.onSurfaceVariant)),
            Text('${g.xpInCurrentLevel}/${g.xpToNextLevel} XP',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.levelPurple)),
          ]),
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
      ]),
    );
  }
}

// ── Pending card (linked but different device) ────────────────────────────────

class _PendingCard extends StatelessWidget {
  final String ykCode;
  const _PendingCard({required this.ykCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
              color: AppColors.warning.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.hourglass_top_rounded,
              color: AppColors.warning, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(ykCode,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.onSurface)),
            const SizedBox(height: 3),
            const Text(
              'En attente — l\'enfant doit se connecter à yikri '
              'pour que ses données apparaissent.',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5)),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _StatItem(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(label,
          style: AppTextStyles.bodySmall
              .copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onLink;
  const _EmptyState({this.onLink});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.child_care_rounded,
              size: 72, color: AppColors.grey400),
          const SizedBox(height: 20),
          Text('Aucun enfant lié',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Entre le code yikri de ton enfant pour suivre '
            'sa progression — fonctionne sur tous les téléphones.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (onLink != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onLink,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: const Text('Lier un enfant',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ),
    );
  }
}
