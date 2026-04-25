import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:loniya_v2/core/errors/failures.dart';
import 'package:loniya_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:loniya_v2/features/auth/domain/usecases/send_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SendOtpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase  = SendOtpUseCase(mockRepo);
  });

  group('SendOtpUseCase', () {
    test('returns ValidationFailure when phone has fewer than 8 digits', () async {
      final result = await useCase.call('123');
      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      verifyNever(() => mockRepo.sendOtp(any()));
    });

    test('strips non-digit characters before calling repository', () async {
      when(() => mockRepo.sendOtp('70123456'))
          .thenAnswer((_) async => const Right('req'));
      await useCase.call('+226 70-123-456');
      verify(() => mockRepo.sendOtp('22670123456')).called(1);
    });

    test('propagates Right from repository on success', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Right('req_id'));
      final result = await useCase.call('70123456');
      expect(result.isRight(), isTrue);
    });

    test('propagates Left from repository on failure', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Left(ServerFailure('SMS error')));
      final result = await useCase.call('70123456');
      expect(result.isLeft(), isTrue);
    });
  });
}
