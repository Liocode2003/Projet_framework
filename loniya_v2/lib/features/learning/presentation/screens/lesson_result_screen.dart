import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/learning_provider.dart';

class LessonResultScreen extends ConsumerWidget {
  final String lessonId;
  const LessonResultScreen({super.key, required this.lessonId});

  static const _subjectColors = {
    'Mathématiques':      AppColors.primary,
    'Français':           AppColors.secondary,
    'Sciences':           AppColors.orientation,
    'Histoire-Géographie': AppColors.tertiary,
    'Physique-Chimie':    AppColors.aiTutor,
    'Anglais':            AppColors.teacher,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(lessonNotifierProvider(lessonId));

    // Fallback while loading (e.g. navigated directly to result URL)
    final xpEarned = stateAsync.whenOrNull(data: (s) => s.xpEarned) ?? 0;
    final score    = stateAsync.whenOrNull(data: (s) => s.score) ?? 100;
    final lesson   = stateAsync.whenOrNull(data: (s) => s.lesson);
    final color    = lesson != null
        ? (_subjectColors[lesson.subject] ?? AppColors.grey500)
        : AppColors.learning;

    final grade = _grade(score);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ── Trophy ────────────────────────────────────────────────
              _TrophyWidget(score: score, color: color),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────────────
              Text(
                grade.title,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (lesson != null)
                Text(
                  lesson.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),

              // ── Stats row ─────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_rounded,
                    iconColor: AppColors.xpGold,
                    value: '+$xpEarned',
                    label: 'XP gagnés',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: color,
                    value: '$score%',
                    label: 'Score',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.info,
                    value: '${lesson?.totalSteps ?? 0}',
                    label: 'Étapes',
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Grade message ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: grade.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: grade.color.withOpacity(0.25)),
                ),
                child: Text(
                  grade.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // ── Actions ───────────────────────────────────────────────
              AppButton(
                label: 'Retour aux leçons',
                prefixIcon: Icons.menu_book_rounded,
                backgroundColor: color,
                foregroundColor: Colors.white,
                onPressed: () => context.go(RouteNames.learning),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Accueil',
                prefixIcon: Icons.home_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: () => context.go(RouteNames.home),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  _GradeInfo _grade(int score) {
    if (score >= 90) {
      return _GradeInfo(
        title: 'Excellent ! 🎉',
        message:
            'Tu maîtrises parfaitement ce contenu. Continue comme ça !',
        color: AppColors.success,
      );
    } else if (score >= 70) {
      return _GradeInfo(
        title: 'Bien joué !',
        message:
            'Tu as bien compris l\'essentiel. Relis les points difficiles.',
        color: AppColors.info,
      );
    } else if (score >= 50) {
      return _GradeInfo(
        title: 'Pas mal !',
        message:
            'Tu progresses. Reprends la leçon pour consolider tes connaissances.',
        color: AppColors.warning,
      );
    }
    return _GradeInfo(
      title: 'Continue d\'essayer',
      message:
          'Chaque erreur est une leçon. Reprends depuis le début, tu peux y arriver !',
      color: AppColors.tertiary,
    );
  }
}

class _GradeInfo {
  final String title;
  final String message;
  final Color color;
  const _GradeInfo({
    required this.title,
    required this.message,
    required this.color,
  });
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────
class _TrophyWidget extends StatelessWidget {
  final int score;
  final Color color;
  const _TrophyWidget({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3), width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            score >= 90
                ? Icons.emoji_events_rounded
                : Icons.school_rounded,
            size: 44,
            color: score >= 90 ? AppColors.xpGold : color,
          ),
          const SizedBox(height: 4),
          Text(
            '$score%',
            style: AppTextStyles.headlineLarge.copyWith(
              color: color,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w900,
            )),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.onSurfaceVariant)),
      ]),
    );
  }
}
