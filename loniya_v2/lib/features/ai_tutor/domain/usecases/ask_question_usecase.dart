import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ai_tutor_repository.dart';

class AskQuestionUseCase {
  final AiTutorRepository _repo;
  const AskQuestionUseCase(this._repo);

  Future<Either<Failure, String>> call({
    required String userId,
    required String question,
    String stepId = '',
    List<String> stepKeywords = const [],
    String subject = '',
  }) {
    if (question.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('La question ne peut pas être vide.')),
      );
    }
    return _repo.askQuestion(
      userId: userId,
      question: question,
      stepId: stepId,
      stepKeywords: stepKeywords,
      subject: subject,
    );
  }
}
