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

    // Seed demo leaderboard entries on first launch
    await _seedDemoLeaderboard();
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

  // ─── Demo leaderboard seeding ─────────────────────────────────────────────

  Future<void> _seedDemoLeaderboard() async {
    final db = _ref.read(databaseServiceProvider);
    if (db.getLeaderboard().any((g) => g.userId.startsWith('demo_'))) return;

    final demos = [
      _demoEntry('demo_001', 5240, 8, 15),
      _demoEntry('demo_002', 4180, 7,  9),
      _demoEntry('demo_003', 3650, 6, 21),
      _demoEntry('demo_004', 2870, 5,  6),
      _demoEntry('demo_005', 2140, 4, 12),
      _demoEntry('demo_006', 1620, 3,  4),
      _demoEntry('demo_007', 1100, 2, 18),
      _demoEntry('demo_008',  780, 2,  3),
      _demoEntry('demo_009',  450, 1,  7),
      _demoEntry('demo_010',  210, 1,  1),
    ];
    for (final g in demos) {
      await db.saveGamification(g);
    }
  }

  static GamificationModel _demoEntry(
      String id, int xp, int level, int streak) =>
      GamificationModel(
        userId:           id,
        totalXp:          xp,
        level:            level,
        currentStreak:    streak,
        longestStreak:    streak + 3,
        unlockedBadgeIds: [
          'badge_first_lesson',
          if (xp >  800) 'badge_streak_3',
          if (xp > 2000) 'badge_streak_7',
          if (level >= 5) 'badge_level_5',
          if (level >= 10) 'badge_level_10',
        ],
        lessonsCompleted: xp ~/ 50,
        totalTimeMinutes: xp ~/ 8,
        xpBySubject: {
          'Mathématiques': xp ~/ 3,
          'Français':      xp ~/ 4,
          'Sciences':      xp ~/ 6,
        },
        lastActivityDate: DateTime.now()
            .subtract(Duration(days: level % 4))
            .toIso8601String()
            .substring(0, 10),
        version: 1,
      );

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
