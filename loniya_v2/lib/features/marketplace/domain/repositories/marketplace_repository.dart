import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';

abstract class MarketplaceRepository {
  Future<Either<Failure, List<ContentEntity>>> getAllContents();
  Future<Either<Failure, List<ContentEntity>>> filterContents({
    String? subject, String? gradeLevel, String? type, String? query,
  });
  Future<Either<Failure, List<ContentEntity>>> getDownloadedContents();
  Future<Either<Failure, ContentEntity>> getContentById(String id);
  /// Download: compress → encrypt → save to app dir → update Hive record.
  /// Emits progress via [onProgress] callback (0.0 – 1.0).
  Future<Either<Failure, ContentEntity>> downloadContent(
    String id, {
    void Function(double progress)? onProgress,
  });
  Future<Either<Failure, Unit>> deleteContent(String id);
}
