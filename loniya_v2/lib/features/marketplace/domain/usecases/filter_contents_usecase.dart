import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';
import '../repositories/marketplace_repository.dart';

class FilterContentsUseCase {
  final MarketplaceRepository _repo;
  const FilterContentsUseCase(this._repo);

  Future<Either<Failure, List<ContentEntity>>> call({
    String? subject,
    String? gradeLevel,
    String? type,
    String? query,
  }) =>
      _repo.filterContents(
        subject: subject,
        gradeLevel: gradeLevel,
        type: type,
        query: query,
      );
}
