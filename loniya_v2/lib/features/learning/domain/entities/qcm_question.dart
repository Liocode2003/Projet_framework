enum QuestionType { multipleChoice, trueFalse }

class QcmQuestion {
  final String id;
  final String question;
  final List<String> options;   // always 4 options
  final int correctIndex;
  final String explanation;     // shown after answering
  final QuestionType type;

  const QcmQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.type = QuestionType.multipleChoice,
  });

  String get correctAnswer => options[correctIndex];
}
