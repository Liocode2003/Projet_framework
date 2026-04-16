import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/services/orientation_engine.dart';
import '../providers/orientation_provider.dart';
import '../widgets/score_input_row.dart';

class OrientationScreen extends ConsumerWidget {
  const OrientationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(orientationNotifierProvider);
    final notifier = ref.read(orientationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orientation,
                      Color(0xFF004D40),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Row(children: [
                const Icon(Icons.compass_calibration_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Orientation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
              ]),
              titlePadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Exam type selector ───────────────────────────────
                Text('Type d\'examen', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _ExamTypeCard(
                      label:    'BEPC',
                      subtitle: 'Brevet du 1er Cycle',
                      icon:     Icons.school_rounded,
                      color:    AppColors.secondary,
                      selected: state.examType == 'BEPC',
                      onTap:    () => notifier.selectExamType('BEPC'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExamTypeCard(
                      label:    'BAC',
                      subtitle: 'Baccalauréat',
                      icon:     Icons.account_balance_rounded,
                      color:    AppColors.orientation,
                      selected: state.examType == 'BAC',
                      onTap:    () => notifier.selectExamType('BAC'),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Score entry ───────────────────────────────────────
                Row(children: [
                  Text('Notes', style: AppTextStyles.titleMedium),
                  const Spacer(),
                  Text(
                    'Glisse le curseur pour saisir ta note',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ]),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _subjectsFor(state.examType)
                          .entries
                          .map((e) => ScoreInputRow(
                                subject:     e.key,
                                score:       state.scores[e.key] ?? 10,
                                coefficient: e.value,
                                onChanged:   (v) =>
                                    notifier.updateScore(e.key, v),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // ── Average preview ──────────────────────────────────
                if (state.hasScores) ...[
                  const SizedBox(height: 12),
                  _AveragePreview(
                    scores:  state.scores,
                    coeffs:  _subjectsFor(state.examType),
                    engine:  ref.read(orientationEngineProvider),
                    examType: state.examType,
                  ),
                ],

                // ── Error ─────────────────────────────────────────────
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(state.errorMessage!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Analyze button ────────────────────────────────────
                AppButton(
                  label: state.isAnalyzing
                      ? 'Analyse en cours…'
                      : 'Analyser mes résultats',
                  prefixIcon: state.isAnalyzing
                      ? null
                      : Icons.analytics_rounded,
                  isLoading: state.isAnalyzing,
                  backgroundColor: AppColors.orientation,
                  foregroundColor: Colors.white,
                  onPressed: state.isAnalyzing
                      ? null
                      : () async {
                          final result = await notifier.analyze();
                          if (result != null && context.mounted) {
                            context.go(RouteNames.orientationResult);
                          }
                        },
                ),

                // ── Link to last result ───────────────────────────────
                if (state.lastResult != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Voir la dernière analyse',
                    prefixIcon: Icons.history_rounded,
                    variant: AppButtonVariant.outlined,
                    onPressed: () =>
                        context.go(RouteNames.orientationResult),
                  ),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _subjectsFor(String examType) =>
      examType == 'BAC'
          ? OrientationEngine.bacSubjects
          : OrientationEngine.bepcSubjects;
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ExamTypeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ExamTypeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.grey200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon,
              color: selected ? color : AppColors.grey400,
              size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.titleSmall.copyWith(
                color: selected ? color : AppColors.onSurface,
              )),
          Text(subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _AveragePreview extends StatelessWidget {
  final Map<String, double> scores;
  final Map<String, int> coeffs;
  final OrientationEngine engine;
  final String examType;

  const _AveragePreview({
    required this.scores,
    required this.coeffs,
    required this.engine,
    required this.examType,
  });

  double get _weightedAvg {
    double sum = 0;
    int total = 0;
    for (final e in scores.entries) {
      final c = coeffs[e.key] ?? 1;
      sum += e.value * c;
      total += c;
    }
    return total == 0 ? 0 : sum / total;
  }

  Color get _avgColor {
    final a = _weightedAvg;
    if (a >= 14) return AppColors.success;
    if (a >= 10) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _avgColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _avgColor.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.calculate_rounded, size: 20),
        const SizedBox(width: 10),
        Text('Moyenne pondérée estimée :',
            style: AppTextStyles.bodySmall),
        const Spacer(),
        Text(
          '${_weightedAvg.toStringAsFixed(2)}/20',
          style: AppTextStyles.titleSmall.copyWith(
            color: _avgColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }
}
