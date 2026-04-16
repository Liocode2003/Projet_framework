import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';
import '../repositories/marketplace_repository.dart';

class GetDownloadedContentsUseCase {
  final MarketplaceRepository _repo;
  const GetDownloadedContentsUseCase(this._repo);
  Future<Either<Failure, List<ContentEntity>>> call() =>
      _repo.getDownloadedContents();
}
