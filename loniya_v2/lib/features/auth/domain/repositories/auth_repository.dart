import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract: all auth operations — implemented in data layer, consumed by use cases.
abstract class AuthRepository {
  /// Send OTP to phone (mock: always succeeds, code = 1234).
  Future<Either<Failure, String>> sendOtp(String phone);

  /// Verify OTP — returns userId on success.
  Future<Either<Failure, String>> verifyOtp(String phone, String otp);

  /// Save the role chosen by the user.
  Future<Either<Failure, Unit>> saveRole(String userId, String role);

  /// Record consent acceptance.
  Future<Either<Failure, Unit>> saveConsent(String userId);

  /// Create and hash the PIN; persist session.
  Future<Either<Failure, UserEntity>> createPin(String userId, String pin);

  /// Verify PIN for an existing session.
  Future<Either<Failure, bool>> verifyPin(String userId, String pin);

  /// Return the current authenticated user, or null.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Clear session and secure storage token.
  Future<Either<Failure, Unit>> logout();

  /// Check whether a valid (non-expired) session exists.
  bool get hasActiveSession;
}
