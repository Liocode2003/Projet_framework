import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_message_entity.dart';

abstract class AiTutorRepository {
  Future<Either<Failure, String>> askQuestion({
    required String userId,
    required String question,
    List<AiMessageEntity> history,
    String stepId,
    List<String> stepKeywords,
    String subject,
    String userRole,
    String grade,
    String stepTitle,
  });

  Future<void> pruneCache({int maxAgeHours = 72});
}
