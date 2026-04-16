import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/database/database_service.dart';
import '../../data/datasources/learning_local_datasource.dart';
import '../../data/models/progress_model.dart';
import '../../data/repositories/learning_repository_impl.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/step_entity.dart';
import '../../domain/repositories/learning_repository.dart';
import '../../domain/usecases/get_all_lessons_usecase.dart';
import '../../domain/usecases/get_available_lessons_usecase.dart';
import '../../domain/usecases/get_lesson_usecase.dart';
import '../../domain/usecases/save_progress_usecase.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────
final learningLocalDataSourceProvider =
    Provider<LearningLocalDataSource>((ref) {
  return LearningLocalDataSource(ref.read(databaseServiceProvider));
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepositoryImpl(ref.read(learningLocalDataSourceProvider));
});

// ─── Use-case providers ───────────────────────────────────────────────────────
final getAllLessonsUseCaseProvider = Provider(
  (ref) => GetAllLessonsUseCase(ref.read(learningRepositoryProvider)),
);
final getAvailableLessonsUseCaseProvider = Provider(
  (ref) => GetAvailableLessonsUseCase(ref.read(learningRepositoryProvider)),
);
final getLessonUseCaseProvider = Provider(
  (ref) => GetLessonUseCase(ref.read(learningRepositoryProvider)),
);
final saveProgressUseCaseProvider = Provider(
  (ref) => SaveProgressUseCase(ref.read(learningRepositoryProvider)),
);

// ─── Content providers ────────────────────────────────────────────────────────
final availableLessonsProvider =
    FutureProvider.autoDispose<List<LessonEntity>>((ref) async {
  final result = await ref.read(getAvailableLessonsUseCaseProvider).call();
  return result.fold(
    (f) => throw Exception(f.message),
    (list) => list,
  );
});

final allLessonsProvider =
    FutureProvider.autoDispose<List<LessonEntity>>((ref) async {
  final result = await ref.read(getAllLessonsUseCaseProvider).call();
  return result.fold(
    (f) => throw Exception(f.message),
    (list) => list,
  );
});

final lessonProvider =
    FutureProvider.autoDispose.family<LessonEntity, String>((ref, id) async {
  final result = await ref.read(getLessonUseCaseProvider).call(id);
  return result.fold(
    (f) => throw Exception(f.message),
    (lesson) => lesson,
  );
});

// ─── Lesson State ─────────────────────────────────────────────────────────────
enum AnswerStatus { idle, correct, wrong, revealed }

class LessonState {
  final LessonEntity lesson;
  final int currentStepIndex;
  final Set<int> completedSteps;
  final String userAnswer;
  final AnswerStatus answerStatus;
  final int xpEarned;
  final int wrongAttemptsOnCurrentStep;
  final bool isCompleted;
  final bool isSaving;

  const LessonState({
    required this.lesson,
    this.currentStepIndex = 0,
    this.completedSteps = const {},
    this.userAnswer = '',
    this.answerStatus = AnswerStatus.idle,
    this.xpEarned = 0,
    this.wrongAttemptsOnCurrentStep = 0,
    this.isCompleted = false,
    this.isSaving = false,
  });

  StepEntity get currentStep => lesson.steps[currentStepIndex];
  bool get isLastStep => currentStepIndex >= lesson.steps.length - 1;
  bool get currentStepDone => completedSteps.contains(currentStepIndex);

  double get progressPercent => lesson.totalSteps > 0
      ? completedSteps.length / lesson.totalSteps
      : 0.0;

  int get score {
    if (lesson.totalSteps == 0) return 0;
    return ((completedSteps.length / lesson.totalSteps) * 100).round();
  }

