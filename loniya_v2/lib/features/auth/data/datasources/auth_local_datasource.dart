import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/services/encryption/aes_encryption_service.dart';
import '../../../../core/services/storage/secure_key_service.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';

/// Handles all local auth operations against Hive + SecureStorage.
class AuthLocalDataSource {
  final DatabaseService _db;
  final AesEncryptionService _encryption;
  final SecureKeyService _secureKeys;

  const AuthLocalDataSource(this._db, this._encryption, this._secureKeys);

  // ─── OTP ─────────────────────────────────────────────────────────────
  /// Mock: stores pending phone, returns requestId.
  Future<String> sendOtp(String phone) async {
    // In production: call SMS gateway API here.
    // Offline mock: persist phone so OTP screen can reference it.
    return 'otp_req_${phone}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Mock OTP verification. Code = AppConstants.mockOtpCode ("1234").
  /// Returns the userId (creates user if first login).
  Future<String> verifyOtp(String phone, String otp) async {
    if (otp != AppConstants.mockOtpCode) {
      throw const AuthException('Code OTP incorrect.');
    }

    // Check if user already exists
    final existing = _findUserByPhone(phone);
    if (existing != null) return existing.id;

    // Create new user skeleton
    final userId = const Uuid().v4();
    final deviceId = await _secureKeys.getOrCreateDeviceId();

    final user = UserModel(
      id: userId,
      phone: phone,
      role: 'student',        // default; updated in SaveRole step
      pinHash: '',            // empty until PIN step
      createdAt: DateTime.now().toIso8601String(),
      consentGiven: false,
      deviceId: deviceId,
    );

    await _db.saveUser(user);
    return userId;
  }

  // ─── ROLE ─────────────────────────────────────────────────────────────
  Future<void> saveRole(String userId, String role) async {
    final user = _requireUser(userId);
    await _db.saveUser(user.copyWith());
    // Store role in a lightweight pending-session map in Hive settings box
    await _db.saveSettings(
      _db.getSettings(userId).copyWith(),
    );
    // Persist role on the user model directly
    final updated = UserModel(
      id: user.id, phone: user.phone, role: role,
      name: user.name, avatarPath: user.avatarPath,
      pinHash: user.pinHash, createdAt: user.createdAt,
      schoolName: user.schoolName, gradeLevel: user.gradeLevel,
      consentGiven: user.consentGiven, deviceId: user.deviceId,
    );
    await _db.saveUser(updated);
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────
  Future<void> saveProfile(
      String userId, String name, String? gradeLevel) async {
    final user = _requireUser(userId);
    final updated = UserModel(
      id: user.id, phone: user.phone, role: user.role,
      name: name, avatarPath: user.avatarPath,
      pinHash: user.pinHash, createdAt: user.createdAt,
      schoolName: user.schoolName, gradeLevel: gradeLevel,
      consentGiven: user.consentGiven, deviceId: user.deviceId,
    );
    await _db.saveUser(updated);
  }

  // ─── CONSENT ──────────────────────────────────────────────────────────
  Future<void> saveConsent(String userId) async {
    final user = _requireUser(userId);
    final updated = UserModel(
      id: user.id, phone: user.phone, role: user.role,
      name: user.name, avatarPath: user.avatarPath,
      pinHash: user.pinHash, createdAt: user.createdAt,
      schoolName: user.schoolName, gradeLevel: user.gradeLevel,
      consentGiven: true, deviceId: user.deviceId,
    );
    await _db.saveUser(updated);
  }

  // ─── PIN ──────────────────────────────────────────────────────────────
  Future<UserModel> createPin(String userId, String pin) async {
    final user = _requireUser(userId);
    final pinHash = _encryption.hashPin(pin);
    final deviceId = user.deviceId ?? await _secureKeys.getOrCreateDeviceId();

    // Update user with hashed PIN
    final updated = UserModel(
      id: user.id, phone: user.phone, role: user.role,
      name: user.name, avatarPath: user.avatarPath,
      pinHash: pinHash, createdAt: user.createdAt,
      schoolName: user.schoolName, gradeLevel: user.gradeLevel,
      consentGiven: user.consentGiven, deviceId: deviceId,
    );
    await _db.saveUser(updated);

    // Create session
    final session = SessionModel.create(
      userId: userId,
      role: updated.role,
      deviceId: deviceId,
      expiryDays: AppConstants.sessionExpiryDays,
    ).copyWith(pinSet: true);

    await _db.saveSession(session);
    await _secureKeys.saveSessionToken(
      _encryption.encrypt('${userId}:${session.createdAt}'),
    );

    return updated;
  }

  Future<bool> verifyPin(String userId, String pin) async {
    final user = _requireUser(userId);
    return _encryption.verifyPin(pin, user.pinHash);
  }

  // ─── SESSION ──────────────────────────────────────────────────────────
  UserModel? getCurrentUser() {
    final session = _db.getCurrentSession();
    if (session == null || session.isExpired) return null;
    return _db.getUser(session.userId);
  }

  Future<void> logout() async {
    await _db.clearSession();
    await _secureKeys.clearSession();
  }

  bool get hasActiveSession => _db.hasActiveSession;

  // ─── Helpers ──────────────────────────────────────────────────────────
  UserModel? _findUserByPhone(String phone) {
    return _db.getAllUsers().where((u) => u.phone == phone).firstOrNull;
  }

  UserModel _requireUser(String userId) {
    final user = _db.getUser(userId);
    if (user == null) throw AuthException('Utilisateur $userId introuvable.');
    return user;
  }
}
