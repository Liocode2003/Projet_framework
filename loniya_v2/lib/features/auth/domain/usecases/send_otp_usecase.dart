import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository _repository;
  const SendOtpUseCase(this._repository);

  Future<Either<Failure, String>> call(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 8) {
      return Future.value(const Left(ValidationFailure('Numéro invalide.')));
    }
    return _repository.sendOtp(cleaned);
  }
}
