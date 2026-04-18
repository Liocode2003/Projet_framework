import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_service.dart';
import 'sync_queue_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, synced, error }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  bool get hasPending => pendingCount > 0;
  bool get hasFailed  => failedCount > 0;
  bool get isSyncing  => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncAt,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SyncState(
        status:       status       ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        failedCount:  failedCount  ?? this.failedCount,
        lastSyncAt:   lastSyncAt   ?? this.lastSyncAt,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncQueueService _service;
  final DatabaseService  _db;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncNotifier(this._service, this._db) : super(const SyncState()) {
    _init();
  }

  void _init() {
    _refreshCounts();

    // Trigger sync whenever connectivity is restored
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && state.hasPending && !state.isSyncing) {
        syncNow();
      }
    });
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(
        status: SyncStatus.syncing, clearError: true);
    try {
      await _service.processQueue();
      _refreshCounts();
      state = state.copyWith(
        status:    SyncStatus.synced,
        lastSyncAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status:       SyncStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Enqueue an action and refresh counts.
  Future<void> enqueue({
    required String type,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await _service.enqueue(
        type: type, entityId: entityId, payload: payload);
    _refreshCounts();
  }

  void _refreshCounts() {
    final pending = _db.getPendingSyncActions();
    state = state.copyWith(
      pendingCount: pending.where((a) => a.isPending).length,
      failedCount:  pending.where((a) => a.isFailed).length,
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService(ref.read(databaseServiceProvider));
});

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    ref.read(syncQueueServiceProvider),
    ref.read(databaseServiceProvider),
  );
});
