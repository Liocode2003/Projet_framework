import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/gamification_model.dart';

final _leaderboardProvider = FutureProvider.autoDispose<List<_RankEntry>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  final currentId = ref.read(authNotifierProvider).userId ?? '';
  final items = db.getLeaderboard();
  final users = db.getAllUsers();
  final userMap = {for (final u in users) u.id: u.name ?? u.phone};

  return items.asMap().entries.map((entry) {
    final rank = entry.key + 1;
    final g = entry.value;
    return _RankEntry(
      rank: rank,
      userId: g.userId,
      displayName: userMap[g.userId] ?? 'Anonyme',
      totalXp: g.totalXp,
      level: g.level,
      streak: g.currentStreak,
      lessonsCompleted: g.lessonsCompleted,
      isCurrentUser: g.userId == currentId,
    );
  }).toList();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classement'),
        backgroundColor: AppColors.levelPurple,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (entries) => entries.isEmpty
            ? const Center(
                child: Text('Aucun joueur classé pour le moment.'))
            : _Body(entries: entries),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<_RankEntry> entries;
  const _Body({required this.entries});

  @override
  Widget build(BuildContext context) {
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      children: [
        // Podium
        if (top3.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Podium(top3: top3),
          const SizedBox(height: 16),
        ],

        // Rest of leaderboard
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Classement complet',
                style: AppTextStyles.titleMedium),
          ),
          ...rest.map((e) => _RankTile(entry: e)),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<_RankEntry> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.xpGold, AppColors.xpSilver, AppColors.xpBronze];
    final sizes = [80.0, 64.0, 64.0];
    final order = top3.length >= 3
        ? [top3[1], top3[0], top3[2]]
        : top3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.levelPurple, Color(0xFF4A148C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final isCenter = top3.length >= 2 && e == top3[0];
          final color = colors[(e.rank - 1).clamp(0, 2)];
          final size = isCenter ? sizes[0] : sizes[1];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCenter)
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.xpGold, size: 28),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(color: color, width: 3),
                ),
                child: Center(
                  child: Text(
                    e.displayName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCenter ? 28 : 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e.displayName.length > 10
                    ? '${e.displayName.substring(0, 8)}…'
                    : e.displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '${e.totalXp} XP',
                style: TextStyle(color: color, fontSize: 11),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Text(
                  '#${e.rank}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final _RankEntry entry;
  const _RankTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.levelPurple.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.levelPurple.withOpacity(0.3)
              : AppColors.outline,
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text(
            '#${entry.rank}',
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.levelPurple.withOpacity(0.15),
          child: Text(
            entry.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: AppColors.levelPurple, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text(
                entry.isCurrentUser
                    ? '${entry.displayName} (moi)'
                    : entry.displayName,
                style: AppTextStyles.bodyMedium,
              ),
            ]),
            Text(
              'Niv. ${entry.level} · ${entry.streak} j. série',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ]),
        ),
        Text(
          '${entry.totalXp} XP',
          style: const TextStyle(
            color: AppColors.levelPurple,
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
          ),
        ),
      ]),
    );
  }
}

class _RankEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int totalXp;
  final int level;
  final int streak;
  final int lessonsCompleted;
  final bool isCurrentUser;

  const _RankEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.lessonsCompleted,
    required this.isCurrentUser,
  });
}
