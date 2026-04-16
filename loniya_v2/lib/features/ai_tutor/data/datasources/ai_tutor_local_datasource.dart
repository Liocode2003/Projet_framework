import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../../core/services/database/database_service.dart';
import '../models/ai_cache_entry_model.dart';
import '../services/ai_tutor_engine.dart';

class AiTutorLocalDataSource {
  final DatabaseService _db;
  final AiTutorEngine _engine;

  AiTutorLocalDataSource(this._db, this._engine);

  /// Returns a cached response, or null if not found / expired.
  Future<String?> getCachedResponse({
    required String userId,
    required String question,
    required String stepId,
    int maxAgeHours = 72,
  }) async {
    final key = _hash(userId, stepId, question);
    final entry = _db.getAiCache(key);
    if (entry == null) return null;
    if (entry.isExpired(maxAgeHours)) {
      // Stale — let it be regenerated and overwritten
      return null;
    }
    // Increment hit counter
    await _db.saveAiCache(entry.incrementHit());
    return entry.response;
  }

  /// Generates a new response via the engine and persists it to cache.
  Future<String> generateAndCache({
    required String userId,
    required String question,
    required String stepId,
    List<String> stepKeywords = const [],
    String subject = '',
  }) async {
    final response = await _engine.generate(
      question: question,
      stepKeywords: stepKeywords,
      subject: subject,
    );

    final entry = AiCacheEntryModel(
      queryHash: _hash(userId, stepId, question),
      question: question,
      response: response,
      stepId: stepId,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.saveAiCache(entry);
    return response;
  }

  /// Removes expired entries from cache.
  Future<void> pruneCache(int maxAgeHours) =>
      _db.pruneExpiredAiCache(maxAgeHours);

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _hash(String userId, String stepId, String question) {
    final data = '$userId:$stepId:${question.trim().toLowerCase()}';
    return sha256.convert(utf8.encode(data)).toString();
  }
}
