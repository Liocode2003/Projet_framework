import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketplace_repository.dart';

class DeleteContentUseCase {
  final MarketplaceRepository _repo;
  const DeleteContentUseCase(this._repo);
  Future<Either<Failure, Unit>> call(String id) => _repo.deleteContent(id);
}
