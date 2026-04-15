import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SaveConsentUseCase {
  final AuthRepository _repository;
  const SaveConsentUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String userId) =>
      _repository.saveConsent(userId);
}
