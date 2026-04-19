import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/gamification_provider.dart';
import '../widgets/badge_card.dart';
import '../widgets/mission_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/xp_level_card.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs       = ref.watch(gamificationNotifierProvider);
    final missions = ref.watch(dailyMissionsProvider);

    if (gs.isLoading) {
      return const Scaffold(body: Center(child: InlineLoader()));
    }

    final g      = gs.data;
    final badges = gs.mergedBadges;

    ref.listen<GamificationState>(gamificationNotifierProvider, (_, next) {
      if (next.newlyUnlockedIds.isNotEmpty) {
        final names = next.newlyUnlockedIds
            .map((id) => next.mergedBadges
                .firstWhere((b) => b.id == id,
                    orElse: () => badges.first)
                .title)
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.xpGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Badge débloqué : $names !',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
            backgroundColor: AppColors.levelPurple,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(gamificationNotifierProvider.notifier).clearNewlyUnlocked();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(gamificationNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 80,
              pinned: true,
              actions: [
                IconButton(
                  tooltip: 'Classement',
                  icon: const Icon(Icons.leaderboard_rounded,
                      color: Colors.white),
                  onPressed: () => context.push(RouteNames.leaderboard),
                ),
                IconButton(
                  tooltip: 'Performances',
                  icon: const Icon(Icons.bar_chart_rounded,
                      color: Colors.white),
                  onPressed: () => context.push(RouteNames.performance),
                ),
                IconButton(
                  tooltip: 'Paramètres',
                  icon: const Icon(Icons.settings_rounded,
                      color: Colors.white),
                  onPressed: () => context.push(RouteNames.settings),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.levelPurple, Color(0xFF4A148C)],
                    ),
                  ),
                ),
                title: Row(children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppColors.xpGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    g != null ? 'Niveau ${g.level}' : 'Progression',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ]),
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                collapseMode: CollapseMode.pin,
              ),
            ),

            if (g == null)
              const SliverFillRemaining(
                child: Center(child: Text('Aucune donnée de progression.')),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  XpLevelCard(g: g),
                  StreakCard(g: g),
                  const SizedBox(height: 4),

                  _Section(
                    title: 'Missions du jour',
                    icon: Icons.flag_rounded,
                    iconColor: AppColors.streakOrange,
                    child: Column(
                      children: missions
                          .map((m) => MissionCard(mission: m))
                          .toList(),
                    ),
                  ),

                  _Section(
                    title: 'Badges (${g.unlockedBadgeIds.length}/${badges.length})',
                    icon: Icons.military_tech_rounded,
                    iconColor: AppColors.levelPurple,
                    child: badges.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Aucun badge disponible.'),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: badges.length,
                            itemBuilder: (_, i) => BadgeCard(badge: badges[i]),
                          ),
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.titleMedium),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
