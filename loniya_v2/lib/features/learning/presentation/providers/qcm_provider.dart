import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/qcm_question.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../data/services/qcm_generator_engine.dart';
import '../providers/learning_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class QcmState {
  final List<QcmQuestion> questions;
  final int currentIndex;
  final List<int?> answers;       // null = not answered yet
  final bool showExplanation;
  final bool isComplete;
  final bool isLoading;

  const QcmState({
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const [],
    this.showExplanation = false,
    this.isComplete = false,
    this.isLoading = true,
  });

  int get score => answers.asMap().entries
      .where((e) => e.value != null && e.value == questions[e.key].correctIndex)
      .length;

  double get scorePercent =>
      questions.isEmpty ? 0 : score / questions.length;

  int get xpEarned => score * 20;

  QcmQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int? get currentAnswer =>
      currentIndex < answers.length ? answers[currentIndex] : null;

  QcmState copyWith({
    List<QcmQuestion>? questions,
    int? currentIndex,
    List<int?>? answers,
    bool? showExplanation,
    bool? isComplete,
    bool? isLoading,
  }) =>
      QcmState(
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        showExplanation: showExplanation ?? this.showExplanation,
        isComplete: isComplete ?? this.isComplete,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class QcmNotifier extends StateNotifier<QcmState> {
  QcmNotifier() : super(const QcmState());

  void loadFromLesson(LessonEntity lesson) {
    final questions = QcmGeneratorEngine.generate(lesson);
    state = QcmState(
      questions: questions,
      currentIndex: 0,
      answers: List.filled(questions.length, null),
      isLoading: false,
    );
  }

  void answer(int optionIndex) {
    if (state.currentAnswer != null) return; // already answered
    final updated = List<int?>.from(state.answers);
    updated[state.currentIndex] = optionIndex;
    state = state.copyWith(answers: updated, showExplanation: true);
  }

  void next() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) {
      state = state.copyWith(isComplete: true);
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        showExplanation: false,
      );
    }
  }

  void reset() {
    state = const QcmState();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final qcmNotifierProvider =
    StateNotifierProvider.autoDispose<QcmNotifier, QcmState>((ref) {
  return QcmNotifier();
});

/// Loads lesson then seeds the QCM notifier.
final qcmLoaderProvider =
    FutureProvider.autoDispose.family<void, String>((ref, lessonId) async {
  final lesson = await ref.watch(lessonProvider(lessonId).future);
  ref.read(qcmNotifierProvider.notifier).loadFromLesson(lesson);
});
