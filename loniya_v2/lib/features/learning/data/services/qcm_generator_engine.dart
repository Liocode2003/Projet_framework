import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/step_entity.dart';
import '../../domain/entities/qcm_question.dart';

class QcmGeneratorEngine {
  static const int _maxQuestions = 5;

  static List<QcmQuestion> generate(LessonEntity lesson) {
    final questions = <QcmQuestion>[];
    final allSteps = lesson.steps;

    // 1. Questions from steps with expectedAnswer (max 2)
    final answerSteps = allSteps
        .where((s) => s.expectedAnswer != null && s.expectedAnswer!.isNotEmpty)
        .toList();
    for (final step in answerSteps.take(2)) {
      questions.add(_fromExpectedAnswer(step, allSteps));
    }

    // 2. Keyword-based questions (max 2)
    final keywordSteps = allSteps
        .where((s) => s.keywords.isNotEmpty)
        .toList();
    for (final step in keywordSteps.take(2)) {
      if (questions.length >= _maxQuestions) break;
      questions.add(_fromKeywords(step, allSteps));
    }

    // 3. True/false from read steps
    for (final step in allSteps.where((s) => s.isReadOnly)) {
      if (questions.length >= _maxQuestions) break;
      questions.add(_trueFalseFromStep(step));
    }

    // Deduplicate by id
    final seen = <String>{};
    return questions.where((q) => seen.add(q.id)).toList();
  }

  static QcmQuestion _fromExpectedAnswer(
      StepEntity step, List<StepEntity> all) {
    final correct = step.expectedAnswer!;
    final distractors = all
        .where((s) => s != step && s.expectedAnswer != null && s.expectedAnswer != correct)
        .map((s) => s.expectedAnswer!)
        .take(3)
        .toList();

    _pad(distractors, all, correct);
    final opts = [correct, ...distractors]..shuffle();

    return QcmQuestion(
      id: 'exp_${step.index}',
      question: '${step.title} — quelle est la bonne réponse ?',
      options: opts,
      correctIndex: opts.indexOf(correct),
      explanation: step.content,
    );
  }

  static QcmQuestion _fromKeywords(StepEntity step, List<StepEntity> all) {
    final correct = step.keywords.first;
    final distractors = all
        .expand((s) => s.keywords)
        .where((k) => k != correct)
        .take(3)
        .toList();

    _pad(distractors, all, correct);
    final opts = [correct, ...distractors]..shuffle();

    return QcmQuestion(
      id: 'kw_${step.index}',
      question:
          'Dans la partie "${step.title}", quel concept est central ?',
      options: opts,
      correctIndex: opts.indexOf(correct),
      explanation: step.content,
    );
  }

  static QcmQuestion _trueFalseFromStep(StepEntity step) {
    final firstSentence = step.content.split('.').first.trim();
    const opts = ['Vrai', 'Faux', 'Partiellement vrai', 'Non mentionné'];

    return QcmQuestion(
      id: 'tf_${step.index}',
      question: 'Affirmation : "$firstSentence" — est-ce correct ?',
      options: opts,
      correctIndex: 0, // always Vrai: facts from the lesson are true
      explanation: step.content,
      type: QuestionType.trueFalse,
    );
  }

  static void _pad(List<String> list, List<StepEntity> all, String correct) {
    final fallbacks = [
      'Aucune de ces réponses',
      'Toutes ces réponses',
      'Non applicable',
      'À déterminer',
    ];
    int fb = 0;
    while (list.length < 3) {
      final candidate = fb < fallbacks.length ? fallbacks[fb++] : '—';
      if (candidate != correct && !list.contains(candidate)) {
        list.add(candidate);
      }
    }
  }
}
