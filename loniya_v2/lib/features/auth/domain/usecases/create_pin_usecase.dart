import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CreatePinUseCase {
  final AuthRepository _repository;
  const CreatePinUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(String userId, String pin) {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return Future.value(
        const Left(ValidationFailure('Le PIN doit être 4 chiffres.')),
      );
    }
    return _repository.createPin(userId, pin);
  }
}
