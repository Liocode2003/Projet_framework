import 'package:flutter_test/flutter_test.dart';
import 'package:loniya_v2/features/auth/presentation/providers/auth_state.dart';
import 'package:loniya_v2/features/auth/domain/entities/user_entity.dart';

void main() {
  group('AuthState', () {
    test('initial state is not authenticated', () {
      const state = AuthState.initial();
      expect(state.status, AuthStatus.initial);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('isAuthenticated only when status == authenticated', () {
      for (final s in AuthStatus.values) {
        final state = AuthState(status: s);
        expect(state.isAuthenticated, s == AuthStatus.authenticated);
      }
    });

    test('copyWith preserves unchanged fields', () {
      const original = AuthState(status: AuthStatus.unauthenticated, phone: '70001');
      final updated  = original.copyWith(status: AuthStatus.otpSent);

      expect(updated.status, AuthStatus.otpSent);
      expect(updated.phone, '70001');       // preserved
      expect(updated.isLoading, isFalse);   // preserved
    });

    test('copyWith resets errorMessage to null', () {
      final withError = AuthState(
          status: AuthStatus.error, errorMessage: 'fail');
      final cleared = withError.copyWith(status: AuthStatus.unauthenticated);
      // errorMessage is always explicitly null in copyWith
      expect(cleared.errorMessage, isNull);
    });

    test('props include all fields for equality', () {
      final user = UserEntity(
        id: 'u1', phone: '70001', role: 'student',
        pinHash: '', createdAt: DateTime(2024), consentGiven: false,
      );
      final a = AuthState(status: AuthStatus.authenticated, user: user);
      final b = AuthState(status: AuthStatus.authenticated, user: user);
      expect(a, equals(b));
    });
  });
}
