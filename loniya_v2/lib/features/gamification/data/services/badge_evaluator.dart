import '../../data/models/badge_model.dart';
import '../../data/models/gamification_model.dart';

/// Pure service: evaluates which badges should be unlocked
/// given the current [GamificationModel], and returns their IDs.
class BadgeEvaluator {
  const BadgeEvaluator();

  /// Returns badge IDs that are newly unlockable (not yet in
  /// [g.unlockedBadgeIds]) based on current game state.
  List<String> findNewlyUnlockable(
    GamificationModel g,
    List<BadgeModel> allBadges,
  ) {
    final result = <String>[];
    for (final badge in allBadges) {
      if (g.unlockedBadgeIds.contains(badge.id)) continue;
      if (_isUnlockable(badge.id, g)) result.add(badge.id);
    }
    return result;
  }

  bool _isUnlockable(String badgeId, GamificationModel g) {
    switch (badgeId) {
      case 'badge_first_lesson':
        return g.lessonsCompleted >= 1;
      case 'badge_streak_3':
        return g.currentStreak >= 3;
      case 'badge_streak_7':
        return g.currentStreak >= 7;
      case 'badge_streak_30':
        return g.currentStreak >= 30;
      case 'badge_maths_10':
        // Proxy: ≥ 500 XP in Maths ≈ ~10 lessons
        return (g.xpBySubject['Mathématiques'] ?? 0) >= 500;
      case 'badge_level_5':
        return g.level >= 5;
      case 'badge_level_10':
        return g.level >= 10;
      case 'badge_offline_hero':
        return g.lessonsCompleted >= 5;
      default:
        return false;
    }
  }
}
