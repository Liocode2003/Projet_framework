import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';
import '../repositories/marketplace_repository.dart';

class DownloadContentUseCase {
  final MarketplaceRepository _repo;
  const DownloadContentUseCase(this._repo);

  Future<Either<Failure, ContentEntity>> call(
    String id, {
    void Function(double progress)? onProgress,
  }) =>
      _repo.downloadContent(id, onProgress: onProgress);
}
