import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:loniya_v2/core/errors/failures.dart';
import 'package:loniya_v2/features/auth/domain/entities/user_entity.dart';
import 'package:loniya_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:loniya_v2/features/auth/presentation/providers/auth_notifier.dart';
import 'package:loniya_v2/features/auth/presentation/providers/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Builds a ProviderContainer that replaces the real auth repo with [mock].
/// hasActiveSession is stubbed to false so the constructor path is trivial.
ProviderContainer _makeContainer(MockAuthRepository mock) {
  when(() => mock.hasActiveSession).thenReturn(false);
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mock),
    ],
  );
}

void main() {
  late MockAuthRepository mockRepo;

  final fakeUser = UserEntity(
    id: 'u1', phone: '70000001', role: 'student',
    pinHash: 'h', createdAt: DateTime(2024), consentGiven: true,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    registerFallbackValue(fakeUser);
  });

  group('AuthNotifier – sendOtp', () {
    test('sets status to otpSent on success', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Right('req_id'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.sendOtp('70000001');

      final state = container.read(authNotifierProvider);
      expect(state.status,    AuthStatus.otpSent);
      expect(state.phone,     '70000001');
      expect(state.isLoading, isFalse);
    });

    test('sets status to error on failure', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Left(ServerFailure('SMS down')));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).sendOtp('70000001');

      final state = container.read(authNotifierProvider);
      expect(state.status,       AuthStatus.error);
      expect(state.errorMessage, 'SMS down');
      expect(state.isLoading,    isFalse);
    });
  });

  group('AuthNotifier – verifyOtp', () {
    test('sets status to otpVerified on success', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Right('req'));
      when(() => mockRepo.verifyOtp(any(), any()))
          .thenAnswer((_) async => const Right('user-uuid'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.sendOtp('70000001');
      await notifier.verifyOtp('1234');

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.otpVerified);
      expect(state.userId, 'user-uuid');
    });

    test('sets error on invalid OTP from repository', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Right('req'));
      when(() => mockRepo.verifyOtp(any(), any()))
          .thenAnswer((_) async => Left(InvalidOtpFailure()));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.sendOtp('70000001');
      await notifier.verifyOtp('0000');

      final state = container.read(authNotifierProvider);
      expect(state.status,       AuthStatus.error);
      expect(state.errorMessage, isNotNull);
    });

    test('verifyOtp is a no-op if phone is not set', () async {
      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).verifyOtp('1234');

      verifyNever(() => mockRepo.verifyOtp(any(), any()));
    });
  });

  group('AuthNotifier – saveRole', () {
    test('sets status to roleSelected on success', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Right('req'));
      when(() => mockRepo.verifyOtp(any(), any()))
          .thenAnswer((_) async => const Right('u1'));
      when(() => mockRepo.saveRole(any(), any()))
          .thenAnswer((_) async => const Right(unit));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.sendOtp('70000001');
      await notifier.verifyOtp('1234');
      await notifier.saveRole('student');

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.roleSelected);
      expect(state.role,   'student');
    });
  });

  group('AuthNotifier – createPin', () {
    test('sets status to authenticated on valid PIN', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Right('req'));
      when(() => mockRepo.verifyOtp(any(), any()))
          .thenAnswer((_) async => const Right('u1'));
      when(() => mockRepo.createPin(any(), any()))
          .thenAnswer((_) async => Right(fakeUser));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.sendOtp('70000001');
      await notifier.verifyOtp('1234');
      await notifier.createPin('1234');

      final state = container.read(authNotifierProvider);
      expect(state.status,        AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user,          fakeUser);
    });
  });

  group('AuthNotifier – clearError', () {
    test('clears errorMessage', () async {
      when(() => mockRepo.sendOtp(any()))
          .thenAnswer((_) async => const Left(ServerFailure('err')));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.sendOtp('70000001');
      expect(container.read(authNotifierProvider).errorMessage, isNotNull);

      notifier.clearError();
      expect(container.read(authNotifierProvider).errorMessage, isNull);
    });
  });
}
