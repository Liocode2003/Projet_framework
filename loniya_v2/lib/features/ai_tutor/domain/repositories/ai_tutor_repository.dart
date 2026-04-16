import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_message_entity.dart';

abstract class AiTutorRepository {
  /// Generates a Socratic hint for [question].
  /// Checks Hive cache first; falls back to rule-based engine.
  Future<Either<Failure, String>> askQuestion({
    required String userId,
    required String question,
    String stepId = '',
    List<String> stepKeywords = const [],
    String subject = '',
  });

  /// Clears expired cache entries.
  Future<void> pruneCache({int maxAgeHours = 72});
}
