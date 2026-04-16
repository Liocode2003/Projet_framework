import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SaveRoleUseCase {
  final AuthRepository _repository;
  const SaveRoleUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String userId, String role) {
    const allowed = {'student', 'teacher', 'parent'};
    if (!allowed.contains(role)) {
      return Future.value(const Left(ValidationFailure('Rôle invalide.')));
    }
    return _repository.saveRole(userId, role);
  }
}
