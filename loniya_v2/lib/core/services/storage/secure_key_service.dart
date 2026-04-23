import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages all secure keys stored in Android Keystore.
/// Single source of truth for cryptographic material.
class SecureKeyService {
  static const String _masterKeyAlias    = 'loniya_aes_master_key';
  static const String _pinSaltAlias      = 'loniya_pin_salt';
  static const String _sessionTokenAlias = 'loniya_session_token';
  static const String _deviceIdAlias     = 'loniya_device_id';
  static const String _groqApiKeyAlias   = 'loniya_groq_api_key';

  final FlutterSecureStorage _storage;

  SecureKeyService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ─── Master AES Key ──────────────────────────────────────────────────
  Future<List<int>> getOrCreateMasterKey() async {
    String? stored = await _storage.read(key: _masterKeyAlias);
    if (stored == null) {
      final key = _generateRandomBytes(32);
      stored = base64Encode(key);
      await _storage.write(key: _masterKeyAlias, value: stored);
    }
    return base64Decode(stored);
  }

  // ─── PIN Salt ────────────────────────────────────────────────────────
  Future<String> getOrCreatePinSalt() async {
    String? salt = await _storage.read(key: _pinSaltAlias);
    if (salt == null) {
      salt = base64Encode(_generateRandomBytes(16));
      await _storage.write(key: _pinSaltAlias, value: salt);
    }
    return salt;
  }

  // ─── Session Token ───────────────────────────────────────────────────
  Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _sessionTokenAlias, value: token);
  }

  Future<String?> getSessionToken() async {
    return _storage.read(key: _sessionTokenAlias);
  }

  Future<void> deleteSessionToken() async {
    await _storage.delete(key: _sessionTokenAlias);
  }

  // ─── Device ID ───────────────────────────────────────────────────────
  /// Stable unique device identifier — generated once, never changes.
  Future<String> getOrCreateDeviceId() async {
    String? id = await _storage.read(key: _deviceIdAlias);
    if (id == null) {
      id = _generateDeviceId();
      await _storage.write(key: _deviceIdAlias, value: id);
    }
    return id;
  }

  // ─── Wipe all keys (logout) ──────────────────────────────────────────
  /// Deletes session token only. Master key is retained (data stays readable).
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionTokenAlias);
  }

  // ─── Groq API Key ────────────────────────────────────────────────────
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _groqApiKeyAlias, value: key.trim());
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: _groqApiKeyAlias);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _groqApiKeyAlias);
  }

  // ─── Full wipe ───────────────────────────────────────────────────────
  /// Full wipe — removes ALL keys. Use only on account deletion.
  Future<void> wipeAll() async {
    await _storage.deleteAll();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────
  List<int> _generateRandomBytes(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  String _generateDeviceId() {
    final bytes = _generateRandomBytes(16);
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

final secureKeyServiceProvider = Provider<SecureKeyService>((ref) {
  return SecureKeyService();
});
