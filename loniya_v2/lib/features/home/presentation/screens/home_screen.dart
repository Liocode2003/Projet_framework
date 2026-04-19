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
    final user       = ref.watch(currentUserProvider);
    final gState     = ref.watch(gamificationNotifierProvider);
    final gData      = gState.data;
    final sync       = ref.watch(syncNotifierProvider);
    final lastOrient = ref.watch(orientationNotifierProvider).lastResult;
    final firstName  = (user?.name ?? 'Étudiant').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeroBanner(
                firstName: firstName,
                gData: gData,
                greeting: _greeting(),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Sync banner ────────────────────────────────────────
                if (sync.hasPending) ...[
                  _SyncBanner(
                    sync: sync,
                    onSync: () =>
                        ref.read(syncNotifierProvider.notifier).syncNow(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Feature carousel ───────────────────────────────────
                Text('Explorer', style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const _FeatureCarousel(),
                const SizedBox(height: 24),

                // ── Streak ─────────────────────────────────────────────
                _StreakCard(gData: gData),
                const SizedBox(height: 24),

                // ── Continue learning ──────────────────────────────────
                Text('Continuer', style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _ContinueLearningCard(gData: gData),

                // ── Orientation teaser ─────────────────────────────────
                if (lastOrient != null) ...[
                  const SizedBox(height: 12),
                  _OrientationTeaser(
                    filiere: lastOrient.recommendedFiliere,
                    onTap: () => context.go(RouteNames.orientationResult),
                  ),
                ],
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

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String firstName;
  final GamificationModel? gData;
  final String greeting;

  const _HeroBanner({
    required this.firstName,
    required this.gData,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final xp       = gData?.totalXp ?? 0;
    final level    = gData?.level ?? 1;
    final progress = gData?.levelProgress ?? 0.0;
    final streak   = gData?.currentStreak ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A3E), AppColors.primaryDark, AppColors.primary],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          firstName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stats chips
                  Row(children: [
                    _MiniChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '$streak',
                      color: AppColors.streakOrange,
                    ),
                    const SizedBox(width: 8),
                    _MiniChip(
                      icon: Icons.military_tech_rounded,
                      label: 'Niv. $level',
                      color: AppColors.gold,
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 14),

              // XP progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niv. $level → ${level + 1}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    '$xp XP',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white15,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
      ]),
    );
  }
}

// ─── Feature Carousel ─────────────────────────────────────────────────────────

class _FeatureCarousel extends StatelessWidget {
  const _FeatureCarousel();

  static const _features = [
    _Feature(
      label: 'Apprendre',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF00C9B1), Color(0xFF006B60)],
      route: RouteNames.learning,
    ),
    _Feature(
      label: 'Contenus',
      icon: Icons.store_rounded,
      colors: [AppColors.primary, AppColors.primaryDark],
      route: RouteNames.marketplace,
    ),
    _Feature(
      label: 'IA Tuteur',
      icon: Icons.psychology_rounded,
      colors: [Color(0xFFFF3D9A), Color(0xFF8B0050)],
      route: RouteNames.aiTutor,
    ),
    _Feature(
      label: 'Orientation',
      icon: Icons.compass_calibration_rounded,
      colors: [Color(0xFFFF6B35), Color(0xFF8B2800)],
      route: RouteNames.orientation,
    ),
    _Feature(
      label: 'Wi-Fi Classe',
      icon: Icons.wifi_rounded,
      colors: [Color(0xFF00C9B1), Color(0xFF00958A)],
      route: RouteNames.localClassroom,
    ),
    _Feature(
      label: 'Progression',
      icon: Icons.emoji_events_rounded,
      colors: [Color(0xFFFFB800), Color(0xFF8B6000)],
      route: RouteNames.gamification,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _features.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => _FeatureCard(feature: _features[i]),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(feature.route),
      child: Container(
        width: 118,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: feature.colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: feature.colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature.icon, color: Colors.white, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white60,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final String route;
  const _Feature({
    required this.label,
    required this.icon,
    required this.colors,
    required this.route,
  });
}

// ─── Streak Card ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [const Color(0xFFFF6B35), const Color(0xFFCC3300)]
              : [AppColors.surfaceVariant, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: active
                ? AppColors.streakOrange.withOpacity(0.3)
                : AppColors.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Text(active ? '🔥' : '💤', style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                streak == 0
                    ? 'Lance ta série !'
                    : 'Série de $streak jour${streak > 1 ? 's' : ''}',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                active
                    ? 'Bravo ! Tu as appris aujourd\'hui.'
                    : 'Fais une leçon pour maintenir ta série.',
                style: TextStyle(
                  color: active ? Colors.white70 : AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(active ? 0.2 : 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$streak',
              style: TextStyle(
                color: active ? Colors.white : AppColors.streakOrange,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
              ),
            ),
          ),
      ]),
    );
  }
}

// ─── Continue Learning ────────────────────────────────────────────────────────

class _ContinueLearningCard extends StatelessWidget {
  final GamificationModel? gData;
  const _ContinueLearningCard({this.gData});

  @override
  Widget build(BuildContext context) {
    final lessons  = gData?.lessonsCompleted ?? 0;
    final progress = gData?.levelProgress ?? 0.0;

    return GestureDetector(
      onTap: () => context.go(RouteNames.learning),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.tealDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.play_circle_rounded,
                color: Colors.white, size: 30),
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
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lessons == 0
                      ? 'Télécharge des contenus depuis les Contenus'
                      : 'Continue pour atteindre le niveau suivant',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 20),
          ),
        ]),
      ),
    );
  }
}

// ─── Orientation Teaser ───────────────────────────────────────────────────────

class _OrientationTeaser extends StatelessWidget {
  final String filiere;
  final VoidCallback onTap;
  const _OrientationTeaser({required this.filiere, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.compass_calibration_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Orientation conseillée',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  filiere,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 22),
        ]),
      ),
    );
  }
}

// ─── Sync Banner ──────────────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  final SyncState sync;
  final VoidCallback onSync;
  const _SyncBanner({required this.sync, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.sync_rounded, color: AppColors.warning, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${sync.pendingCount} action${sync.pendingCount > 1 ? 's' : ''} en attente.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
          ),
        ),
        TextButton(
          onPressed: sync.isSyncing ? null : onSync,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warning,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
          ),
          child: Text(
            sync.isSyncing ? 'En cours…' : 'Sync',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }
}
