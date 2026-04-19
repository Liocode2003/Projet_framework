import 'package:hive/hive.dart';

import '../../constants/hive_boxes.dart';
import '../../data/models/sync_action_model.dart';
import '../database/database_service.dart';
import '../../../features/learning/data/models/progress_model.dart';
import '../../../features/orientation/data/models/orientation_result_model.dart';

/// Processes the offline sync queue.
///
/// Architecture:
///   1. Actions are enqueued offline via [DatabaseService.enqueueSyncAction].
///   2. [processQueue] applies each pending action locally (the queue is
///      structured for future remote sync when a server is added).
///   3. Conflict resolution: last-write-wins using [ProgressModel.version].
///      Higher version wins; equal version keeps whichever is already stored.
///   4. Retry policy: up to 3 attempts, delays 2 s → 4 s → 8 s.
///      After 3 failures the action is marked [failed] and skipped on next run.
///
/// Supported action types:
///   progress.update      — lesson progress (score, steps, xp, completion)
///   gamification.xp      — award XP to user (with optional subject tag)
///   gamification.badge   — unlock a badge by id
///   orientation.result   — persist an orientation analysis result
class SyncQueueService {
  final DatabaseService _db;

  static const List<int> _retryDelaysMs = [2000, 4000, 8000];

  const SyncQueueService(this._db);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Processes all pending actions in FIFO order.
  /// Returns the number of successfully applied actions.
  Future<int> processQueue() async {
    final pending = _db.getPendingSyncActions();
    if (pending.isEmpty) return 0;

    int applied = 0;
    for (final action in pending) {
      final success = await _processAction(action);
      if (success) applied++;
    }

    await _db.removeDoneSyncActions();
    return applied;
  }

  /// Convenience wrapper — also stamps [updatedAt] into the payload.
  Future<void> enqueue({
    required String type,
    required String entityId,
    required Map<String, dynamic> payload,
  }) =>
      _db.enqueueSyncAction(
        type: type,
        entityId: entityId,
        payload: {
          ...payload,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

  int get pendingCount => _db.pendingSyncCount;

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<bool> _processAction(SyncActionModel action) async {
    final delayMs = _delay(action.retries);
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    try {
      final applied = await _apply(action);
      await _db.updateSyncAction(action.markDone());
      return applied;
    } catch (e) {
      await _db.updateSyncAction(action.incrementRetry(e.toString()));
      return false;
    }
  }

  Future<bool> _apply(SyncActionModel action) async {
    switch (action.type) {
      case 'progress.update':
        return _applyProgress(action.payload);
      case 'gamification.xp':
        return _applyXp(action.payload);
      case 'gamification.badge':
        return _applyBadge(action.payload);
      case 'orientation.result':
        return _applyOrientation(action.payload);
      default:
        return true; // unknown type — drain without error
    }
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<bool> _applyProgress(Map<String, dynamic> p) async {
    final userId   = p['userId']   as String? ?? '';
    final lessonId = p['lessonId'] as String? ?? '';
    final version  = (p['version'] as num?)?.toInt() ?? 1;

    // Last-write-wins: higher version wins
    final stored = _db.getProgress(userId, lessonId);
    if (stored != null && stored.version >= version) return false; // stale

    final model = ProgressModel(
      id:               '${userId}_$lessonId',
      userId:           userId,
      lessonId:         lessonId,
      currentStepIndex: (p['currentStepIndex'] as num?)?.toInt() ?? 0,
      isCompleted:      p['isCompleted'] as bool? ?? false,
      score:            (p['score'] as num?)?.toInt() ?? 0,
      xpEarned:         (p['xpEarned'] as num?)?.toInt() ?? 0,
      startedAt:        p['startedAt'] as String? ?? DateTime.now().toIso8601String(),
      completedAt:      p['completedAt'] as String?,
      completedSteps:   List<int>.from(p['completedSteps'] as List? ?? []),
      attempts:         (p['attempts'] as num?)?.toInt() ?? 1,
      syncPending:      false,
      version:          version,
    );

    await _db.saveProgress(model);
    return true;
  }

  Future<bool> _applyXp(Map<String, dynamic> p) async {
    final userId  = p['userId']  as String? ?? '';
    final xp      = (p['xp'] as num?)?.toInt() ?? 0;
    final subject = p['subject'] as String?;
    if (xp <= 0 || userId.isEmpty) return false;
    await _db.addXp(userId, xp, subject: subject);
    return true;
  }

  Future<bool> _applyBadge(Map<String, dynamic> p) async {
    final userId  = p['userId']  as String? ?? '';
    final badgeId = p['badgeId'] as String? ?? '';
    if (userId.isEmpty || badgeId.isEmpty) return false;
    await _db.unlockBadge(userId, badgeId);
    return true;
  }

  Future<bool> _applyOrientation(Map<String, dynamic> p) async {
    try {
      final json   = Map<String, dynamic>.from(p['result'] as Map? ?? {});
      final result = OrientationResultModel.fromJson(json);
      await Hive.box(HiveBoxes.orientation).put(result.id, result);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _delay(int retries) {
    if (retries == 0) return 0;
    return _retryDelaysMs[((retries - 1)).clamp(0, _retryDelaysMs.length - 1)];
  }
}
