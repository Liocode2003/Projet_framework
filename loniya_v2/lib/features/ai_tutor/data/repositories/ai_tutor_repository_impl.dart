import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/repositories/ai_tutor_repository.dart';
import '../datasources/ai_tutor_local_datasource.dart';
import '../services/ai_llm_service.dart';

class AiTutorRepositoryImpl implements AiTutorRepository {
  final AiTutorLocalDataSource _local;
  final AiLlmService _llm;
  final ConnectivityService _connectivity;

  const AiTutorRepositoryImpl(this._local, this._llm, this._connectivity);

  @override
  Future<Either<Failure, String>> askQuestion({
    required String userId,
    required String question,
    List<AiMessageEntity> history   = const [],
    String stepId                   = '',
    List<String> stepKeywords       = const [],
    String subject                  = '',
    String userRole                 = 'student',
    String grade                    = '',
    String stepTitle                = '',
  }) async {
    try {
      // 1. Always check local cache first (works offline + saves API quota)
      final cached = await _local.getCachedResponse(
        userId: userId, question: question, stepId: stepId);
      if (cached != null) return Right(cached);

      // 2. Try Groq LLM when connected
      if (_connectivity.isConnected) {
        final llmResult = await _llm.chat(
          question:     question,
          history:      history,
          userRole:     userRole,
          grade:        grade,
          subject:      subject,
          stepTitle:    stepTitle,
          stepKeywords: stepKeywords,
        );

        if (llmResult.isRight()) {
          final response = llmResult.getOrElse(() => '');
          // Cache the LLM response for offline reuse (72h)
          await _local.saveResponseToCache(
            userId: userId, question: question,
            stepId: stepId, response: response,
          );
          return Right(response);
        }

        // Auth failure = bad API key → surface error, don't fall through
        final failure = llmResult.fold((f) => f, (_) => null);
        if (failure is AuthFailure) return llmResult;
        // Other LLM errors (timeout, server) → fall through to local engine
      }

      // 3. Offline fallback — rule-based Socratic engine
      final response = await _local.generateAndCache(
        userId:       userId,
        question:     question,
        stepId:       stepId,
        stepKeywords: stepKeywords,
        subject:      subject,
      );
      return Right(response);
    } catch (e) {
      return Left(UnknownFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<void> pruneCache({int maxAgeHours = 72}) =>
      _local.pruneCache(maxAgeHours);
}
