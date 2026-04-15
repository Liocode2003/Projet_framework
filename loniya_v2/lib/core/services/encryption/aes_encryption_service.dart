import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'encryption_service.dart';

/// AES-256-CBC encryption service.
/// Key is generated once and stored in Android Keystore via flutter_secure_storage.
/// Fully implemented here — Phase 3 will wire it into all Hive boxes.
class AesEncryptionService implements EncryptionService {
  static const String _keyAlias = 'loniya_aes_master_key';
  static const String _saltAlias = 'loniya_pin_salt';

  final FlutterSecureStorage _secureStorage;

  late enc.Key _aesKey;
  late List<int> _hiveKey;
  bool _initialized = false;

  AesEncryptionService()
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<void> init() async {
    if (_initialized) return;

    // 1. Try to load existing key from secure storage
    String? storedKey = await _secureStorage.read(key: _keyAlias);

    if (storedKey == null) {
      // 2. Generate a new AES-256 key (32 bytes)
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      storedKey = base64Encode(keyBytes);
      await _secureStorage.write(key: _keyAlias, value: storedKey);
    }

    final keyBytes = base64Decode(storedKey);
    _aesKey = enc.Key(Uint8List.fromList(keyBytes));
    _hiveKey = keyBytes;
    _initialized = true;
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError('AesEncryptionService not initialized. Call init() first.');
    }
  }

  @override
  String encrypt(String plaintext) {
    _assertInitialized();
    // Random IV per encryption call
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_aesKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Prepend IV to ciphertext: base64(iv) + ":" + base64(ciphertext)
    return '${iv.base64}:${encrypted.base64}';
  }

  @override
  String decrypt(String ciphertext) {
    _assertInitialized();
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) throw const FormatException('Invalid ciphertext format');
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_aesKey, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  @override
  String hashPin(String pin) {
    // PBKDF2-like: SHA-256(salt + pin + salt)
    final salt = _getSalt();
    final bytes = utf8.encode('$salt$pin$salt');
    return sha256.convert(bytes).toString();
  }

  @override
  bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }

  /// The Hive encryption key (32 bytes) used for encrypted boxes.
  @override
  List<int> get hiveEncryptionKey {
    _assertInitialized();
    return List.unmodifiable(_hiveKey);
  }

  String _getSalt() {
    // Deterministic per-device salt derived from the master key
    return sha256
        .convert(utf8.encode('loniya_salt_${_aesKey.base64}'))
        .toString()
        .substring(0, 16);
  }
}
