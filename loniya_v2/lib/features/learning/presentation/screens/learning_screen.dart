import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/lesson_entity.dart';
import '../providers/learning_provider.dart';
import '../widgets/lesson_card.dart';

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableLessonsProvider);
    final allAsync       = ref.watch(allLessonsProvider);
    final userId         = ref.watch(currentUserProvider)?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.learning, AppColors.secondaryDark],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Apprendre',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            )),
                        SizedBox(height: 4),
                        Text('Parcours APC pas à pas',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            )),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
          ),

          // ─── Downloaded lessons ───────────────────────────────────────
          availableAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: InlineLoader()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorWidget(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(availableLessonsProvider),
              ),
            ),
            data: (available) {
              if (available.isEmpty) {
                return allAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: InlineLoader()),
                  ),
                  error: (_, __) => const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.menu_book_rounded,
                      title: 'Aucune leçon disponible',
                      subtitle:
                          'Téléchargez du contenu dans le Marché pour commencer.',
                      color: AppColors.learning,
                    ),
                  ),
                  data: (all) => _LessonList(
                    lessons: all,
                    userId: userId,
                    ref: ref,
                    sectionTitle: 'Toutes les leçons',
                    hint:
                        'Téléchargez le contenu depuis le Marché pour y accéder hors-ligne.',
                  ),
                );
              }
              return _LessonList(
                lessons: available,
                userId: userId,
                ref: ref,
                sectionTitle: 'Contenu disponible (${available.length})',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Lesson list sliver ───────────────────────────────────────────────────────
class _LessonList extends StatelessWidget {
  final List<LessonEntity> lessons;
  final String userId;
  final WidgetRef ref;
  final String sectionTitle;
  final String? hint;

  const _LessonList({
    required this.lessons,
    required this.userId,
    required this.ref,
    required this.sectionTitle,
    this.hint,
  });

  static const _subjectColors = {
    'Mathématiques':      AppColors.primary,
    'Français':           AppColors.secondary,
    'Sciences':           AppColors.orientation,
    'Histoire-Géographie': AppColors.tertiary,
    'Physique-Chimie':    AppColors.aiTutor,
    'Anglais':            AppColors.teacher,
  };

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(sectionTitle, style: AppTextStyles.titleMedium),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: AppTextStyles.caption
                .copyWith(color: AppColors.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          ...lessons.map((lesson) {
            final color = _subjectColors[lesson.subject] ?? AppColors.grey500;
            final progress = ref
                .read(databaseServiceProvider)
                .getProgress(userId, lesson.id);
            return LessonCard(
              lesson:       lesson,
              progress:     progress,
              subjectColor: color,
              onTap: () => context.go(
                '${RouteNames.learning}/${lesson.contentItemId}',
              ),
            );
          }),
        ]),
      ),
    );
  }
}
