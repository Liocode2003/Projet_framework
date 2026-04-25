import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../../core/services/encryption/aes_encryption_service.dart';
import '../../../../core/services/encryption/encryption_provider.dart';
import '../../../../core/services/storage/secure_key_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/save_role_usecase.dart';
import '../../domain/usecases/save_consent_usecase.dart';
import '../../domain/usecases/create_pin_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import 'auth_state.dart';

// ─── Dependency providers ──────────────────────────────────────────────────────
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(
    ref.read(databaseServiceProvider),
    ref.read(encryptionServiceProvider),
    ref.read(secureKeyServiceProvider),
  );
});

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((_) => AuthRemoteDataSource());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authLocalDataSourceProvider),
    ref.read(authRemoteDataSourceProvider),
  );
});

// ─── Use case providers ────────────────────────────────────────────────────────
final sendOtpUseCaseProvider = Provider(
  (ref) => SendOtpUseCase(ref.read(authRepositoryProvider)),
);
final verifyOtpUseCaseProvider = Provider(
  (ref) => VerifyOtpUseCase(ref.read(authRepositoryProvider)),
);
final saveRoleUseCaseProvider = Provider(
  (ref) => SaveRoleUseCase(ref.read(authRepositoryProvider)),
);
final saveConsentUseCaseProvider = Provider(
  (ref) => SaveConsentUseCase(ref.read(authRepositoryProvider)),
);
final createPinUseCaseProvider = Provider(
  (ref) => CreatePinUseCase(ref.read(authRepositoryProvider)),
);
final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);
final getCurrentUserUseCaseProvider = Provider(
  (ref) => GetCurrentUserUseCase(ref.read(authRepositoryProvider)),
);

// ─── Main auth notifier ────────────────────────────────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _checkSession();
  }

  // ─── Session check on startup ──────────────────────────────────────────
  Future<void> _checkSession() async {
    final repo = _ref.read(authRepositoryProvider);
    if (!repo.hasActiveSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    final result = await _ref.read(getCurrentUserUseCaseProvider).call();
    result.fold(
      (_) => state = state.copyWith(status: AuthStatus.unauthenticated),
      (user) {
        if (user == null) {
          state = state.copyWith(status: AuthStatus.unauthenticated);
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            userId: user.id,
            role: user.role,
          );
        }
      },
    );
  }

  // ─── Step 1: Send OTP ─────────────────────────────────────────────────
  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(sendOtpUseCaseProvider).call(phone);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.otpSent,
        phone: phone,
      ),
    );
  }

  // ─── Step 2: Verify OTP ───────────────────────────────────────────────
  Future<void> verifyOtp(String otp) async {
    if (state.phone == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result =
        await _ref.read(verifyOtpUseCaseProvider).call(state.phone!, otp);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (userId) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.otpVerified,
        userId: userId,
      ),
    );
  }

  // ─── Step 3: Save role ────────────────────────────────────────────────
  Future<void> saveRole(String role) async {
    if (state.userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result =
        await _ref.read(saveRoleUseCaseProvider).call(state.userId!, role);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.roleSelected,
        role: role,
      ),
    );
  }

  // ─── Step 4: Save consent ─────────────────────────────────────────────
  Future<void> saveConsent() async {
    if (state.userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result =
        await _ref.read(saveConsentUseCaseProvider).call(state.userId!);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.consentGiven,
      ),
    );
  }

  // ─── Step 5: Create PIN (completes auth) ──────────────────────────────
  Future<void> createPin(String pin) async {
    if (state.userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result =
        await _ref.read(createPinUseCaseProvider).call(state.userId!, pin);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  // ─── Step 5b: Save profile (name + grade/subject) ────────────────────
  Future<void> saveProfile(String name, String? gradeLevel) async {
    if (state.userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _ref
        .read(authLocalDataSourceProvider)
        .saveProfile(state.userId!, name, gradeLevel);
    final result = await _ref.read(getCurrentUserUseCaseProvider).call();
    result.fold(
      (_) => state = state.copyWith(isLoading: false),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
      ),
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _ref.read(logoutUseCaseProvider).call();
    await _ref.read(databaseServiceProvider).clearAll();
    state = const AuthState.initial().copyWith(
      status: AuthStatus.unauthenticated,
    );
  }

  // ─── Clear error ──────────────────────────────────────────────────────
  void clearError() => state = state.copyWith(errorMessage: null);
}

// ─── Convenience providers ────────────────────────────────────────────────────
final currentUserProvider = Provider((ref) {
  return ref.watch(authNotifierProvider).user;
});

final isAuthenticatedProvider = Provider((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final currentUserRoleProvider = Provider<String>((ref) {
  return ref.watch(authNotifierProvider).role ?? 'student';
});
