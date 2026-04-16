import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';
import '../repositories/marketplace_repository.dart';

class GetAllContentsUseCase {
  final MarketplaceRepository _repo;
  const GetAllContentsUseCase(this._repo);
  Future<Either<Failure, List<ContentEntity>>> call() => _repo.getAllContents();
}
