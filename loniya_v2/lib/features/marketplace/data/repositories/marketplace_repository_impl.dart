import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_local_datasource.dart';
import '../models/marketplace_item_model.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceLocalDataSource _local;
  const MarketplaceRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<ContentEntity>>> getAllContents() async {
    try {
      final models = await _local.getAllItems();
      return Right(models.map(_toEntity).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ContentEntity>>> filterContents({
    String? subject, String? gradeLevel, String? type, String? query,
  }) async {
    try {
      final models = await _local.filterItems(
        subject: subject, gradeLevel: gradeLevel, type: type, query: query,
      );
      return Right(models.map(_toEntity).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ContentEntity>>> getDownloadedContents() async {
    try {
      final models = await _local.getDownloadedItems();
      return Right(models.map(_toEntity).toList());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, ContentEntity>> getContentById(String id) async {
    try {
      final model = _local.getItemById(id);
      if (model == null) return const Left(ContentNotFoundFailure());
      return Right(_toEntity(model));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ContentEntity>> downloadContent(
    String id, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final model = await _local.downloadItem(id, onProgress: onProgress);
      return Right(_toEntity(model));
    } on CacheException catch (e) {
      return Left(DownloadFailure(e.message));
    } on StorageException catch (e) {
      return Left(DownloadFailure(e.message));
    } catch (_) {
      return const Left(DownloadFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteContent(String id) async {
    try {
      await _local.deleteItem(id);
      return const Right(unit);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  ContentEntity _toEntity(MarketplaceItemModel m) => ContentEntity(
        id: m.id, title: m.title, subject: m.subject,
        gradeLevel: m.gradeLevel, type: m.type, description: m.description,
        thumbnailPath: m.thumbnailPath, fileSizeBytes: m.fileSizeBytes,
        isDownloaded: m.isDownloaded, localPath: m.localPath,
        createdAt: m.createdAt, authorId: m.authorId, tags: m.tags,
        downloadCount: m.downloadCount, rating: m.rating,
        isEncrypted: m.isEncrypted,
      );
}
