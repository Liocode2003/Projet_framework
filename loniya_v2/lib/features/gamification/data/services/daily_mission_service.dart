import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gamification_model.dart';
import '../../domain/entities/daily_mission.dart';

/// Generates 3 daily missions deterministically from the current
/// [GamificationModel]. Missions refresh each calendar day.
class DailyMissionService {
  const DailyMissionService();

  List<DailyMission> generate(GamificationModel g) {
    final today = _todayStr();
    final isActiveToday = g.lastActivityDate == today;

    return [
      _streakMission(g, isActiveToday),
      _xpMilestone(g),
      _badgeMission(g),
    ];
  }

  // ── Mission 1 — Daily streak ──────────────────────────────────────────────
  DailyMission _streakMission(GamificationModel g, bool activeToday) {
    return DailyMission(
      id:          'streak_daily',
      title:       g.currentStreak == 0
          ? 'Commencer ta série'
          : 'Maintenir ta série',
      description: 'Complète au moins une activité aujourd\'hui.',
      type:        MissionType.streak,
      current:     activeToday ? 1 : 0,
      target:      1,
      xpReward:    25,
      icon:        Icons.local_fire_department_rounded,
      color:       AppColors.streakOrange,
    );
  }

  // ── Mission 2 — XP milestone ──────────────────────────────────────────────
  DailyMission _xpMilestone(GamificationModel g) {
    // Next round-number XP milestone above current total
    final milestone = _nextXpMilestone(g.totalXp);
    return DailyMission(
      id:          'xp_milestone',
      title:       'Atteindre $milestone XP',
      description: 'Accumule des points d\'expérience en apprenant.',
      type:        MissionType.xp,
      current:     g.totalXp,
      target:      milestone,
      xpReward:    50,
      icon:        Icons.star_rounded,
      color:       AppColors.xpGold,
    );
  }

  // ── Mission 3 — Badge hunt ────────────────────────────────────────────────
  DailyMission _badgeMission(GamificationModel g) {
    final unlocked = g.unlockedBadgeIds.length;
    final nextTarget = unlocked + 1;
    return DailyMission(
      id:          'badge_hunt',
      title:       'Débloquer un badge',
      description: 'Progresse pour débloquer ton prochain badge.',
      type:        MissionType.badge,
      current:     unlocked,
      target:      nextTarget,
      xpReward:    30,
      icon:        Icons.military_tech_rounded,
      color:       AppColors.levelPurple,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
  }

  static int _nextXpMilestone(int current) {
    const steps = [
      100, 250, 500, 750, 1000, 1500, 2000, 3000, 5000,
      7500, 10000, 15000, 20000, 30000, 50000,
    ];
    for (final s in steps) {
      if (current < s) return s;
    }
    // Beyond 50k: next multiple of 10000
    return ((current ~/ 10000) + 1) * 10000;
  }
}
