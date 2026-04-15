import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/encryption/aes_encryption_service.dart';

/// Handles the full download pipeline:
/// 1. Fetch raw bytes (mock: generate from JSON asset)
/// 2. GZIP compress
/// 3. AES-256 encrypt
/// 4. Write to app documents directory
/// 5. Return local file path
class ContentDownloadService {
  final AesEncryptionService _encryption;

  const ContentDownloadService(this._encryption);

  static const String _contentDir = 'loniya_contents';

  /// Downloads (mock) and stores a content item.
  /// [onProgress] is called with values 0.0 → 1.0.
  Future<String> downloadAndStore(
    String contentId,
    String contentJson, {
    void Function(double)? onProgress,
  }) async {
    try {
      final dir = await _getContentDirectory();
      final filePath = '${dir.path}/$contentId.lnc'; // loniya content

      onProgress?.call(0.1);

      // Step 1: Encode payload as UTF-8 bytes
      final rawBytes = utf8.encode(contentJson);
      onProgress?.call(0.3);

      // Step 2: GZIP compress
      final compressed = GZipEncoder().encode(rawBytes);
      if (compressed == null) throw const StorageException('Compression échouée.');
      onProgress?.call(0.5);

      // Step 3: AES-256 encrypt (base64 payload)
      final b64 = base64Encode(Uint8List.fromList(compressed));
      final encrypted = _encryption.encrypt(b64);
      onProgress?.call(0.8);

      // Step 4: Write to disk
      final file = File(filePath);
      await file.writeAsString(encrypted, flush: true);
      onProgress?.call(1.0);

      return filePath;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Échec du stockage : $e');
    }
  }

  /// Reads and decrypts a stored content file; returns JSON string.
  Future<String> readContent(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const StorageException('Fichier introuvable.');
      }
      final encrypted = await file.readAsString();
      final b64 = _encryption.decrypt(encrypted);
      final compressed = base64Decode(b64);
      final rawBytes = GZipDecoder().decodeBytes(compressed);
      return utf8.decode(rawBytes);
    } catch (e) {
      throw StorageException('Lecture échouée : $e');
    }
  }

  /// Deletes a stored content file from disk.
  Future<void> deleteContent(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  /// Returns total bytes used by all stored contents.
  Future<int> getTotalUsedBytes() async {
    final dir = await _getContentDirectory();
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<Directory> _getContentDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${appDir.path}/$_contentDir');
    if (!await contentDir.exists()) {
      await contentDir.create(recursive: true);
    }
    return contentDir;
  }
}
