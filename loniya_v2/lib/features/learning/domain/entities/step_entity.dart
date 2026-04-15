import 'package:equatable/equatable.dart';

enum StepType { read, question, exercise, validation }

class StepEntity extends Equatable {
  final int index;
  final String title;
  final String content;
  final StepType type;
  final String? imagePath;
  final String? expectedAnswer;
  final List<String> hints;
  final List<String> keywords;
  final int xpReward;

  const StepEntity({
    required this.index,
    required this.title,
    required this.content,
    required this.type,
    this.imagePath,
    this.expectedAnswer,
    required this.hints,
    required this.keywords,
    required this.xpReward,
  });

  bool get requiresAnswer =>
      type == StepType.question || type == StepType.exercise;
  bool get isReadOnly => type == StepType.read;
  bool get isFinal => type == StepType.validation;

  static StepType _typeFromString(String s) {
    switch (s) {
      case 'question':   return StepType.question;
      case 'exercise':   return StepType.exercise;
      case 'validation': return StepType.validation;
      default:           return StepType.read;
    }
  }

  factory StepEntity.fromJson(Map<String, dynamic> j) => StepEntity(
        index:          j['index'] as int? ?? 0,
        title:          j['title'] as String,
        content:        j['content'] as String,
        type:           _typeFromString(j['type'] as String? ?? 'read'),
        imagePath:      j['image_path'] as String?,
        expectedAnswer: j['expected_answer'] as String?,
        hints:          List<String>.from(j['hints'] as List? ?? []),
        keywords:       List<String>.from(j['keywords'] as List? ?? []),
        xpReward:       j['xp_reward'] as int? ?? 10,
      );

  @override
  List<Object?> get props => [
        index, title, content, type, imagePath,
        expectedAnswer, hints, keywords, xpReward,
      ];
}
