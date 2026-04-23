import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../credits/presentation/providers/credit_provider.dart';

// A simplified Défi Le Sage: 5 quick questions, reward credits on ≥80%

class GameSageScreen extends ConsumerStatefulWidget {
  const GameSageScreen({super.key});

  @override
  ConsumerState<GameSageScreen> createState() => _GameSageScreenState();
}

class _GameSageScreenState extends ConsumerState<GameSageScreen> {
  static const _questions = [
    _Question(
      question: 'Quelle est la capitale du Burkina Faso ?',
      options: ['Bobo-Dioulasso', 'Ouagadougou', 'Koudougou', 'Dédougou'],
      answer: 1,
    ),
    _Question(
      question: 'Combien font 7 × 8 ?',
      options: ['54', '56', '64', '48'],
      answer: 1,
    ),
    _Question(
      question: 'Quelle est la formule de l\'eau ?',
      options: ['CO₂', 'H₂O', 'O₂', 'NaCl'],
      answer: 1,
    ),
    _Question(
      question: 'Qui a écrit "Les Misérables" ?',
      options: ['Molière', 'Voltaire', 'Victor Hugo', 'Balzac'],
      answer: 2,
    ),
    _Question(
      question: 'En quelle année le Burkina Faso a obtenu l\'indépendance ?',
      options: ['1958', '1960', '1965', '1970'],
      answer: 1,
    ),
  ];

  int _current  = 0;
  int _correct  = 0;
  bool _done    = false;
  int? _chosen;

  void _answer(int idx) {
    if (_chosen != null) return;
    setState(() => _chosen = idx);

    final isCorrect = idx == _questions[_current].answer;
    if (isCorrect) _correct++;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_current < _questions.length - 1) {
        setState(() { _current++; _chosen = null; });
      } else {
        setState(() => _done = true);
        _onFinish();
      }
    });
  }

  void _onFinish() {
    final pct = _correct / _questions.length;
    if (pct >= 0.8) {
      ref.read(creditNotifierProvider.notifier)
          .addBonus(AppConstants.creditPerChallenge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = (user?.name ?? 'Joueur').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Défi Le Sage',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _done ? _ResultView(
        correct: _correct,
        total: _questions.length,
        name: name,
        onRetry: () => setState(() {
          _current = 0; _correct = 0; _done = false; _chosen = null;
        }),
        onHome: () => context.go(RouteNames.game),
      ) : _QuestionView(
        question: _questions[_current],
        index: _current,
        total: _questions.length,
        chosen: _chosen,
        onAnswer: _answer,
      ),
    );
  }
}

// ── Question View ─────────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final _Question question;
  final int index, total;
  final int? chosen;
  final ValueChanged<int> onAnswer;

  const _QuestionView({
    required this.question, required this.index, required this.total,
    required this.chosen, required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Question ${index+1}/$total',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.onSurfaceVariant)),
            const Text('🌿 Le Sage te teste',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.sage, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (index + 1) / total,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.sage),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 32),

          // Question bubble
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A2A), AppColors.sage],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🌿', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Text(question.question,
                  style: const TextStyle(color: Colors.white,
                      fontFamily: 'Nunito', fontSize: 16,
                      fontWeight: FontWeight.w700, height: 1.4))),
            ]),
          ),
          const SizedBox(height: 28),

          // Options
          ...List.generate(question.options.length, (i) {
            Color bgColor = Colors.white;
            Color borderColor = AppColors.outline;
            Color textColor = AppColors.onSurface;

            if (chosen != null) {
              if (i == question.answer) {
                bgColor = AppColors.successLight;
                borderColor = AppColors.success;
                textColor = AppColors.success;
              } else if (i == chosen && i != question.answer) {
                bgColor = AppColors.errorLight;
                borderColor = AppColors.error;
                textColor = AppColors.error;
              }
            }

            return GestureDetector(
              onTap: chosen == null ? () => onAnswer(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow.withOpacity(0.08),
                        blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(question.options[i],
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                        fontWeight: FontWeight.w600, color: textColor)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Result View ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final int correct, total;
  final String name;
  final VoidCallback onRetry, onHome;

  const _ResultView({
    required this.correct, required this.total,
    required this.name, required this.onRetry, required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final pct      = correct / total;
    final success  = pct >= 0.8;
    final emoji    = pct == 1.0 ? '🏆' : pct >= 0.8 ? '🌟' : pct >= 0.6 ? '💪' : '📚';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          Text('$correct / $total bonnes réponses',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 24,
                  fontWeight: FontWeight.w900, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text(
            success
                ? 'Excellent $name ! Le Sage est fier de toi.'
                : 'Bien essayé $name ! Continue à apprendre.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                color: AppColors.onSurfaceVariant, height: 1.5),
          ),
          if (success) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 6),
                Text('+${AppConstants.creditPerChallenge} crédits gagnés !',
                    style: const TextStyle(color: AppColors.gold,
                        fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
            ),
          ],
          const SizedBox(height: 32),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: onHome,
              child: const Text('Accueil jeu',
                  style: TextStyle(fontFamily: 'Nunito')),
            )),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.sage),
              child: const Text('Rejouer',
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Question {
  final String question;
  final List<String> options;
  final int answer;
  const _Question({required this.question, required this.options, required this.answer});
}
