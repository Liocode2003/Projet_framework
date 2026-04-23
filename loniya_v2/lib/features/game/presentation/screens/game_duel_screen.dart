import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class GameDuelScreen extends ConsumerWidget {
  const GameDuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = (user?.name ?? 'Joueur').split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        title: const Text('Duel',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('⚔️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Défi un(e) autre élève, $name !',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white,
                  fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Le duel asynchrone est en cours de développement.\n'
              'Tu pourras bientôt lancer un défi avec un code et voir '
              'les scores de ton adversaire !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54,
                  fontFamily: 'Nunito', fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(children: [
                const Text('Comment ça marche ?',
                    style: TextStyle(color: Colors.white,
                        fontFamily: 'Nunito', fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _Step(num: '1', text: 'Tu joues ta partie de Sprint 60s'),
                _Step(num: '2', text: 'Tu partages ton code défi'),
                _Step(num: '3', text: 'L\'adversaire joue la même grille'),
                _Step(num: '4', text: 'Le meilleur score gagne !'),
              ]),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.construction_rounded, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Text('Disponible bientôt — Bêta',
                    style: TextStyle(color: AppColors.primary,
                        fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num, text;
  const _Step({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num, style: const TextStyle(
                color: AppColors.primary, fontFamily: 'Nunito',
                fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(
            color: Colors.white70, fontFamily: 'Nunito', fontSize: 13))),
      ]),
    );
  }
}
