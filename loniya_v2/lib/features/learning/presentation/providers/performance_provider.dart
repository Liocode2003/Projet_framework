import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';

class PerformanceData {
  final int totalCompleted;
  final int totalAvailable;
  final Map<String, int> completedBySubject;  // subject → count
  final Map<String, int> xpBySubject;         // subject → XP
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final int level;

  const PerformanceData({
    required this.totalCompleted,
    required this.totalAvailable,
    required this.completedBySubject,
    required this.xpBySubject,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.level,
  });

  double get completionRate =>
      totalAvailable == 0 ? 0 : totalCompleted / totalAvailable;

  List<String> get subjects =>
      xpBySubject.keys.toList()
        ..sort((a, b) =>
            (xpBySubject[b] ?? 0).compareTo(xpBySubject[a] ?? 0));
}

final performanceDataProvider =
    FutureProvider.autoDispose<PerformanceData>((ref) async {
  final userId = ref.watch(authNotifierProvider).userId ?? '';
  final db = ref.read(databaseServiceProvider);
  final g = db.getOrCreateGamification(userId);

  final completed = db.getCompletedLessons(userId);
  final all = db.getAllMarketplaceItems();

  // Build completedBySubject from progress
  final bySubject = <String, int>{};
  for (final p in completed) {
    // subject isn't on ProgressModel directly; use xpBySubject as proxy
  }
  // Use xpBySubject from gamification (has subject data)
  final xpMap = Map<String, int>.from(g.xpBySubject);

  // completedBySubject: approximate from lessonId names or from progress tags
  // Since progress doesn't store subject directly, count per subject using marketplace data
  final subjectCount = <String, int>{};
  for (final p in completed) {
    final item = all.cast<dynamic>().firstWhere(
          (i) => i.id == p.lessonId,
          orElse: () => null,
        );
    if (item != null) {
      final subject = item.subject as String;
      subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
    }
  }

  // If no subject data from progress, distribute evenly across XP subjects
  if (subjectCount.isEmpty && xpMap.isNotEmpty) {
    for (final s in xpMap.keys) {
      subjectCount[s] = 0;
    }
  }

  return PerformanceData(
    totalCompleted: completed.length,
    totalAvailable: all.length,
    completedBySubject: subjectCount,
    xpBySubject: xpMap,
    currentStreak: g.currentStreak,
    longestStreak: g.longestStreak,
    totalXp: g.totalXp,
    level: g.level,
  );
});
