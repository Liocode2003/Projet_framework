import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../../core/services/sync/sync_notifier.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/gamification_model.dart';
import '../../data/services/badge_evaluator.dart';
import '../../data/services/daily_mission_service.dart';
import '../../domain/entities/daily_mission.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ─── Badges from JSON asset ───────────────────────────────────────────────────
final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final raw =
      await rootBundle.loadString('assets/mock_data/badges.json');
  return (json.decode(raw) as List)
      .map((j) => BadgeModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ─── Gamification state ───────────────────────────────────────────────────────
class GamificationState {
  final GamificationModel? data;
  final List<BadgeModel> badges;
  final List<String> newlyUnlockedIds; // shown in notification
  final bool isLoading;

  const GamificationState({
    this.data,
    this.badges = const [],
    this.newlyUnlockedIds = const [],
    this.isLoading = true,
  });

  GamificationState copyWith({
    GamificationModel? data,
    List<BadgeModel>? badges,
    List<String>? newlyUnlockedIds,
    bool? isLoading,
  }) =>
      GamificationState(
        data:             data ?? this.data,
        badges:           badges ?? this.badges,
        newlyUnlockedIds: newlyUnlockedIds ?? this.newlyUnlockedIds,
        isLoading:        isLoading ?? this.isLoading,
      );

  /// Badge list merged with unlock status from [data].
  List<BadgeModel> get mergedBadges {
    if (data == null) return badges;
    return badges.map((b) {
      if (data!.unlockedBadgeIds.contains(b.id)) {
        return b.isUnlocked ? b : b.unlock();
      }
      return b;
    }).toList();
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class GamificationNotifier extends StateNotifier<GamificationState> {
  final Ref _ref;
  static const _evaluator = BadgeEvaluator();

  GamificationNotifier(this._ref) : super(const GamificationState()) {
    _init();
  }

  Future<void> _init() async {
    final badges = await _ref.read(allBadgesProvider.future);
    final userId = _ref.read(currentUserProvider)?.id ?? '';
    final g = _ref.read(databaseServiceProvider).getOrCreateGamification(userId);

    // Check for any badges earned before this session
    final newly = _evaluator.findNewlyUnlockable(g, badges);
    GamificationModel updated = g;
    if (newly.isNotEmpty) {
      updated = await _unlockBadges(g, newly, badges);
    }

    state = GamificationState(
      data:      updated,
      badges:    badges,
      isLoading: false,
    );
  }

  /// Refreshes from Hive (call after lesson completion or XP gain).
  Future<void> refresh() async {
    final userId = _ref.read(currentUserProvider)?.id ?? '';
    final g =
        _ref.read(databaseServiceProvider).getOrCreateGamification(userId);
    final badges = state.badges.isEmpty
        ? await _ref.read(allBadgesProvider.future)
        : state.badges;

    final newly = _evaluator.findNewlyUnlockable(g, badges);
    GamificationModel updated = g;
    if (newly.isNotEmpty) {
      updated = await _unlockBadges(g, newly, badges);
    }

    state = state.copyWith(
      data:             updated,
      badges:           badges,
      newlyUnlockedIds: newly,
      isLoading:        false,
    );
  }

  void clearNewlyUnlocked() =>
      state = state.copyWith(newlyUnlockedIds: []);

  // ─── Private ──────────────────────────────────────────────────────────────
  Future<GamificationModel> _unlockBadges(
    GamificationModel g,
    List<String> newIds,
    List<BadgeModel> badges,
  ) async {
    final db = _ref.read(databaseServiceProvider);
    GamificationModel updated = g;
    int bonusXp = 0;

    for (final id in newIds) {
      updated = updated.copyWith(
        unlockedBadgeIds: [...updated.unlockedBadgeIds, id],
      );
      // Add badge XP reward
      final badge = badges.firstWhere((b) => b.id == id,
          orElse: () => BadgeModel(
              id: id, title: '', description: '', iconAsset: '',
              category: '', xpReward: 0, condition: ''));
      bonusXp += badge.xpReward;
    }
    if (bonusXp > 0) {
      updated = updated.addXp(bonusXp);
    }
    await db.saveGamification(updated);

    // Enqueue badge unlock sync actions
    final userId = updated.userId;
    final sync = _ref.read(syncNotifierProvider.notifier);
    for (final id in newIds) {
      await sync.enqueue(
        type: 'gamification.badge',
        entityId: '${userId}_$id',
        payload: {'userId': userId, 'badgeId': id},
      );
    }

    return updated;
  }
}

final gamificationNotifierProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>(
  (ref) => GamificationNotifier(ref),
);

// ─── Daily missions (derived) ────────────────────────────────────────────────
final dailyMissionsProvider = Provider<List<DailyMission>>((ref) {
  final g = ref.watch(gamificationNotifierProvider).data;
  if (g == null) return [];
  return const DailyMissionService().generate(g);
});
