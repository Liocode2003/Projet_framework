import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with greeting
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour !',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  'LONIYA V2',
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // XP badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.xpGold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '0 XP',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Daily streak card
                _StreakCard(),
                const SizedBox(height: 20),

                // Quick actions grid
                Text('Accès rapide', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 20),

                // Continue learning section
                Text('Continuer à apprendre', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                _ContinueLearningCard(),
                const SizedBox(height: 100), // Bottom nav spacing
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.streakOrange.withOpacity(0.1),
            AppColors.xpGold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.streakOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Série de 0 jour', style: AppTextStyles.titleMedium),
              Text(
                'Commence ta première leçon aujourd\'hui !',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_QuickAction> actions = const [
    _QuickAction(
      label: 'Contenus',
      icon: Icons.store_rounded,
      color: AppColors.marketplace,
      route: RouteNames.marketplace,
    ),
    _QuickAction(
      label: 'Apprendre',
      icon: Icons.menu_book_rounded,
      color: AppColors.learning,
      route: RouteNames.learning,
    ),
    _QuickAction(
      label: 'AI Tuteur',
      icon: Icons.psychology_rounded,
      color: AppColors.aiTutor,
      route: RouteNames.aiTutor,
    ),
    _QuickAction(
      label: 'Orientation',
      icon: Icons.compass_calibration_rounded,
      color: AppColors.orientation,
      route: RouteNames.orientation,
    ),
    _QuickAction(
      label: 'Badges',
      icon: Icons.emoji_events_rounded,
      color: AppColors.gamification,
      route: RouteNames.gamification,
    ),
    _QuickAction(
      label: 'Wi-Fi Classe',
      icon: Icons.wifi_rounded,
      color: AppColors.localNetwork,
      route: RouteNames.localClassroom,
    ),
  ];

  const _QuickActionsGrid();

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
      itemCount: actions.length,
      itemBuilder: (context, i) => _QuickActionTile(action: actions[i]),
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
            Icon(action.icon, color: action.color, size: 30),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: AppTextStyles.labelSmall.copyWith(color: action.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(RouteNames.learning),
      child: Row(
        children: [
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
                Text('Commencer l\'apprentissage',
                    style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Téléchargez des contenus depuis le Marketplace',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0,
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
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}
