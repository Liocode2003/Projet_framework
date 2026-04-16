import 'package:equatable/equatable.dart';

enum MessageRole { user, tutor }

class AiMessageEntity extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool fromCache;

  const AiMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.fromCache = false,
  });

  bool get isUser  => role == MessageRole.user;
  bool get isTutor => role == MessageRole.tutor;

  @override
  List<Object?> get props => [id, role, content, createdAt, fromCache];
}

/// Optional context injected when user asks from within a lesson step.
class AiContext extends Equatable {
  final String lessonId;
  final String stepId;
  final String stepTitle;
  final String subject;
  final List<String> keywords;

  const AiContext({
    required this.lessonId,
    required this.stepId,
    required this.stepTitle,
    required this.subject,
    required this.keywords,
  });

  @override
  List<Object?> get props =>
      [lessonId, stepId, stepTitle, subject, keywords];
}
