import 'dart:convert';
import 'package:flutter/services.dart';

import '../../../../core/services/database/database_service.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';

class LearningLocalDataSource {
  final DatabaseService _db;
  LearningLocalDataSource(this._db);

  List<LessonModel>? _cache;

  Future<List<LessonModel>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/mock_data/lessons.json');
    final list = json.decode(raw) as List;
    _cache = list
        .map((j) => LessonModel.fromJson(j as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<LessonModel>> getAllLessons() => _load();

  Future<List<LessonModel>> getAvailableLessons() async {
    final all = await _load();
    final downloadedIds = _db
        .getAllMarketplaceItems()
        .where((i) => i.isDownloaded)
        .map((i) => i.id)
        .toSet();
    return all
        .where((l) => downloadedIds.contains(l.contentItemId))
        .toList();
  }

  /// Matches by lesson [id] first, then by [contentItemId] (FK from marketplace).
  Future<LessonModel?> getLessonById(String id) async {
    final all = await _load();
    try {
      return all.firstWhere(
        (l) => l.id == id || l.contentItemId == id,
      );
    } catch (_) {
      return null;
    }
  }

  ProgressModel? getProgress(String userId, String lessonId) =>
      _db.getProgress(userId, lessonId);

  Future<void> saveProgress(ProgressModel progress) =>
      _db.saveProgress(progress);
}
