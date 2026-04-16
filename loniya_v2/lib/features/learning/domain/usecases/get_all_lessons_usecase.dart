import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/learning_repository.dart';

class GetAllLessonsUseCase {
  final LearningRepository _repo;
  const GetAllLessonsUseCase(this._repo);

  Future<Either<Failure, List<LessonEntity>>> call() =>
      _repo.getAllLessons();
}
