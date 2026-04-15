import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/learning_provider.dart';
import '../widgets/situation_card.dart';
import '../widgets/step_card.dart';
import '../widgets/hint_panel.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId; // lesson id OR content item id
  const LessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  static const _subjectColors = {
    'Mathématiques':      AppColors.primary,
    'Français':           AppColors.secondary,
    'Sciences':           AppColors.orientation,
    'Histoire-Géographie': AppColors.tertiary,
    'Physique-Chimie':    AppColors.aiTutor,
    'Anglais':            AppColors.teacher,
  };

  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    // Listen for completion → navigate once
    ref.listen<AsyncValue<LessonState>>(
      lessonNotifierProvider(widget.lessonId),
      (_, next) {
        if (_navigated) return;
        next.whenData((ls) {
          if (ls.isCompleted && !_navigated) {
            _navigated = true;
            context.go(
              '${RouteNames.learning}/${widget.lessonId}/result',
            );
          }
        });
      },
    );

    final stateAsync = ref.watch(lessonNotifierProvider(widget.lessonId));

    return stateAsync.when(
      loading: () => const Scaffold(body: Center(child: InlineLoader())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(lessonNotifierProvider(widget.lessonId)),
        ),
      ),
      data: (ls) {
        final color =
            _subjectColors[ls.lesson.subject] ?? AppColors.grey500;
        final notifier =
            ref.read(lessonNotifierProvider(widget.lessonId).notifier);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // ── AppBar with progress ──────────────────────────────────
              _LessonAppBar(
                title: ls.lesson.title,
                subject: ls.lesson.subject,
                currentStep: ls.currentStepIndex + 1,
                totalSteps: ls.lesson.totalSteps,
                progress: ls.progressPercent,
                color: color,
              ),

              // ── Scrollable content ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Situation banner (always visible)
                      SituationCard(
                        lesson: ls.lesson,
                        subjectColor: color,
                      ),
                      const SizedBox(height: 12),

                      // Current step card
                      StepCard(
                        step:          ls.currentStep,
                        lessonState:   ls,
                        subjectColor:  color,
                        onAdvance:     notifier.advance,
                        onSubmit:      notifier.submitAnswer,
                        onRetry:       notifier.retryAnswer,
                        onReveal:      notifier.revealAnswer,
                        onAdvanceAfterCorrect:
                            notifier.advanceAfterCorrect,
                        onAnswerChanged: notifier.setAnswer,
                      ),

                      // Hints panel (if step has hints)
                      if (ls.currentStep.hints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        HintPanel(hints: ls.currentStep.hints),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Saving indicator ──────────────────────────────────────
              if (ls.isSaving)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: AppColors.infoLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Sauvegarde en cours…',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.info)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Custom App Bar ───────────────────────────────────────────────────────────
class _LessonAppBar extends StatelessWidget {
  final String title;
  final String subject;
  final int currentStep;
  final int totalSteps;
  final double progress;
  final Color color;

  const _LessonAppBar({
    required this.title,
    required this.subject,
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _confirmExit(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subject,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$currentStep / $totalSteps',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ]),
            ),
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.grey200,
              color: color,
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter la leçon ?'),
        content: const Text(
          'Ta progression sera sauvegardée. '
          'Tu pourras reprendre là où tu t\'es arrêté.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer la leçon'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
