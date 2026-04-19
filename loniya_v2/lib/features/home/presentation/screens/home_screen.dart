import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/sync/sync_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../gamification/data/models/gamification_model.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../orientation/presentation/providers/orientation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(currentUserProvider);
    final gState  = ref.watch(gamificationNotifierProvider);
    final gData   = gState.data;
    final sync    = ref.watch(syncNotifierProvider);
    final lastOrient = ref.watch(orientationNotifierProvider).lastResult;

    final greeting = _greeting();
    final firstName = (user?.name ?? 'Élève').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting,
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: Colors.white70)),
                                Text(
                                  firstName,
                                  style: AppTextStyles.headlineLarge
                                      .copyWith(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // XP + Level pill
                          _XpPill(gData: gData),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Sync pending banner ────────────────────────────────
                if (sync.hasPending)
                  _SyncBanner(sync: sync, onSync: () =>
                      ref.read(syncNotifierProvider.notifier).syncNow()),

                // ── Stats row ──────────────────────────────────────────
                _StatsRow(gData: gData),
                const SizedBox(height: 20),

                // ── Streak card ────────────────────────────────────────
                _StreakCard(gData: gData),
                const SizedBox(height: 20),

                // ── Quick actions ──────────────────────────────────────
                Text('Accès rapide', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                const _QuickActionsGrid(),
                const SizedBox(height: 20),

                // ── Continue learning ──────────────────────────────────
                Text('Continuer', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                _ContinueLearningCard(gData: gData),

                // ── Orientation teaser ─────────────────────────────────
                if (lastOrient != null) ...[
                  const SizedBox(height: 12),
                  _OrientationTeaser(
                    filiere: lastOrient.recommendedFiliere,
                    onTap: () => context.go(RouteNames.orientationResult),
                  ),
                ],

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _XpPill extends StatelessWidget {
  final GamificationModel? gData;
  const _XpPill({this.gData});

  @override
  Widget build(BuildContext context) {
    final xp    = gData?.totalXp ?? 0;
    final level = gData?.level ?? 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.levelPurple,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$level',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white, fontSize: 10)),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.star_rounded,
            color: AppColors.xpGold, size: 16),
        const SizedBox(width: 3),
        Text('$xp XP',
            style: AppTextStyles.labelMedium
                .copyWith(color: Colors.white)),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final GamificationModel? gData;
  const _StatsRow({this.gData});

  @override
  Widget build(BuildContext context) {
    final xp      = gData?.totalXp ?? 0;
    final level   = gData?.level ?? 1;
    final streak  = gData?.currentStreak ?? 0;
    final lessons = gData?.lessonsCompleted ?? 0;

    return Row(children: [
      _StatChip(label: 'XP',     value: '$xp',    icon: Icons.star_rounded,      color: AppColors.xpGold),
      const SizedBox(width: 8),
      _StatChip(label: 'Niveau', value: '$level',  icon: Icons.military_tech_rounded, color: AppColors.levelPurple),
      const SizedBox(width: 8),
      _StatChip(label: 'Série',  value: '$streak j', icon: Icons.local_fire_department_rounded, color: AppColors.streakOrange),
      const SizedBox(width: 8),
      _StatChip(label: 'Leçons', value: '$lessons', icon: Icons.menu_book_rounded, color: AppColors.learning),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.labelMedium.copyWith(
                  color: color, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(fontSize: 9, color: AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final GamificationModel? gData;
  const _StreakCard({this.gData});

  bool get _isActive {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return gData?.lastActivityDate == todayStr;
  }

  @override
  Widget build(BuildContext context) {
    final streak = gData?.currentStreak ?? 0;
    final active = _isActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.streakOrange.withOpacity(active ? 0.15 : 0.06),
          AppColors.xpGold.withOpacity(active ? 0.12 : 0.04),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.streakOrange
              .withOpacity(active ? 0.4 : 0.15),
        ),
      ),
      child: Row(children: [
        Text(active ? '🔥' : '💤',
            style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                streak == 0
                    ? 'Commence ta série !'
                    : 'Série de $streak jour${streak > 1 ? 's' : ''}',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                active
                    ? 'Tu as appris aujourd\'hui. Continue !'
                    : 'Fais une leçon aujourd\'hui pour maintenir ta série.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.streakOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text('$streak',
                style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.streakOrange,
                    fontWeight: FontWeight.w900)),
          ),
      ]),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const List<_QuickAction> _actions = [
    _QuickAction('Contenus',      Icons.store_rounded,               AppColors.marketplace, RouteNames.marketplace),
    _QuickAction('Apprendre',     Icons.menu_book_rounded,           AppColors.learning,    RouteNames.learning),
    _QuickAction('IA Tuteur',     Icons.psychology_rounded,          AppColors.aiTutor,     RouteNames.aiTutor),
    _QuickAction('Orientation',   Icons.compass_calibration_rounded, AppColors.orientation, RouteNames.orientation),
    _QuickAction('Progression',   Icons.emoji_events_rounded,        AppColors.gamification,RouteNames.gamification),
    _QuickAction('Wi-Fi Classe',  Icons.wifi_rounded,                AppColors.localNetwork,RouteNames.localClassroom),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _actions.length,
      itemBuilder: (ctx, i) => _QuickActionTile(action: _actions[i]),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: action.color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 28),
            const SizedBox(height: 6),
            Text(action.label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: action.color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final GamificationModel? gData;
  const _ContinueLearningCard({this.gData});

  @override
  Widget build(BuildContext context) {
    final lessons  = gData?.lessonsCompleted ?? 0;
    final progress = gData?.levelProgress ?? 0.0;

    return AppCard(
      onTap: () => context.go(RouteNames.learning),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.learning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.play_circle_rounded,
              color: AppColors.learning, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessons == 0
                    ? 'Commencer l\'apprentissage'
                    : '$lessons leçon${lessons > 1 ? 's' : ''} terminée${lessons > 1 ? 's' : ''}',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                lessons == 0
                    ? 'Télécharge des contenus depuis le Marketplace'
                    : 'Continue pour atteindre le niveau suivant',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.grey200,
                  color: AppColors.learning,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.grey400, size: 22),
      ]),
    );
  }
}

class _OrientationTeaser extends StatelessWidget {
  final String filiere;
  final VoidCallback onTap;
  const _OrientationTeaser({required this.filiere, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.orientation.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.compass_calibration_rounded,
              color: AppColors.orientation, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orientation conseillée',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(filiere,
                  style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.orientation)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.grey400, size: 22),
      ]),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final SyncState sync;
  final VoidCallback onSync;
  const _SyncBanner({required this.sync, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.sync_rounded,
            color: AppColors.warning, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${sync.pendingCount} action${sync.pendingCount > 1 ? 's' : ''} '
            'en attente de synchronisation.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.warning),
          ),
        ),
        TextButton(
          onPressed: sync.isSyncing ? null : onSync,
          style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8)),
          child: Text(sync.isSyncing ? 'En cours…' : 'Sync',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.warning)),
        ),
      ]),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
