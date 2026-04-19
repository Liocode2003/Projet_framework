import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/route_names.dart';
import '../../domain/entities/qcm_question.dart';
import '../providers/qcm_provider.dart';

class QcmScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const QcmScreen({super.key, required this.lessonId});

  @override
  ConsumerState<QcmScreen> createState() => _QcmScreenState();
}

class _QcmScreenState extends ConsumerState<QcmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qcmLoaderProvider(widget.lessonId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qcmNotifierProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('Pas assez de contenu pour générer un quiz.'),
        ),
      );
    }

    if (state.isComplete) {
      return _ResultScreen(state: state, lessonId: widget.lessonId);
    }

    return _QuestionScreen(state: state, lessonId: widget.lessonId);
  }
}

// ─── Question screen ──────────────────────────────────────────────────────────

class _QuestionScreen extends ConsumerWidget {
  final QcmState state;
  final String lessonId;
  const _QuestionScreen({required this.state, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = state.currentQuestion!;
    final answered = state.currentAnswer != null;
    final total = state.questions.length;
    final idx = state.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quiz · ${idx + 1}/$total'),
        backgroundColor: AppColors.aiTutor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('${RouteNames.learning}/$lessonId'),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          RepaintBoundary(
            child: LinearProgressIndicator(
              value: (idx + 1) / total,
              backgroundColor: AppColors.grey200,
              color: AppColors.aiTutor,
              minHeight: 4,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.aiTutor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      q.type == QuestionType.trueFalse
                          ? 'Vrai / Faux'
                          : 'Choix multiple',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.aiTutor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question text
                  Text(q.question, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 24),

                  // Options
                  ...q.options.asMap().entries.map((entry) {
                    final i = entry.key;
                    final opt = entry.value;
                    return _OptionTile(
                      text: opt,
                      index: i,
                      correctIndex: q.correctIndex,
                      selectedIndex: state.currentAnswer,
                      answered: answered,
                      onTap: answered
                          ? null
                          : () => ref
                              .read(qcmNotifierProvider.notifier)
                              .answer(i),
                    );
                  }),

                  // Explanation
                  if (answered && state.showExplanation) ...[
                    const SizedBox(height: 20),
                    _ExplanationCard(
                      isCorrect:
                          state.currentAnswer == q.correctIndex,
                      explanation: q.explanation,
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Next button
          if (answered)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.aiTutor),
                    onPressed: () =>
                        ref.read(qcmNotifierProvider.notifier).next(),
                    child: Text(
                      state.currentIndex + 1 >= state.questions.length
                          ? 'Voir les résultats'
                          : 'Question suivante',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final int index;
  final int correctIndex;
  final int? selectedIndex;
  final bool answered;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.text,
    required this.index,
    required this.correctIndex,
    required this.selectedIndex,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surface;
    Color border = AppColors.outline;
    Color textColor = AppColors.onSurface;
    IconData? trailingIcon;

    if (answered) {
      if (index == correctIndex) {
        bg = AppColors.successLight;
        border = AppColors.success;
        textColor = AppColors.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (index == selectedIndex) {
        bg = AppColors.errorLight;
        border = AppColors.error;
        textColor = AppColors.error;
        trailingIcon = Icons.cancel_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(children: [
            Expanded(
              child: Text(text,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: textColor)),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  const _ExplanationCard(
      {required this.isCorrect, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.info;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isCorrect
                  ? Icons.emoji_events_rounded
                  : Icons.info_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(isCorrect ? 'Bonne réponse !' : 'Explication',
                style: AppTextStyles.labelMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(
            explanation.length > 200
                ? '${explanation.substring(0, 200)}…'
                : explanation,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Result screen ────────────────────────────────────────────────────────────

class _ResultScreen extends StatelessWidget {
  final QcmState state;
  final String lessonId;
  const _ResultScreen({required this.state, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final pct = state.scorePercent;
    final passed = pct >= 0.6;
    final color = passed ? AppColors.success : AppColors.warning;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              RepaintBoundary(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(color: color, width: 4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.score}/${state.questions.length}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                passed ? 'Excellent travail !' : 'Continuez à pratiquer !',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                passed
                    ? 'Tu as maîtrisé cette leçon.'
                    : 'Relis la leçon pour mieux te préparer.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // XP earned
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.xpGold, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '+${state.xpEarned} XP gagnés',
                    style: const TextStyle(
                      color: AppColors.xpGold,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Retour à la leçon'),
                  onPressed: () =>
                      context.go('${RouteNames.learning}/$lessonId'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(RouteNames.learning),
                child: const Text('Toutes les leçons'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
