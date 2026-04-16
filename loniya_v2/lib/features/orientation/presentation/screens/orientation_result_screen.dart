import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/orientation_result_model.dart';
import '../providers/orientation_provider.dart';
import '../widgets/score_bar_chart.dart';

class OrientationResultScreen extends ConsumerWidget {
  const OrientationResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(orientationNotifierProvider);
    final notifier = ref.read(orientationNotifierProvider.notifier);
    final result   = state.lastResult;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Résultat')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.grey400),
              const SizedBox(height: 16),
              Text('Aucune analyse disponible',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              AppButton(
                label: 'Lancer une analyse',
                prefixIcon: Icons.analytics_rounded,
                onPressed: () => context.go(RouteNames.orientation),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.go(RouteNames.orientation),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orientation, Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Row(children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Résultat ${result.examType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
              ]),
              titlePadding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Recommended filière card ─────────────────────────────
                _FiliereCard(result: result),

                const SizedBox(height: 16),

                // ── Success probability ──────────────────────────────────
                _ProbabilityCard(probability: result.successProbability,
                    label: result.successLabel),

                const SizedBox(height: 16),

                // ── Score bar chart ──────────────────────────────────────
                Text('Détail par matière',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ScoreBarChart(scores: result.scores),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Analysis text ────────────────────────────────────────
                Text('Analyse', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      result.analysisText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        height: 1.6,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),

                // ── Alternative filières ─────────────────────────────────
                if (result.alternativeFilières.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Alternatives possibles',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.alternativeFilières
                        .map((f) => _FiliereChip(label: f))
                        .toList(),
                  ),
                ],

                // ── Error ────────────────────────────────────────────────
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

                const SizedBox(height: 24),

                // ── Export PDF button ────────────────────────────────────
                AppButton(
                  label: state.isExporting
                      ? 'Export en cours…'
                      : 'Exporter en PDF',
                  prefixIcon: state.isExporting
                      ? null
                      : Icons.picture_as_pdf_rounded,
                  isLoading: state.isExporting,
                  backgroundColor: AppColors.orientation,
                  foregroundColor: Colors.white,
                  onPressed:
                      state.isExporting ? null : notifier.exportPdf,
                ),

                const SizedBox(height: 12),

                // ── New analysis button ──────────────────────────────────
                AppButton(
                  label: 'Nouvelle analyse',
                  prefixIcon: Icons.refresh_rounded,
                  variant: AppButtonVariant.outlined,
                  onPressed: () {
                    notifier.reset();
                    context.go(RouteNames.orientation);
                  },
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FiliereCard extends StatelessWidget {
  final OrientationResultModel result;

  const _FiliereCard({required this.result});

  IconData get _icon {
    final f = result.recommendedFiliere.toLowerCase();
    if (f.contains('scientifique') || f.contains('série c') || f.contains('serie c')) {
      return Icons.science_rounded;
    }
    if (f.contains('littéraire') || f.contains('série a') || f.contains('serie a')) {
      return Icons.menu_book_rounded;
    }
    if (f.contains('technique')) return Icons.build_rounded;
    if (f.contains('série d') || f.contains('serie d')) {
      return Icons.biotech_rounded;
    }
    return Icons.school_rounded;
  }

  String get _examBadge =>
      result.examType == 'BAC' ? 'Baccalauréat' : 'BEPC';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orientation, Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.orientation.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filière recommandée',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.recommendedFiliere,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _InfoChip(
              icon: Icons.verified_rounded,
              label: _examBadge,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: Icons.calendar_today_rounded,
              label: _formatDate(result.createdAt),
            ),
          ]),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.white)),
      ]),
    );
  }
}

class _ProbabilityCard extends StatelessWidget {
  final double probability; // 0.0–1.0
  final String label;

  const _ProbabilityCard({
    required this.probability,
    required this.label,
  });

  Color get _color {
    if (probability >= 0.75) return AppColors.success;
    if (probability >= 0.50) return AppColors.secondary;
    if (probability >= 0.30) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Circular gauge
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _CircleGaugePainter(
                value: probability,
                color: _color,
              ),
              child: Center(
                child: Text(
                  '${(probability * 100).round()}%',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Probabilité de réussite',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    )),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: probability,
                    backgroundColor: AppColors.grey200,
                    color: _color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CircleGaugePainter extends CustomPainter {
  final double value; // 0.0–1.0
  final Color color;

  _CircleGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 6;

    final bgPaint = Paint()
      ..color = AppColors.grey200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * value;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      2 * math.pi,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleGaugePainter old) =>
      old.value != value || old.color != color;
}

class _FiliereChip extends StatelessWidget {
  final String label;

  const _FiliereChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orientation.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.orientation.withOpacity(0.3),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.alt_route_rounded,
            size: 14, color: AppColors.orientation),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.orientation,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}
