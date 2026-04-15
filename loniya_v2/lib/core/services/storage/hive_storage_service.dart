import 'package:hive_flutter/hive_flutter.dart';

import '../encryption/aes_encryption_service.dart';
import '../../constants/hive_boxes.dart';
import 'storage_service.dart';

/// Hive-backed implementation of StorageService.
/// Encrypted boxes use the AES-256 key via HiveCipher.
/// Full encryption wiring is completed in Phase 3.
class HiveStorageService implements StorageService {
  final AesEncryptionService _encryption;

  HiveStorageService(this._encryption);

  // ─── Static initializer — called from main.dart ─────────────────────
  static Future<void> openBoxes(AesEncryptionService encryption) async {
    final hiveKey = encryption.hiveEncryptionKey;
    final cipher = HiveAesCipher(hiveKey);

    // Open encrypted boxes
    await Future.wait([
      Hive.openBox(HiveBoxes.users, encryptionCipher: cipher),
      Hive.openBox(HiveBoxes.sessions, encryptionCipher: cipher),
      Hive.openBox(HiveBoxes.contents, encryptionCipher: cipher),
      Hive.openBox(HiveBoxes.progress, encryptionCipher: cipher),
    ]);

    // Open non-encrypted boxes
    await Future.wait([
      Hive.openBox(HiveBoxes.gamification),
      Hive.openBox(HiveBoxes.syncQueue),
      Hive.openBox(HiveBoxes.aiCache),
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.orientation),
      Hive.openBox(HiveBoxes.classroom),
      Hive.openBox(HiveBoxes.marketplace),
    ]);
  }

  // ─── StorageService implementation ──────────────────────────────────
  @override
  Future<void> put(String box, String key, dynamic value) async {
    await Hive.box(box).put(key, value);
  }

  @override
  dynamic get(String box, String key, {dynamic defaultValue}) {
    return Hive.box(box).get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> delete(String box, String key) async {
    await Hive.box(box).delete(key);
  }

  @override
  Map<dynamic, dynamic> getAll(String box) {
    return Hive.box(box).toMap();
  }

  @override
  Future<void> clear(String box) async {
    await Hive.box(box).clear();
  }
}
