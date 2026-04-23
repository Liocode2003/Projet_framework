import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../credits/presentation/providers/credit_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final gData    = ref.watch(gamificationNotifierProvider).data;
    final credits  = ref.watch(creditBalanceProvider);
    final totalEarned = ref.watch(creditNotifierProvider)?.totalEarned ?? 0;

    final name     = user?.name ?? 'Profil';
    final firstName = name.split(' ').first;
    final role     = user?.role ?? 'student';
    final grade    = user?.gradeLevel ?? '';

    final level    = gData?.level ?? 1;
    final xp       = gData?.totalXp ?? 0;
    final streak   = gData?.currentStreak ?? 0;
    final badges   = gData?.badges.length ?? 0;

    final creditLevel = _creditLevel(totalEarned);
    final ykCode = _generateYkCode(user?.id ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => context.push(RouteNames.settings),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHero(
                name: name,
                role: role,
                grade: grade,
                level: level,
                creditLevel: creditLevel,
                avatarEmoji: _avatarEmoji(user?.id ?? ''),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats row ───────────────────────────────────────────
                Row(children: [
                  Expanded(child: _StatCard(
                      icon: Icons.military_tech_rounded, label: 'Niveau',
                      value: '$level', color: AppColors.gold)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                      icon: Icons.bolt_rounded, label: 'XP total',
                      value: '$xp', color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                      icon: Icons.local_fire_department_rounded, label: 'Série',
                      value: '${streak}j', color: AppColors.streakOrange)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                      icon: Icons.workspace_premium_rounded, label: 'Badges',
                      value: '$badges', color: AppColors.levelPurple)),
                ]),
                const SizedBox(height: 20),

                // ── Credits card ─────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push(RouteNames.credits),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A2A00), AppColors.gold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(children: [
                      const Text('⭐', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('$credits crédits',
                                style: const TextStyle(color: Colors.white,
                                    fontFamily: 'Nunito', fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            _LevelBadge(level: creditLevel),
                          ]),
                          Text('$totalEarned crédits gagnés au total',
                              style: const TextStyle(color: Colors.white70,
                                  fontFamily: 'Nunito', fontSize: 12)),
                        ],
                      )),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white60),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // ── YK Code ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mon code yikri',
                            style: TextStyle(fontFamily: 'Nunito',
                                fontSize: 12, color: AppColors.onSurfaceVariant)),
                        Text(ykCode, style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                            letterSpacing: 1.5)),
                      ],
                    )),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.primary, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: ykCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copié !',
                                style: TextStyle(fontFamily: 'Nunito')),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Actions ───────────────────────────────────────────────
                _ActionTile(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  onTap: () => context.push(RouteNames.settings),
                ),
                _ActionTile(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Accessibilité',
                  onTap: () => context.push(RouteNames.accessibility),
                ),
                if (role == 'teacher') ...[
                  _ActionTile(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Mon abonnement enseignant',
                    onTap: () => context.go(RouteNames.teacherSubscription),
                  ),
                ],
                if (role == 'parent') ...[
                  _ActionTile(
                    icon: Icons.child_care_rounded,
                    label: 'Lier un enfant',
                    onTap: () => context.push(RouteNames.parentLink),
                  ),
                ],
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Se déconnecter',
                  color: AppColors.error,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _creditLevel(int totalEarned) {
    if (totalEarned >= AppConstants.levelSageThreshold) return 'Sage';
    if (totalEarned >= AppConstants.levelEruditThreshold) return 'Érudit';
    return 'Apprenti';
  }

  String _avatarEmoji(String userId) {
    const avatars = ['🦁', '🐘', '🦊', '🦅', '🐆', '🦋'];
    if (userId.isEmpty) return avatars[0];
    return avatars[userId.hashCode.abs() % avatars.length];
  }

  String _generateYkCode(String userId) {
    if (userId.isEmpty) return 'YK-0000-BF';
    final hash = userId.hashCode.abs() % 10000;
    return 'YK-${hash.toString().padLeft(4, '0')}-BF';
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter ?',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: const Text('Tu devras te reconnecter la prochaine fois.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(fontFamily: 'Nunito',
                    color: AppColors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnecter',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Hero ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String name, role, grade, creditLevel, avatarEmoji;
  final int level;

  const _ProfileHero({
    required this.name, required this.role, required this.grade,
    required this.level, required this.creditLevel, required this.avatarEmoji,
  });

  List<Color> get _gradientColors => switch (role) {
    'teacher' => const [Color(0xFF003D35), Color(0xFF00958A)],
    'parent'  => const [Color(0xFF3D1A00), AppColors.accent],
    _         => const [Color(0xFF1A0A3E), AppColors.primary],
  };

  String get _roleLabel => switch (role) {
    'teacher' => 'Enseignant',
    'parent'  => 'Parent',
    _         => 'Élève',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 60, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Center(
                    child: Text(avatarEmoji,
                        style: const TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      _HeroBadge(label: _roleLabel, color: Colors.white24),
                      if (grade.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _HeroBadge(label: grade, color: Colors.white15),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    _HeroBadge(label: '✨ $creditLevel', color: AppColors.gold.withOpacity(0.3)),
                  ],
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HeroBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white,
          fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Level Badge ───────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(level, style: const TextStyle(color: Colors.white,
          fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withOpacity(0.12),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontFamily: 'Nunito',
            fontSize: 15, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 9, color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(label, style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w600, color: color)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.grey400, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
