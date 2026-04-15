import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  Future<Either<Failure, String>> call(String phone, String otp) {
    if (otp.length != 4) {
      return Future.value(const Left(ValidationFailure('Code OTP incomplet.')));
    }
    return _repository.verifyOtp(phone, otp);
  }
}
