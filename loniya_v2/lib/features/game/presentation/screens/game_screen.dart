import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../credits/presentation/providers/credit_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(creditBalanceProvider);
    final gData   = ref.watch(gamificationNotifierProvider).data;
    final user    = ref.watch(currentUserProvider);
    final name    = (user?.name ?? 'Joueur').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _GameHero(name: name, credits: credits),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(children: [
                  _StatChip(
                    icon: Icons.emoji_events_rounded,
                    label: 'Niv. ${gData?.level ?? 1}',
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: Icons.local_fire_department_rounded,
                    label: '${gData?.currentStreak ?? 0}j',
                    color: AppColors.streakOrange,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: Icons.stars_rounded,
                    label: '$credits crédits',
                    color: AppColors.primary,
                  ),
                ]),
                const SizedBox(height: 28),

                const Text(
                  'Choisis ton mode',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 4 game modes
                _GameModeCard(
                  icon: '💎',
                  title: 'Gemmes',
                  subtitle: 'Match-3 classique — accumule des points et des crédits',
                  tag: '+${AppConstants.creditPerGame} crédits/niveau',
                  colors: const [Color(0xFF1A3A6E), Color(0xFF1565C0)],
                  onTap: () => context.go(RouteNames.gameSprint),
                ),
                const SizedBox(height: 14),

                _GameModeCard(
                  icon: '⚡',
                  title: 'Sprint 60s',
                  subtitle: 'Maximum de gemmes en 60 secondes — rythme intense',
                  tag: 'Chronométré',
                  colors: const [Color(0xFF4A1A00), Color(0xFFCC4400)],
                  onTap: () => context.go(RouteNames.gameSprint),
                ),
                const SizedBox(height: 14),

                _GameModeCard(
                  icon: '🌿',
                  title: 'Défi Le Sage',
                  subtitle: 'Le Sage te pose des questions — réponds vite et bien',
                  tag: '+${AppConstants.creditPerChallenge} crédits',
                  colors: const [Color(0xFF1A3A2A), Color(0xFF2E7D32)],
                  onTap: () => context.go(RouteNames.gameSage),
                ),

                const SizedBox(height: 28),

                // Leaderboard banner
                GestureDetector(
                  onTap: () => context.go(RouteNames.leaderboard),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A2A00), AppColors.gold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      const Text('🏆', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Classement Burkina',
                                style: TextStyle(color: Colors.white,
                                    fontFamily: 'Nunito', fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            Text('Vois ta position nationale',
                                style: TextStyle(color: Colors.white70,
                                    fontFamily: 'Nunito', fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white70),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _GameHero extends StatelessWidget {
  final String name;
  final int credits;
  const _GameHero({required this.name, required this.credits});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D1A), Color(0xFF1A0A3E), Color(0xFF4527A0)],
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
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jeu éducatif',
                        style: TextStyle(color: Colors.white54,
                            fontSize: 13, fontFamily: 'Nunito')),
                    Text('Joue, $name !',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 28, fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.stars_rounded,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text('$credits',
                        style: const TextStyle(color: AppColors.gold,
                            fontFamily: 'Nunito', fontSize: 15,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Game Mode Card ────────────────────────────────────────────────────────────

class _GameModeCard extends StatelessWidget {
  final String icon, title, subtitle, tag;
  final List<Color> colors;
  final String? badge;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.colors,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: const TextStyle(
                      color: Colors.white, fontFamily: 'Nunito',
                      fontSize: 17, fontWeight: FontWeight.w800)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(
                    color: Colors.white70, fontFamily: 'Nunito', fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(tag, style: const TextStyle(
                      color: Colors.white, fontFamily: 'Nunito',
                      fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_rounded,
              color: Colors.white54, size: 28),
        ]),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
            color: color, fontFamily: 'Nunito',
            fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
