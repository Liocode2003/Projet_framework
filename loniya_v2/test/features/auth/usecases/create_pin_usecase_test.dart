import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:loniya_v2/core/errors/failures.dart';
import 'package:loniya_v2/features/auth/domain/entities/user_entity.dart';
import 'package:loniya_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:loniya_v2/features/auth/domain/usecases/create_pin_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late CreatePinUseCase useCase;

  final fakeUser = UserEntity(
    id: 'u1', phone: '70000001', role: 'student',
    pinHash: 'hash', createdAt: DateTime(2024), consentGiven: true,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase  = CreatePinUseCase(mockRepo);
    registerFallbackValue(fakeUser);
  });

  group('CreatePinUseCase', () {
    test('rejects non-numeric PIN', () async {
      final result = await useCase.call('u1', 'abcd');
      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('rejects PIN shorter than 4 digits', () async {
      final result = await useCase.call('u1', '123');
      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('rejects PIN longer than 4 digits', () async {
      final result = await useCase.call('u1', '12345');
      expect(result.isLeft(), isTrue);
    });

    test('calls repository and returns UserEntity on valid PIN', () async {
      when(() => mockRepo.createPin('u1', '1234'))
          .thenAnswer((_) async => Right(fakeUser));
      final result = await useCase.call('u1', '1234');
      expect(result.isRight(), isTrue);
      verify(() => mockRepo.createPin('u1', '1234')).called(1);
    });
  });
}