  LessonState copyWith({
    int? currentStepIndex,
    Set<int>? completedSteps,
    String? userAnswer,
    AnswerStatus? answerStatus,
    int? xpEarned,
    int? wrongAttemptsOnCurrentStep,
    bool? isCompleted,
    bool? isSaving,
  }) =>
      LessonState(
        lesson:                     lesson,
        currentStepIndex:           currentStepIndex ?? this.currentStepIndex,
        completedSteps:             completedSteps ?? this.completedSteps,
        userAnswer:                 userAnswer ?? this.userAnswer,
        answerStatus:               answerStatus ?? this.answerStatus,
        xpEarned:                   xpEarned ?? this.xpEarned,
        wrongAttemptsOnCurrentStep: wrongAttemptsOnCurrentStep ??
            this.wrongAttemptsOnCurrentStep,
        isCompleted: isCompleted ?? this.isCompleted,
        isSaving:    isSaving ?? this.isSaving,
      );
}

// ─── Lesson Notifier ──────────────────────────────────────────────────────────
class LessonNotifier extends StateNotifier<AsyncValue<LessonState>> {
  final Ref _ref;
  final String _lessonId; // lesson id OR content item id

  LessonNotifier(this._ref, this._lessonId)
      : super(const AsyncLoading()) {
    _init();
  }

  LessonState get _s => (state as AsyncData<LessonState>).value;

