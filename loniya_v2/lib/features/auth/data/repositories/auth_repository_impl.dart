import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _local;
  const AuthRepositoryImpl(this._local);

  @override
  Future<Either<Failure, String>> sendOtp(String phone) async {
    try {
      final requestId = await _local.sendOtp(phone);
      return Right(requestId);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> verifyOtp(String phone, String otp) async {
    try {
      final userId = await _local.verifyOtp(phone, otp);
      return Right(userId);
    } on AuthException catch (e) {
      return Left(InvalidOtpFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRole(String userId, String role) async {
    try {
      await _local.saveRole(userId, role);
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
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createPin(
      String userId, String pin) async {
    try {
      final model = await _local.createPin(userId, pin);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on EncryptionException catch (_) {
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

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
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
      return const Right(unit);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  bool get hasActiveSession => _local.hasActiveSession;
}
