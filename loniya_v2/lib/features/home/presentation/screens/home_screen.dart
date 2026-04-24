import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/sync/sync_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../gamification/data/models/gamification_model.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../orientation/presentation/providers/orientation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);

    switch (role) {
      case 'teacher':
        return const _TeacherHome();
      case 'parent':
        return const _ParentHome();
      default:
        return const _StudentHome();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STUDENT HOME
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentHome extends ConsumerWidget {
  const _StudentHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final gState    = ref.watch(gamificationNotifierProvider);
    final gData     = gState.data;
    final sync      = ref.watch(syncNotifierProvider);
    final lastOrient = ref.watch(orientationNotifierProvider).lastResult;
    final firstName = (user?.name ?? 'Élève').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _StudentHero(
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
                if (sync.hasPending) ...[
                  _SyncBanner(sync: sync,
                    onSync: () => ref.read(syncNotifierProvider.notifier).syncNow()),
                  const SizedBox(height: 16),
                ],
                _ActiveStudentsBanner(),
                const SizedBox(height: 16),
                Text('Explorer', style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const _StudentCarousel(),
                const SizedBox(height: 24),
                _StreakCard(gData: gData),
                const SizedBox(height: 24),
                Text('Continuer', style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _ContinueLearningCard(gData: gData),
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

class _StudentHero extends StatelessWidget {
  final String firstName, greeting;
  final GamificationModel? gData;
  const _StudentHero({required this.firstName, required this.gData, required this.greeting});

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
                        Text(greeting,
                            style: const TextStyle(color: Colors.white60,
                                fontSize: 13, fontFamily: 'Nunito')),
                        Text(firstName,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 28, fontWeight: FontWeight.w900,
                                fontFamily: 'Nunito'),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(children: [
                    _MiniChip(icon: Icons.local_fire_department_rounded,
                        label: '$streak', color: AppColors.streakOrange),
                    const SizedBox(width: 8),
                    _MiniChip(icon: Icons.military_tech_rounded,
                        label: 'Niv. $level', color: AppColors.gold),
                  ]),
                ],
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Niv. $level → ${level + 1}',
                    style: const TextStyle(color: Colors.white54,
                        fontSize: 11, fontFamily: 'Nunito')),
                Text('$xp XP',
                    style: const TextStyle(color: AppColors.gold, fontSize: 12,
                        fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
              ]),
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

class _StudentCarousel extends StatelessWidget {
  const _StudentCarousel();

  static const _features = [
    _Feature('Apprendre', Icons.menu_book_rounded,
        [Color(0xFF00C9B1), Color(0xFF006B60)], RouteNames.learning),
    _Feature('Contenus', Icons.store_rounded,
        [AppColors.primary, AppColors.primaryDark], RouteNames.marketplace),
    _Feature('IA Tuteur', Icons.psychology_rounded,
        [Color(0xFFFF3D9A), Color(0xFF8B0050)], RouteNames.aiTutor),
    _Feature('Orientation', Icons.compass_calibration_rounded,
        [Color(0xFFFF6B35), Color(0xFF8B2800)], RouteNames.orientation),
    _Feature('Wi-Fi Classe', Icons.wifi_rounded,
        [Color(0xFF00C9B1), Color(0xFF00958A)], RouteNames.localClassroom),
    _Feature('Progression', Icons.emoji_events_rounded,
        [Color(0xFFFFB800), Color(0xFF8B6000)], RouteNames.gamification),
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

// ═══════════════════════════════════════════════════════════════════════════════
// TEACHER HOME
// ═══════════════════════════════════════════════════════════════════════════════

class _TeacherHome extends ConsumerWidget {
  const _TeacherHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final sync      = ref.watch(syncNotifierProvider);
    final firstName = (user?.name ?? 'Enseignant').split(' ').first;
    final subject   = user?.gradeLevel ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _TeacherHero(firstName: firstName, subject: subject),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (sync.hasPending) ...[
                  _SyncBanner(sync: sync,
                    onSync: () => ref.read(syncNotifierProvider.notifier).syncNow()),
                  const SizedBox(height: 16),
                ],

                // Stats row
                Row(children: [
                  Expanded(child: _StatCard(
                    icon: Icons.group_rounded,
                    label: 'Élèves',
                    value: '—',
                    color: AppColors.teal,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.library_books_rounded,
                    label: 'Contenus',
                    value: '—',
                    color: AppColors.primary,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.savings_rounded,
                    label: 'Revenus',
                    value: '—',
                    color: AppColors.gold,
                  )),
                ]),
                const SizedBox(height: 24),

                Text('Mes outils', style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const _TeacherCarousel(),
                const SizedBox(height: 24),

                // Quick action — classroom
                _QuickActionCard(
                  icon: Icons.wifi_rounded,
                  title: 'Démarrer une classe Wi-Fi',
                  subtitle: 'Partage des contenus hors-ligne',
                  colors: const [Color(0xFF00C9B1), Color(0xFF006B60)],
                  onTap: () => context.go(RouteNames.localClassroomHost),
                ),
                const SizedBox(height: 12),
                _QuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Voir mes revenus',
                  subtitle: 'Suivi des ventes et abonnements',
                  colors: const [Color(0xFFFFB800), Color(0xFF8B6000)],
                  onTap: () => context.go(RouteNames.teacherRevenue),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherHero extends StatelessWidget {
  final String firstName, subject;
  const _TeacherHero({required this.firstName, required this.subject});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003D35), Color(0xFF00958A), AppColors.teal],
          stops: [0.0, 0.5, 1.0],
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
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(color: Colors.white60,
                        fontSize: 13, fontFamily: 'Nunito')),
                    Text(firstName, style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subject.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(subject, style: const TextStyle(
                            color: Colors.white70, fontSize: 12, fontFamily: 'Nunito')),
                      ),
                  ],
                )),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cast_for_education_rounded,
                      color: Colors.white, size: 28),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherCarousel extends StatelessWidget {
  const _TeacherCarousel();

  static const _features = [
    _Feature('Ma Classe', Icons.group_rounded,
        [Color(0xFF003D35), AppColors.teal], RouteNames.localClassroom),
    _Feature('Mes Contenus', Icons.library_books_rounded,
        [AppColors.primary, AppColors.primaryDark], RouteNames.marketplace),
    _Feature('Revenus', Icons.savings_rounded,
        [Color(0xFFFFB800), Color(0xFF8B6000)], RouteNames.teacherRevenue),
    _Feature('Wi-Fi', Icons.wifi_rounded,
        [Color(0xFF00C9B1), Color(0xFF00958A)], RouteNames.localClassroomHost),
    _Feature('Abonnement', Icons.workspace_premium_rounded,
        [Color(0xFFFF6B35), Color(0xFF8B2800)], RouteNames.teacherSubscription),
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

// ═══════════════════════════════════════════════════════════════════════════════
// PARENT HOME
// ═══════════════════════════════════════════════════════════════════════════════

class _ParentHome extends ConsumerWidget {
  const _ParentHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final sync      = ref.watch(syncNotifierProvider);
    final firstName = (user?.name ?? 'Parent').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ParentHero(firstName: firstName),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (sync.hasPending) ...[
                  _SyncBanner(sync: sync,
                    onSync: () => ref.read(syncNotifierProvider.notifier).syncNow()),
                  const SizedBox(height: 16),
                ],

                Text('Mes outils', style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const _ParentCarousel(),
                const SizedBox(height: 24),

                // Children placeholder card
                _QuickActionCard(
                  icon: Icons.child_care_rounded,
                  title: 'Suivre la progression',
                  subtitle: 'Consulte les résultats de tes enfants',
                  colors: const [Color(0xFFFF6B35), Color(0xFF8B2800)],
                  onTap: () => context.go(RouteNames.parentDashboard),
                ),
                const SizedBox(height: 12),
                _QuickActionCard(
                  icon: Icons.store_rounded,
                  title: 'Explorer les contenus',
                  subtitle: 'Trouve des ressources pour tes enfants',
                  colors: const [AppColors.primary, AppColors.primaryDark],
                  onTap: () => context.go(RouteNames.marketplace),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentHero extends StatelessWidget {
  final String firstName;
  const _ParentHero({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1A00), Color(0xFFCC4400), AppColors.accent],
          stops: [0.0, 0.5, 1.0],
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
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(color: Colors.white60,
                        fontSize: 13, fontFamily: 'Nunito')),
                    Text(firstName, style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    const Text('Tableau de bord parent',
                        style: TextStyle(color: Colors.white60,
                            fontSize: 13, fontFamily: 'Nunito')),
                  ],
                )),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.family_restroom_rounded,
                      color: Colors.white, size: 28),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentCarousel extends StatelessWidget {
  const _ParentCarousel();

  static const _features = [
    _Feature('Mes Enfants', Icons.child_care_rounded,
        [Color(0xFF3D1A00), AppColors.accent], RouteNames.parentDashboard),
    _Feature('Contenus', Icons.store_rounded,
        [AppColors.primary, AppColors.primaryDark], RouteNames.marketplace),
    _Feature('IA Tuteur', Icons.psychology_rounded,
        [Color(0xFFFF3D9A), Color(0xFF8B0050)], RouteNames.aiTutor),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Feature {
  final String label, route;
  final IconData icon;
  final List<Color> colors;
  const _Feature(this.label, this.icon, this.colors, this.route);
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
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature.icon, color: Colors.white, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.label, style: const TextStyle(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
                  const SizedBox(height: 2),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white60, size: 14),
                ],
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 18,
            fontWeight: FontWeight.w900, fontFamily: 'Nunito')),
        Text(label, style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant)),
      ]),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.title,
      required this.subtitle, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: colors.first.withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white70,
                  fontSize: 12, fontFamily: 'Nunito')),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 22),
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
    final s = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    return gData?.lastActivityDate == s;
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
            color: active ? AppColors.streakOrange.withOpacity(0.3)
                : AppColors.shadow.withOpacity(0.1),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Text(active ? '🔥' : '💤', style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              streak == 0 ? 'Lance ta série !'
                  : 'Série de $streak jour${streak > 1 ? 's' : ''}',
              style: TextStyle(
                color: active ? Colors.white : AppColors.onSurface,
                fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              active ? 'Bravo ! Tu as appris aujourd\'hui.'
                  : 'Fais une leçon pour maintenir ta série.',
              style: TextStyle(
                color: active ? Colors.white70 : AppColors.onSurfaceVariant,
                fontSize: 12, fontFamily: 'Nunito',
              ),
            ),
          ],
        )),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(active ? 0.2 : 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$streak', style: TextStyle(
              color: active ? Colors.white : AppColors.streakOrange,
              fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Nunito',
            )),
          ),
      ]),
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

    return GestureDetector(
      onTap: () => context.go(RouteNames.learning),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.tealDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.play_circle_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessons == 0 ? 'Commencer l\'apprentissage'
                    : '$lessons leçon${lessons > 1 ? 's' : ''} terminée${lessons > 1 ? 's' : ''}',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                lessons == 0 ? 'Télécharge des contenus depuis les Contenus'
                    : 'Continue pour atteindre le niveau suivant',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant),
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
          )),
          const SizedBox(width: 8),
          Container(
            width: 32, height: 32,
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
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.compass_calibration_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Orientation conseillée',
                  style: TextStyle(color: Colors.white60,
                      fontSize: 11, fontFamily: 'Nunito')),
              const SizedBox(height: 2),
              Text(filiere, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 22),
        ]),
      ),
    );
  }
}

class _ActiveStudentsBanner extends StatelessWidget {
  _ActiveStudentsBanner();

  int get _count {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return 1050 + Random(seed).nextInt(450);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sage.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.sage.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.people_rounded, color: AppColors.sage, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${_count} élèves actifs au Burkina Faso aujourd\'hui 🇧🇫',
          style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.sage, fontWeight: FontWeight.w700),
        )),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.sync_rounded, color: AppColors.warning, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${sync.pendingCount} action${sync.pendingCount > 1 ? 's' : ''} en attente.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
        )),
        TextButton(
          onPressed: sync.isSyncing ? null : onSync,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warning,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
          ),
          child: Text(sync.isSyncing ? 'En cours…' : 'Sync',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