  Future<void> _init() async {
    try {
      final repo = _ref.read(learningRepositoryProvider);
      final result = await repo.getLessonById(_lessonId);
      result.fold(
        (f) => state = AsyncError(Exception(f.message), StackTrace.current),
        (lesson) {
          final userId = _ref.read(currentUserProvider)?.id ?? '';
          final saved = _ref
              .read(databaseServiceProvider)
              .getProgress(userId, lesson.id);

          state = AsyncData(LessonState(
            lesson:            lesson,
            currentStepIndex:  saved?.currentStepIndex ?? 0,
            completedSteps:    Set<int>.from(saved?.completedSteps ?? []),
            xpEarned:          saved?.xpEarned ?? 0,
            isCompleted:       saved?.isCompleted ?? false,
          ));
        },
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ─── Answer handling ───────────────────────────────────────────────────────
  void setAnswer(String answer) {
    if (state is! AsyncData) return;
    state = AsyncData(_s.copyWith(
      userAnswer: answer,
      answerStatus: AnswerStatus.idle,
    ));
  }

  void submitAnswer() {
    if (state is! AsyncData) return;
    final step = _s.currentStep;
    if (!step.requiresAnswer || step.expectedAnswer == null) return;

    final correct = _normalize(_s.userAnswer) == _normalize(step.expectedAnswer!);
    if (correct) {
      final xp = _s.wrongAttemptsOnCurrentStep > 0
          ? (step.xpReward * 0.6).round()
          : step.xpReward;
      state = AsyncData(_s.copyWith(
        answerStatus: AnswerStatus.correct,
        xpEarned: _s.xpEarned + xp,
      ));
    } else {
      state = AsyncData(_s.copyWith(
        answerStatus: AnswerStatus.wrong,
        wrongAttemptsOnCurrentStep: _s.wrongAttemptsOnCurrentStep + 1,
      ));
    }
  }

  void retryAnswer() {
    if (state is! AsyncData) return;
    state = AsyncData(_s.copyWith(
      answerStatus: AnswerStatus.idle,
      userAnswer: '',
    ));
  }

  void revealAnswer() {
    if (state is! AsyncData) return;
    final step = _s.currentStep;
    final xp = (step.xpReward * 0.25).round();
    state = AsyncData(_s.copyWith(
      answerStatus: AnswerStatus.revealed,
      xpEarned: _s.xpEarned + xp,
    ));
  }

  // ─── Step navigation ───────────────────────────────────────────────────────

  /// Called for read / validation steps — marks step done and advances.
  Future<void> advance() async {
    if (state is! AsyncData) return;
    final idx = _s.currentStepIndex;
    final step = _s.currentStep;

    // Add XP for read and validation steps
    int newXp = _s.xpEarned;
    if (step.isReadOnly || step.isFinal) {
      newXp += step.xpReward;
    }

    final newCompleted = {..._s.completedSteps, idx};

    if (_s.isLastStep || step.isFinal) {
      // Lesson complete
      await _complete(newCompleted, newXp);
    } else {
      state = AsyncData(_s.copyWith(
        currentStepIndex:           idx + 1,
        completedSteps:             newCompleted,
        userAnswer:                 '',
        answerStatus:               AnswerStatus.idle,
        wrongAttemptsOnCurrentStep: 0,
        xpEarned:                   newXp,
      ));
      await _autoSave(newCompleted, newXp);
    }
  }

  /// Called after a correct answer is confirmed (question / exercise steps).
  Future<void> advanceAfterCorrect() async {
    if (state is! AsyncData) return;
    final idx = _s.currentStepIndex;
    final newCompleted = {..._s.completedSteps, idx};

    if (_s.isLastStep) {
      await _complete(newCompleted, _s.xpEarned);
    } else {
      state = AsyncData(_s.copyWith(
        currentStepIndex:           idx + 1,
        completedSteps:             newCompleted,
        userAnswer:                 '',
        answerStatus:               AnswerStatus.idle,
        wrongAttemptsOnCurrentStep: 0,
      ));
      await _autoSave(newCompleted, _s.xpEarned);
    }
  }

  // ─── Persistence ───────────────────────────────────────────────────────────
  Future<void> _complete(Set<int> completed, int xp) async {
    state = AsyncData(_s.copyWith(
      completedSteps: completed,
      isCompleted: true,
      isSaving: true,
      xpEarned: xp,
    ));

    final userId = _ref.read(currentUserProvider)?.id ?? '';
    final lesson = _s.lesson;
    final score = lesson.totalSteps > 0
        ? ((completed.length / lesson.totalSteps) * 100).round()
        : 100;

    final progress = ProgressModel(
      id:               '${userId}_${lesson.id}',
      userId:           userId,
      lessonId:         lesson.id,
      currentStepIndex: lesson.totalSteps - 1,
      isCompleted:      true,
      score:            score,
      xpEarned:         xp,
      startedAt:        DateTime.now().toIso8601String(),
      completedAt:      DateTime.now().toIso8601String(),
      completedSteps:   completed.toList()..sort(),
      attempts:         1,
      syncPending:      true,
    );

    await _ref.read(databaseServiceProvider).saveProgress(progress);

    // Add XP to gamification
    await _ref
        .read(databaseServiceProvider)
        .addXp(userId, xp, subject: lesson.subject);

    state = AsyncData(_s.copyWith(isSaving: false));
  }

  Future<void> _autoSave(Set<int> completed, int xp) async {
    final userId = _ref.read(currentUserProvider)?.id ?? '';
    final lesson = _s.lesson;
    final existing = _ref
        .read(databaseServiceProvider)
        .getProgress(userId, lesson.id);

    final progress = ProgressModel(
      id:               '${userId}_${lesson.id}',
      userId:           userId,
      lessonId:         lesson.id,
      currentStepIndex: _s.currentStepIndex,
      isCompleted:      false,
      score:            0,
      xpEarned:         xp,
      startedAt:        existing?.startedAt ?? DateTime.now().toIso8601String(),
      completedSteps:   completed.toList()..sort(),
      attempts:         existing?.attempts ?? 1,
      syncPending:      true,
    );
    await _ref.read(databaseServiceProvider).saveProgress(progress);
  }

  // ─── Helper ────────────────────────────────────────────────────────────────
  static String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final lessonNotifierProvider = StateNotifierProvider.autoDispose
    .family<LessonNotifier, AsyncValue<LessonState>, String>(
  (ref, lessonId) => LessonNotifier(ref, lessonId),
);

// Convenience: current user progress for a given lesson id
final lessonProgressProvider =
    Provider.autoDispose.family<ProgressModel?, String>((ref, lessonId) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return ref.read(databaseServiceProvider).getProgress(userId, lessonId);
});
