import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/performance_provider.dart';

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(performanceDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes performances'),
        backgroundColor: AppColors.learning,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: InlineLoader()),
        error: (e, _) =>
            Center(child: Text('Erreur: $e')),
        data: (data) => _Body(data: data),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PerformanceData data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary cards ────────────────────────────────────────────
          Row(children: [
            Expanded(child: _StatCard(
              label: 'XP Total',
              value: '${data.totalXp}',
              icon: Icons.star_rounded,
              color: AppColors.xpGold,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Niveau',
              value: '${data.level}',
              icon: Icons.military_tech_rounded,
              color: AppColors.levelPurple,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(
              label: 'Leçons terminées',
              value: '${data.totalCompleted}',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Série actuelle',
              value: '${data.currentStreak} j',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.streakOrange,
            )),
          ]),

          const SizedBox(height: 20),

          // ── Completion rate ──────────────────────────────────────────
          _Section(title: 'Taux de complétion'),
          const SizedBox(height: 8),
          _CompletionCard(data: data),

          const SizedBox(height: 20),

          // ── XP by subject ────────────────────────────────────────────
          if (data.xpBySubject.isNotEmpty) ...[
            _Section(title: 'XP par matière'),
            const SizedBox(height: 8),
            RepaintBoundary(child: _SubjectBarChart(xpMap: data.xpBySubject)),
          ],

          const SizedBox(height: 20),

          // ── Streak info ──────────────────────────────────────────────
          _Section(title: 'Régularité'),
          const SizedBox(height: 8),
          _StreakCard(
            current: data.currentStreak,
            longest: data.longestStreak,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Nunito',
            )),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.onSurfaceVariant)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleMedium);
  }
}

class _CompletionCard extends StatelessWidget {
  final PerformanceData data;
  const _CompletionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = data.completionRate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${data.totalCompleted} / ${data.totalAvailable} leçons',
                style: AppTextStyles.bodyMedium),
            Text('${(pct * 100).toInt()}%',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.learning)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.grey200,
            color: AppColors.learning,
            minHeight: 10,
          ),
        ),
      ]),
    );
  }
}

class _SubjectBarChart extends StatelessWidget {
  final Map<String, int> xpMap;
  const _SubjectBarChart({required this.xpMap});

  @override
  Widget build(BuildContext context) {
    final sorted = xpMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxXp = sorted.first.value.toDouble();

    const colors = [
      AppColors.primary, AppColors.secondary, AppColors.aiTutor,
      AppColors.tertiary, AppColors.orientation, AppColors.marketplace,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = maxXp == 0 ? 0.0 : e.value / maxXp;
          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 110,
                child: Text(
                  e.key.length > 14 ? '${e.key.substring(0, 12)}.' : e.key,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.grey200,
                    color: color,
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text('${e.value} XP',
                    style: AppTextStyles.caption.copyWith(color: color),
                    textAlign: TextAlign.end),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int current;
  final int longest;
  const _StreakCard({required this.current, required this.longest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.local_fire_department_rounded,
            color: AppColors.streakOrange, size: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Série actuelle : $current jour(s)',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text('Record : $longest jour(s)',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}
