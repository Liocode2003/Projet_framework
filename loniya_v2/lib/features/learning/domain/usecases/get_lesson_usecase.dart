import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/learning_repository.dart';

class GetLessonUseCase {
  final LearningRepository _repo;
  const GetLessonUseCase(this._repo);

  /// [id] may be the lesson's own id OR the contentItemId.
  Future<Either<Failure, LessonEntity>> call(String id) =>
      _repo.getLessonById(id);
}
