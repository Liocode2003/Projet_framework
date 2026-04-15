import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/app_constants.dart';

part 'gamification_model.g.dart';

@HiveType(typeId: HiveTypeIds.gamificationModel)
class GamificationModel extends HiveObject {
  @HiveField(0)  final String userId;
  @HiveField(1)  final int totalXp;
  @HiveField(2)  final int level;            // 1–100
  @HiveField(3)  final int currentStreak;    // consecutive days
  @HiveField(4)  final int longestStreak;
  @HiveField(5)  final String? lastActivityDate; // ISO date (YYYY-MM-DD)
  @HiveField(6)  final List<String> unlockedBadgeIds;
  @HiveField(7)  final int lessonsCompleted;
  @HiveField(8)  final int totalTimeMinutes;
  @HiveField(9)  final Map<String, int> xpBySubject; // subject → XP
  @HiveField(10) final int version;

  GamificationModel({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    required this.unlockedBadgeIds,
    required this.lessonsCompleted,
    required this.totalTimeMinutes,
    required this.xpBySubject,
    this.version = 1,
  });

  factory GamificationModel.empty(String userId) => GamificationModel(
        userId: userId, totalXp: 0, level: 1,
        currentStreak: 0, longestStreak: 0,
        unlockedBadgeIds: [], lessonsCompleted: 0,
        totalTimeMinutes: 0, xpBySubject: {}, version: 1,
      );

  /// XP needed to reach the next level (quadratic scale).
  int get xpToNextLevel => (level * level * 100);
  int get xpInCurrentLevel => totalXp - _xpForLevel(level);
  double get levelProgress => xpToNextLevel == 0
      ? 1.0
      : (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);

  static int _xpForLevel(int lvl) => lvl <= 1 ? 0 : ((lvl - 1) * (lvl - 1) * 100);

  static int levelFromXp(int xp) {
    int lvl = 1;
    while (lvl < AppConstants.maxLevel && _xpForLevel(lvl + 1) <= xp) {
      lvl++;
    }
    return lvl;
  }

  GamificationModel addXp(int xp, {String? subject}) {
    final newTotal = totalXp + xp;
    final newLevel = levelFromXp(newTotal).clamp(1, AppConstants.maxLevel);
    final subjectMap = Map<String, int>.from(xpBySubject);
    if (subject != null) {
      subjectMap[subject] = (subjectMap[subject] ?? 0) + xp;
    }
    return copyWith(
      totalXp: newTotal, level: newLevel, xpBySubject: subjectMap,
    );
  }

  GamificationModel updateStreak() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    if (lastActivityDate == todayStr) return this; // already updated today

    int newStreak = currentStreak;
    if (lastActivityDate != null) {
      final last = DateTime.parse('${lastActivityDate!}T00:00:00');
      final diff = today.difference(last).inHours;
      newStreak = diff <= AppConstants.streakResetHours ? currentStreak + 1 : 1;
    } else {
      newStreak = 1;
    }
    return copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      lastActivityDate: todayStr,
    );
  }

  GamificationModel copyWith({
    int? totalXp, int? level, int? currentStreak, int? longestStreak,
    String? lastActivityDate, List<String>? unlockedBadgeIds,
    int? lessonsCompleted, int? totalTimeMinutes,
    Map<String, int>? xpBySubject, int? version,
  }) =>
      GamificationModel(
        userId: userId,
        totalXp: totalXp ?? this.totalXp,
        level: level ?? this.level,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastActivityDate: lastActivityDate ?? this.lastActivityDate,
        unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
        lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
        totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
        xpBySubject: xpBySubject ?? this.xpBySubject,
        version: version ?? this.version,
      );
}

class GamificationModelAdapter extends TypeAdapter<GamificationModel> {
  @override
  final int typeId = HiveTypeIds.gamificationModel;

  @override
  GamificationModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return GamificationModel(
      userId: f[0] as String, totalXp: f[1] as int, level: f[2] as int,
      currentStreak: f[3] as int, longestStreak: f[4] as int,
      lastActivityDate: f[5] as String?,
      unlockedBadgeIds: List<String>.from(f[6] as List? ?? []),
      lessonsCompleted: f[7] as int, totalTimeMinutes: f[8] as int,
      xpBySubject: Map<String, int>.from(f[9] as Map? ?? {}),
      version: f[10] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, GamificationModel obj) {
    writer.writeMap({
      0: obj.userId, 1: obj.totalXp, 2: obj.level,
      3: obj.currentStreak, 4: obj.longestStreak,
      5: obj.lastActivityDate, 6: obj.unlockedBadgeIds,
      7: obj.lessonsCompleted, 8: obj.totalTimeMinutes,
      9: obj.xpBySubject, 10: obj.version,
    });
  }
}
