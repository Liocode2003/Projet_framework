import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:loniya_v2/core/errors/failures.dart';
import 'package:loniya_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:loniya_v2/features/auth/domain/usecases/verify_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late VerifyOtpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase  = VerifyOtpUseCase(mockRepo);
  });

  group('VerifyOtpUseCase', () {
    test('returns ValidationFailure when OTP is not 4 digits', () async {
      for (final bad in ['123', '12345', '', 'abcd']) {
        final result = await useCase.call('70000001', bad);
        expect(result.isLeft(), isTrue,
            reason: 'OTP "$bad" should be invalid');
        expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>(),
            reason: 'OTP "$bad" should yield ValidationFailure');
      }
      verifyNever(() => mockRepo.verifyOtp(any(), any()));
    });

    test('accepts exactly 4-digit OTP and calls repository', () async {
      when(() => mockRepo.verifyOtp('70000001', '1234'))
          .thenAnswer((_) async => const Right('user-uuid'));
      final result = await useCase.call('70000001', '1234');
      expect(result.isRight(), isTrue);
      verify(() => mockRepo.verifyOtp('70000001', '1234')).called(1);
    });

    test('returns InvalidOtpFailure when repository fails', () async {
      when(() => mockRepo.verifyOtp(any(), any()))
          .thenAnswer((_) async => Left(InvalidOtpFailure()));
      final result = await useCase.call('70000001', '0000');
      expect(result.fold((f) => f, (_) => null), isA<InvalidOtpFailure>());
    });
  });
}
