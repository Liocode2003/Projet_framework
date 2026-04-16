import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/ai_tutor_repository.dart';
import '../datasources/ai_tutor_local_datasource.dart';

class AiTutorRepositoryImpl implements AiTutorRepository {
  final AiTutorLocalDataSource _local;
  const AiTutorRepositoryImpl(this._local);

  @override
  Future<Either<Failure, String>> askQuestion({
    required String userId,
    required String question,
    String stepId = '',
    List<String> stepKeywords = const [],
    String subject = '',
  }) async {
    try {
      // 1. Check cache
      final cached = await _local.getCachedResponse(
        userId: userId,
        question: question,
        stepId: stepId,
      );
      if (cached != null) return Right(cached);

      // 2. Generate via engine + persist
      final response = await _local.generateAndCache(
        userId: userId,
        question: question,
        stepId: stepId,
        stepKeywords: stepKeywords,
        subject: subject,
      );
      return Right(response);
    } catch (e) {
      return Left(UnknownFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<void> pruneCache({int maxAgeHours = 72}) =>
      _local.pruneCache(maxAgeHours);
}
