import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/step_entity.dart';
import '../../domain/repositories/learning_repository.dart';
import '../datasources/learning_local_datasource.dart';
import '../models/lesson_model.dart';
import '../models/step_model.dart';
import '../models/progress_model.dart';

class LearningRepositoryImpl implements LearningRepository {
  final LearningLocalDataSource _local;
  const LearningRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<LessonEntity>>> getAllLessons() async {
    try {
      final models = await _local.getAllLessons();
      return Right(models.map(_toEntity).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<LessonEntity>>> getAvailableLessons() async {
    try {
      final models = await _local.getAvailableLessons();
      return Right(models.map(_toEntity).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    try {
      final model = await _local.getLessonById(id);
      if (model == null) {
        return const Left(ContentNotFoundFailure('Leçon introuvable.'));
      }
      return Right(_toEntity(model));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ProgressModel?>> getProgress(
      String userId, String lessonId) async {
    try {
      return Right(_local.getProgress(userId, lessonId));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveProgress(ProgressModel progress) async {
    try {
      await _local.saveProgress(progress);
      return const Right(unit);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  // ─── Mapping helpers ──────────────────────────────────────────────────────
  LessonEntity _toEntity(LessonModel m) => LessonEntity(
        id:               m.id,
        title:            m.title,
        subject:          m.subject,
        gradeLevel:       m.gradeLevel,
        situation:        m.situation,
        steps:            m.steps.map(_stepToEntity).toList(),
        contentItemId:    m.contentItemId,
        estimatedMinutes: m.estimatedMinutes,
        competencies:     m.competencies,
        tags:             m.tags,
      );

  StepEntity _stepToEntity(StepModel s) => StepEntity(
        index:          s.index,
        title:          s.title,
        content:        s.content,
        type:           _stepType(s.type),
        imagePath:      s.imagePath,
        expectedAnswer: s.expectedAnswer,
        hints:          s.hints,
        keywords:       s.keywords,
        xpReward:       s.xpReward,
      );

  StepType _stepType(String raw) {
    switch (raw) {
      case 'question':   return StepType.question;
      case 'exercise':   return StepType.exercise;
      case 'validation': return StepType.validation;
      default:           return StepType.read;
    }
  }
}
