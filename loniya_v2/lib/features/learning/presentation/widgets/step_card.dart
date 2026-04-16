import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/step_entity.dart';
import '../providers/learning_provider.dart';
import 'rich_content.dart';

class StepCard extends StatefulWidget {
  final StepEntity step;
  final LessonState lessonState;
  final Color subjectColor;
  final VoidCallback onAdvance;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onReveal;
  final VoidCallback onAdvanceAfterCorrect;
  final void Function(String) onAnswerChanged;

  const StepCard({
    super.key,
    required this.step,
    required this.lessonState,
    required this.subjectColor,
    required this.onAdvance,
    required this.onSubmit,
    required this.onRetry,
    required this.onReveal,
    required this.onAdvanceAfterCorrect,
    required this.onAnswerChanged,
  });

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(StepCard old) {
    super.didUpdateWidget(old);
    // Clear input when step changes
    if (old.step.index != widget.step.index) {
      _ctrl.clear();
      _focus.unfocus();
    }
    // Restore answer text if user is retrying
    if (widget.lessonState.answerStatus == AnswerStatus.idle &&
        old.lessonState.answerStatus != AnswerStatus.idle) {
      _ctrl.clear();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step   = widget.step;
    final ls     = widget.lessonState;
    final color  = widget.subjectColor;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurveTween(curve: Curves.easeOut).animate(anim)),
          child: child,
        ),
      ),
      child: Card(
        key: ValueKey(step.index),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Step header ──────────────────────────────────────────
              Row(children: [
                _StepBadge(step.index + 1, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(step.title,
                      style: AppTextStyles.titleSmall),
                ),
                _TypeBadge(step.type),
              ]),
              const SizedBox(height: 16),

              // ── Step content ─────────────────────────────────────────
              RichContent(step.content),

              // ── Answer input (question / exercise) ────────────────────
              if (step.requiresAnswer &&
                  ls.answerStatus == AnswerStatus.idle) ...[
                const SizedBox(height: 20),
                _AnswerField(
                  ctrl:    _ctrl,
                  focus:   _focus,
                  color:   color,
                  onChanged: widget.onAnswerChanged,
                  onSubmit:  widget.onSubmit,
                ),
              ],

              // ── Feedback ──────────────────────────────────────────────
              if (ls.answerStatus == AnswerStatus.correct) ...[
                const SizedBox(height: 16),
                _FeedbackCard(
                  isCorrect: true,
                  xpGained: _xpForCurrentStep(ls, step),
                  color: color,
                ),
              ],
              if (ls.answerStatus == AnswerStatus.wrong) ...[
                const SizedBox(height: 16),
                _FeedbackCard(
                  isCorrect: false,
                  wrongAttempts: ls.wrongAttemptsOnCurrentStep,
                  color: color,
                ),
              ],
              if (ls.answerStatus == AnswerStatus.revealed) ...[
                const SizedBox(height: 16),
                _RevealCard(
                  expected: step.expectedAnswer ?? '',
                  color: color,
                ),
              ],

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────────
              _ActionRow(
                step:    step,
                ls:      ls,
                color:   color,
                ctrl:    _ctrl,
                onAdvance:            widget.onAdvance,
                onSubmit:             widget.onSubmit,
                onRetry:              widget.onRetry,
                onReveal:             widget.onReveal,
                onAdvanceAfterCorrect: widget.onAdvanceAfterCorrect,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _xpForCurrentStep(LessonState ls, StepEntity step) {
    return ls.wrongAttemptsOnCurrentStep > 0
        ? (step.xpReward * 0.6).round()
        : step.xpReward;
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StepBadge extends StatelessWidget {
  final int number;
  final Color color;
  const _StepBadge(this.number, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final StepType type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (type) {
      case StepType.read:
        label = 'Lecture'; color = AppColors.info;
      case StepType.question:
        label = 'Question'; color = AppColors.warning;
      case StepType.exercise:
        label = 'Exercice'; color = AppColors.tertiary;
      case StepType.validation:
        label = 'Bilan'; color = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnswerField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final Color color;
  final void Function(String) onChanged;
  final VoidCallback onSubmit;

  const _AnswerField({
    required this.ctrl,
    required this.focus,
    required this.color,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ta réponse :', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          focusNode: focus,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit(),
          style: AppTextStyles.bodyMedium,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Écris ta réponse ici…',
            suffixIcon: IconButton(
              icon: Icon(Icons.send_rounded, color: color),
              onPressed: onSubmit,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final int xpGained;
  final int wrongAttempts;
  final Color color;

  const _FeedbackCard({
    required this.isCorrect,
    this.xpGained = 0,
    this.wrongAttempts = 0,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isCorrect) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Excellente réponse ! +$xpGained XP',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.close_rounded, color: AppColors.error, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            wrongAttempts >= 2
                ? 'Pas tout à fait. Tu peux voir la réponse si tu veux.'
                : 'Pas tout à fait. Réessaie !',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ]),
    );
  }
}

class _RevealCard extends StatelessWidget {
  final String expected;
  final Color color;
  const _RevealCard({required this.expected, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Réponse correcte :',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(expected,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final StepEntity step;
  final LessonState ls;
  final Color color;
  final TextEditingController ctrl;
  final VoidCallback onAdvance;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onReveal;
  final VoidCallback onAdvanceAfterCorrect;

  const _ActionRow({
    required this.step,
    required this.ls,
    required this.color,
    required this.ctrl,
    required this.onAdvance,
    required this.onSubmit,
    required this.onRetry,
    required this.onReveal,
    required this.onAdvanceAfterCorrect,
  });

  @override
  Widget build(BuildContext context) {
    // Read / Validation — just a continue button
    if (step.isReadOnly || step.isFinal) {
      return AppButton(
        label: step.isFinal
            ? (ls.isLastStep ? 'Terminer la leçon' : 'Continuer')
            : 'Continuer',
        prefixIcon: step.isFinal
            ? Icons.emoji_events_rounded
            : Icons.arrow_forward_rounded,
        backgroundColor: step.isFinal ? AppColors.success : color,
        foregroundColor: Colors.white,
        onPressed: onAdvance,
      );
    }

    // Question / Exercise — depends on answer status
    switch (ls.answerStatus) {
      case AnswerStatus.idle:
        return AppButton(
          label: 'Valider ma réponse',
          prefixIcon: Icons.check_rounded,
          backgroundColor: color,
          foregroundColor: Colors.white,
          onPressed: ctrl.text.trim().isEmpty ? null : onSubmit,
        );

      case AnswerStatus.correct:
        return AppButton(
          label: ls.isLastStep ? 'Terminer la leçon' : 'Continuer',
          prefixIcon: ls.isLastStep
              ? Icons.emoji_events_rounded
              : Icons.arrow_forward_rounded,
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          onPressed: onAdvanceAfterCorrect,
        );

      case AnswerStatus.wrong:
        return Row(children: [
          Expanded(
            child: AppButton(
              label: 'Réessayer',
              prefixIcon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ),
          if (ls.wrongAttemptsOnCurrentStep >= 2) ...[
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Voir la réponse',
                prefixIcon: Icons.visibility_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: onReveal,
              ),
            ),
          ],
        ]);

      case AnswerStatus.revealed:
        return AppButton(
          label: ls.isLastStep ? 'Terminer' : 'Continuer quand même',
          prefixIcon: Icons.arrow_forward_rounded,
          variant: AppButtonVariant.outlined,
          onPressed: onAdvanceAfterCorrect,
        );
    }
  }
}
