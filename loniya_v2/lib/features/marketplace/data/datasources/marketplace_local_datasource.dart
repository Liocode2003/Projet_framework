import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database/database_service.dart';
import '../models/marketplace_item_model.dart';
import 'content_download_service.dart';

/// Local datasource: reads catalogue from bundled JSON asset,
/// persists downloaded state in Hive via DatabaseService.
class MarketplaceLocalDataSource {
  final DatabaseService _db;
  final ContentDownloadService _downloadService;

  const MarketplaceLocalDataSource(this._db, this._downloadService);

  static const String _cataloguePath = 'assets/mock_data/marketplace_items.json';

  // ─── Catalogue ────────────────────────────────────────────────────────
  /// Returns merged list: asset catalogue enriched with Hive download state.
  Future<List<MarketplaceItemModel>> getAllItems() async {
    try {
      // 1. Load from bundled JSON (source of truth for metadata)
      final jsonStr = await rootBundle.loadString(_cataloguePath);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final assetItems = list
          .map((j) => MarketplaceItemModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // 2. Merge with Hive download state
      await _db.saveAllMarketplaceItems(
        assetItems.map((i) {
          final stored = _db.getMarketplaceItem(i.id);
          if (stored != null) {
            // Keep download state from Hive; refresh metadata from asset
            return i.copyWith(
              isDownloaded: stored.isDownloaded,
              localPath: stored.localPath,
            );
          }
          return i;
        }).toList(),
      );

      return _db.getAllMarketplaceItems();
    } catch (e) {
      // Fallback to Hive-only if asset fails
      final hiveItems = _db.getAllMarketplaceItems();
      if (hiveItems.isNotEmpty) return hiveItems;
      throw CacheException('Impossible de charger le catalogue : $e');
    }
  }

  Future<List<MarketplaceItemModel>> filterItems({
    String? subject,
    String? gradeLevel,
    String? type,
    String? query,
  }) async {
    final all = await getAllItems();
    return all.where((item) {
      if (subject != null && subject.isNotEmpty && item.subject != subject) {
        return false;
      }
      if (gradeLevel != null && gradeLevel.isNotEmpty &&
          item.gradeLevel != gradeLevel) return false;
      if (type != null && type.isNotEmpty && item.type != type) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final inTitle = item.title.toLowerCase().contains(q);
        final inDesc  = item.description.toLowerCase().contains(q);
        final inTags  = item.tags.any((t) => t.toLowerCase().contains(q));
        if (!inTitle && !inDesc && !inTags) return false;
      }
      return true;
    }).toList();
  }

  Future<List<MarketplaceItemModel>> getDownloadedItems() async {
    return _db.getDownloadedItems();
  }

  MarketplaceItemModel? getItemById(String id) => _db.getMarketplaceItem(id);

  // ─── Download pipeline ────────────────────────────────────────────────
  Future<MarketplaceItemModel> downloadItem(
    String id, {
    void Function(double)? onProgress,
  }) async {
    final item = _db.getMarketplaceItem(id);
    if (item == null) throw CacheException('Contenu $id introuvable.');
    if (item.isDownloaded && item.localPath != null) return item;

    // Build mock payload (in production: HTTP GET from server)
    final payload = jsonEncode(item.toJson());

    // Run compress → encrypt → write pipeline
    final localPath = await _downloadService.downloadAndStore(
      id, payload, onProgress: onProgress,
    );

    // Update Hive record
    final updated = item.copyWith(isDownloaded: true, localPath: localPath);
    await _db.saveMarketplaceItem(updated);
    return updated;
  }

  Future<void> deleteItem(String id) async {
    final item = _db.getMarketplaceItem(id);
    if (item == null) return;
    if (item.localPath != null) {
      await _downloadService.deleteContent(item.localPath!);
    }
    final updated = item.copyWith(isDownloaded: false, localPath: '');
    await _db.saveMarketplaceItem(updated);
  }
}
