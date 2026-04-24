import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/credit_provider.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model   = ref.watch(creditNotifierProvider);
    final balance = model?.total ?? AppConstants.creditBase;
    final bonus   = model?.bonus ?? 0;
    final base    = model?.base ?? AppConstants.creditBase;
    final earned  = model?.totalEarned ?? 0;
    final spent   = model?.totalSpent ?? 0;
    final bonusCap = AppConstants.creditBonusCap;

    final level       = _level(earned);
    final nextLevel   = _nextLevelThreshold(earned);
    final levelProgress = nextLevel > 0
        ? (earned / nextLevel).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes crédits',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance Card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3A2A00), AppColors.gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(children: [
                const Text('⭐', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text('$balance', style: const TextStyle(
                    color: Colors.white, fontFamily: 'Nunito',
                    fontSize: 52, fontWeight: FontWeight.w900)),
                const Text('crédits disponibles', style: TextStyle(
                    color: Colors.white70, fontFamily: 'Nunito', fontSize: 14)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _BalancePart(label: 'Base (garantis)',
                      value: '$base', icon: '🛡️'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _BalancePart(label: 'Bonus ce mois',
                      value: '$bonus / $bonusCap', icon: '🎁'),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Level progress ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.shadow,
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Niveau : $level', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 16,
                        fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                    const Spacer(),
                    Text('$earned crédits cumulés',
                        style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (nextLevel > 0)
                    Text(
                      'Encore ${nextLevel - earned} crédits pour atteindre '
                      '${_nextLevelName(earned)}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                          color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── How to earn ───────────────────────────────────────────────
            const Text('Comment gagner des crédits ?',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 17,
                    fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const SizedBox(height: 12),

            _EarnCard(icon: '🎮', label: 'Niveau de jeu complété',
                gain: '+${AppConstants.creditPerGame}'),
            _EarnCard(icon: '🌿', label: 'Défi Le Sage réussi',
                gain: '+${AppConstants.creditPerChallenge}'),
            _EarnCard(icon: '📝', label: 'QCM parfait (100%)',
                gain: '+${AppConstants.creditPerPerfectQcm}'),
            _EarnCard(icon: '🔥', label: 'Série 3 jours consécutifs',
                gain: '+${AppConstants.creditPerStreak3days}'),
            _EarnCard(icon: '💎', label: 'Série 7 jours consécutifs',
                gain: '+${AppConstants.creditPerStreak7days}'),
            const SizedBox(height: 20),

            // ── How to use ────────────────────────────────────────────────
            const Text('Comment utiliser tes crédits ?',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 17,
                    fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const SizedBox(height: 12),

            _UseCard(
              icon: '📚',
              title: '-50% sur un cours',
              subtitle: 'Utilise ${AppConstants.creditThreshold50} crédits bonus',
              value: '100 FCFA',
              unlocked: bonus >= AppConstants.creditThreshold50,
            ),
            const SizedBox(height: 10),
            _UseCard(
              icon: '🎓',
              title: 'Cours gratuit',
              subtitle: 'Utilise ${AppConstants.creditThresholdFree} crédits bonus',
              value: '0 FCFA',
              unlocked: bonus >= AppConstants.creditThresholdFree,
            ),
            const SizedBox(height: 20),

            // ── Stats ─────────────────────────────────────────────────────
            Row(children: [
              Expanded(child: _StatBox(
                  label: 'Gagnés (total)', value: '$earned', color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(
                  label: 'Dépensés (total)', value: '$spent', color: AppColors.accent)),
            ]),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Les crédits de base (20) ne peuvent pas être dépensés — '
                  'seuls les crédits bonus sont utilisables.',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                      color: AppColors.info, height: 1.4),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _level(int totalEarned) {
    if (totalEarned >= AppConstants.levelSageThreshold) return 'Sage';
    if (totalEarned >= AppConstants.levelEruditThreshold) return 'Érudit';
    return 'Apprenti';
  }

  int _nextLevelThreshold(int totalEarned) {
    if (totalEarned < AppConstants.levelEruditThreshold) {
      return AppConstants.levelEruditThreshold;
    }
    if (totalEarned < AppConstants.levelSageThreshold) {
      return AppConstants.levelSageThreshold;
    }
    return 0;
  }

  String _nextLevelName(int totalEarned) {
    if (totalEarned < AppConstants.levelEruditThreshold) return 'Érudit';
    return 'Sage';
  }
}

// ── Balance Part ──────────────────────────────────────────────────────────────

class _BalancePart extends StatelessWidget {
  final String label, value, icon;
  const _BalancePart({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white,
          fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white60,
          fontFamily: 'Nunito', fontSize: 11)),
    ]);
  }
}

// ── Earn Card ─────────────────────────────────────────────────────────────────

class _EarnCard extends StatelessWidget {
  final String icon, label, gain;
  const _EarnCard({required this.icon, required this.label, required this.gain});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.onSurface))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(gain, style: const TextStyle(
              color: AppColors.success, fontFamily: 'Nunito',
              fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ── Use Card ──────────────────────────────────────────────────────────────────

class _UseCard extends StatelessWidget {
  final String icon, title, subtitle, value;
  final bool unlocked;
  const _UseCard({required this.icon, required this.title, required this.subtitle,
      required this.value, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.successLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: unlocked ? AppColors.success.withOpacity(0.3) : AppColors.outline),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
            Text(subtitle, style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 14, fontWeight: FontWeight.w900,
              color: AppColors.primary)),
          if (unlocked)
            const Text('Disponible ✓', style: TextStyle(fontFamily: 'Nunito',
                fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

// ── Stat Box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontFamily: 'Nunito', fontSize: 22,
            fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
            color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
      ]),
    );
  }
}
