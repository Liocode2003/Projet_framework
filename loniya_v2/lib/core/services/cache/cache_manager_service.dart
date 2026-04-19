import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/hive_boxes.dart';
import '../database/database_service.dart';

/// Manages runtime caches and storage hygiene.
///
/// Call [startup] once after Hive boxes open to:
///   1. Prune expired AI cache entries (TTL 72 h).
///   2. Remove done/failed sync actions (keeps queue lean).
///   3. Limit Flutter's image cache to 50 MB / 100 entries.
///
/// Call [storageReport] to get a breakdown of local storage usage.
class CacheManagerService {
  // 3× the base TTL — AI responses stay valid longer than the base 24h constant
  static const int _aiCacheTtlHours = AppConstants.aiCacheExpiryHours * 3;
  static const int _imageCacheMaxMb = 50;
  static const int _imageCacheMaxEntries = AppConstants.maxCachedImages * 2;

  static final _log = Logger(
    printer: PrettyPrinter(methodCount: 0, printTime: false),
  );

  final DatabaseService _db;

  const CacheManagerService(this._db);

  // ── Startup pruning ───────────────────────────────────────────────────────

  Future<void> startup() async {
    try {
      await Future.wait([
        _pruneAiCache(),
        _pruneSyncQueue(),
      ]);
      _applyImageCacheLimits();
    } catch (e) {
      _log.w('CacheManagerService.startup error: $e');
    }
  }

  Future<void> _pruneAiCache() async {
    await _db.pruneExpiredAiCache(_aiCacheTtlHours);
    _log.d('AI cache pruned (TTL $_aiCacheTtlHours h).');
  }

  Future<void> _pruneSyncQueue() async {
    await _db.removeDoneSyncActions();
    final failed = _db.getPendingSyncActions().where((a) => a.isFailed).length;
    if (failed > 0) {
      _log.w('Sync queue: $failed action(s) in failed state.');
    }
  }

  void _applyImageCacheLimits() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = _imageCacheMaxMb * 1024 * 1024;
    cache.maximumSize = _imageCacheMaxEntries;
    _log.d('Image cache: max ${_imageCacheMaxMb}MB / $_imageCacheMaxEntries entries.');
  }

  // ── Storage report ────────────────────────────────────────────────────────

  Future<StorageReport> storageReport() async {
    final contentsDir = await _contentsDirectory();
    final reportsDir  = await _reportsDirectory();

    return StorageReport(
      contentBytes:     await _dirSize(contentsDir),
      reportBytes:      await _dirSize(reportsDir),
      hiveSyncCount:    _db.getPendingSyncActions().length,
      aiCacheCount:     Hive.box(HiveBoxes.aiCache).length,
      marketplaceCount: _db.getAllMarketplaceItems().length,
    );
  }

  Future<Directory> _contentsDirectory() async {
    final app = await getApplicationDocumentsDirectory();
    return Directory('${app.path}/loniya_contents');
  }

  Future<Directory> _reportsDirectory() async {
    final app = await getApplicationDocumentsDirectory();
    return Directory('${app.path}/loniya_reports');
  }

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  // ── Manual cache clear ────────────────────────────────────────────────────

  Future<void> clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
  }

  /// Deletes all downloaded content files (.lnc) from disk.
  /// Does NOT touch Hive metadata — call marketplace delete for full cleanup.
  Future<void> clearContentFiles() async {
    final dir = await _contentsDirectory();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

// ─── Report ───────────────────────────────────────────────────────────────────

class StorageReport {
  final int contentBytes;
  final int reportBytes;
  final int hiveSyncCount;
  final int aiCacheCount;
  final int marketplaceCount;

  const StorageReport({
    required this.contentBytes,
    required this.reportBytes,
    required this.hiveSyncCount,
    required this.aiCacheCount,
    required this.marketplaceCount,
  });

  int get totalBytes => contentBytes + reportBytes;

  String _format(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedTotal    => _format(totalBytes);
  String get formattedContents => _format(contentBytes);
  String get formattedReports  => _format(reportBytes);

  @override
  String toString() =>
      'StorageReport{total: $formattedTotal, '
      'contents: $formattedContents, reports: $formattedReports, '
      'syncQueue: $hiveSyncCount, aiCache: $aiCacheCount, '
      'marketplace: $marketplaceCount}';
}
