import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_message_entity.dart';
import '../repositories/ai_tutor_repository.dart';

class AskQuestionUseCase {
  final AiTutorRepository _repo;
  const AskQuestionUseCase(this._repo);

  Future<Either<Failure, String>> call({
    required String userId,
    required String question,
    List<AiMessageEntity> history = const [],
    String stepId       = '',
    List<String> stepKeywords = const [],
    String subject      = '',
    String userRole     = 'student',
    String grade        = '',
    String stepTitle    = '',
  }) {
    if (question.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('La question ne peut pas être vide.')),
      );
    }
    return _repo.askQuestion(
      userId:       userId,
      question:     question,
      history:      history,
      stepId:       stepId,
      stepKeywords: stepKeywords,
      subject:      subject,
      userRole:     userRole,
      grade:        grade,
      stepTitle:    stepTitle,
    );
  }
}
