import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/progress_model.dart';
import '../repositories/learning_repository.dart';

class SaveProgressUseCase {
  final LearningRepository _repo;
  const SaveProgressUseCase(this._repo);

  Future<Either<Failure, Unit>> call(ProgressModel progress) =>
      _repo.saveProgress(progress);
}
