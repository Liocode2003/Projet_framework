import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Hybrid repository:
/// - Uses Supabase (real SMS OTP + cloud sync) when [SupabaseService.isAvailable]
/// - Falls back to local mock auth otherwise (dev / offline / unconfigured)
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource  _local;
  final AuthRemoteDataSource _remote;

  const AuthRepositoryImpl(this._local, this._remote);

  bool get _useRemote => SupabaseService.isAvailable;

  // ── OTP ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> sendOtp(String phone) async {
    if (_useRemote) {
      try {
        await _remote.sendOtp(phone);
        return const Right('otp_sent');
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (_) {
        return const Left(ServerFailure('Envoi SMS échoué.'));
      }
    }
    // Local mock
    try {
      final id = await _local.sendOtp(phone);
      return Right(id);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> verifyOtp(String phone, String otp) async {
    if (_useRemote) {
      try {
        final userId = await _remote.verifyOtp(phone, otp);
        // Mirror the Supabase user into local Hive for offline access
        await _local.upsertRemoteUser(userId, phone);
        return Right(userId);
      } on AuthException catch (e) {
        return Left(InvalidOtpFailure());
      } catch (_) {
        return const Left(ServerFailure('Vérification OTP échouée.'));
      }
    }
    // Local mock
    try {
      final userId = await _local.verifyOtp(phone, otp);
      return Right(userId);
    } on AuthException {
      return Left(InvalidOtpFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // ── Role / Consent / Profile ─────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> saveRole(String userId, String role) async {
    try {
      await _local.saveRole(userId, role);
      if (_useRemote) _remote.saveRole(userId, role).ignore();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveConsent(String userId) async {
    try {
      await _local.saveConsent(userId);
      if (_useRemote) _remote.saveConsent(userId).ignore();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // ── PIN (always local — offline unlock) ──────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> createPin(
      String userId, String pin) async {
    try {
      final model = await _local.createPin(userId, pin);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on EncryptionException {
      return const Left(EncryptionFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String userId, String pin) async {
    try {
      final ok = await _local.verifyPin(userId, pin);
      return Right(ok);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // Supabase session takes priority; sync profile if needed
      if (_useRemote && SupabaseService.currentUserId != null) {
        final remote = await _remote
            .fetchProfile(SupabaseService.currentUserId!)
            .catchError((_) => null);
        if (remote != null) {
          await _local.upsertRemoteUser(remote.id, remote.phone,
              name: remote.name, role: remote.role,
              gradeLevel: remote.gradeLevel);
        }
      }
      final model = _local.getCurrentUser();
      return Right(model?.toEntity());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _local.logout();
      if (_useRemote) await _remote.logout();
      return const Right(unit);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  bool get hasActiveSession =>
      _useRemote ? _remote.hasActiveSession : _local.hasActiveSession;
}
