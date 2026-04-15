import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/progress_model.dart';
import '../repositories/learning_repository.dart';

class GetProgressUseCase {
  final LearningRepository _repo;
  const GetProgressUseCase(this._repo);

  Future<Either<Failure, ProgressModel?>> call(
          String userId, String lessonId) =>
      _repo.getProgress(userId, lessonId);
}
