import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../../data/models/progress_model.dart';

abstract class LearningRepository {
  /// Returns ALL lessons from JSON assets.
  Future<Either<Failure, List<LessonEntity>>> getAllLessons();

  /// Returns lessons whose content item is marked as downloaded in Hive.
  Future<Either<Failure, List<LessonEntity>>> getAvailableLessons();

  /// Finds a lesson by its own [id] OR by [contentItemId] (FK to marketplace).
  Future<Either<Failure, LessonEntity>> getLessonById(String id);

  /// Returns saved progress for [userId] + [lessonId], or null if not started.
  Future<Either<Failure, ProgressModel?>> getProgress(
      String userId, String lessonId);

  /// Persists [progress] to Hive.
  Future<Either<Failure, Unit>> saveProgress(ProgressModel progress);
}
