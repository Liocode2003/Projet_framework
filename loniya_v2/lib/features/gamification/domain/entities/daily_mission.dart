import 'package:flutter/material.dart';

enum MissionType { streak, xp, lesson, badge }

class DailyMission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final int current;
  final int target;
  final int xpReward;
  final IconData icon;
  final Color color;

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.current,
    required this.target,
    required this.xpReward,
    required this.icon,
    required this.color,
  });

  bool get isCompleted => current >= target;
  double get progress =>
      target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
}
