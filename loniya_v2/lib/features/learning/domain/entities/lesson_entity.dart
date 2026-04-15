import 'package:equatable/equatable.dart';
import 'step_entity.dart';

class LessonEntity extends Equatable {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final String situation;
  final List<StepEntity> steps;
  final String contentItemId;
  final int estimatedMinutes;
  final List<String> competencies;
  final List<String> tags;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.situation,
    required this.steps,
    required this.contentItemId,
    required this.estimatedMinutes,
    required this.competencies,
    required this.tags,
  });

  int get totalSteps => steps.length;
  int get totalXp => steps.fold(0, (sum, s) => sum + s.xpReward);

  String get formattedDuration {
    if (estimatedMinutes < 60) return '$estimatedMinutes min';
    final h = estimatedMinutes ~/ 60;
    final m = estimatedMinutes % 60;
    return m > 0 ? '$h h $m min' : '${h}h';
  }

  @override
  List<Object?> get props => [
        id, title, subject, gradeLevel, situation,
        steps, contentItemId, estimatedMinutes, competencies, tags,
      ];
}
