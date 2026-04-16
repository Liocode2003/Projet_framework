import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../data/datasources/orientation_local_datasource.dart';
import '../../data/models/orientation_result_model.dart';
import '../../data/services/orientation_engine.dart';
import '../../data/services/pdf_export_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────
final orientationLocalDataSourceProvider =
    Provider<OrientationLocalDataSource>(
        (_) => OrientationLocalDataSource());

final orientationEngineProvider =
    Provider<OrientationEngine>((_) => OrientationEngine());

final pdfExportServiceProvider =
    Provider<PdfExportService>((_) => PdfExportService());

// ─── Orientation form state ───────────────────────────────────────────────────
class OrientationFormState {
  final String examType;                    // 'BEPC' | 'BAC'
  final Map<String, double> scores;
  final bool isAnalyzing;
  final bool isExporting;
  final OrientationResultModel? lastResult;
  final String? errorMessage;

  const OrientationFormState({
    this.examType = 'BEPC',
    this.scores = const {},
    this.isAnalyzing = false,
    this.isExporting = false,
    this.lastResult,
    this.errorMessage,
  });

  /// Default score map for the current exam type.
  static Map<String, double> defaultScores(String examType) {
    final subjects = examType == 'BAC'
        ? OrientationEngine.bacSubjects.keys
        : OrientationEngine.bepcSubjects.keys;
    return {for (final s in subjects) s: 10.0};
  }

  bool get hasScores => scores.isNotEmpty;

  OrientationFormState copyWith({
    String? examType,
    Map<String, double>? scores,
    bool? isAnalyzing,
    bool? isExporting,
    OrientationResultModel? lastResult,
    String? errorMessage,
    bool clearError = false,
  }) =>
      OrientationFormState(
        examType:     examType     ?? this.examType,
        scores:       scores       ?? this.scores,
        isAnalyzing:  isAnalyzing  ?? this.isAnalyzing,
        isExporting:  isExporting  ?? this.isExporting,
        lastResult:   lastResult   ?? this.lastResult,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class OrientationNotifier extends StateNotifier<OrientationFormState> {
  final Ref _ref;

  OrientationNotifier(this._ref)
      : super(OrientationFormState(
          scores: OrientationFormState.defaultScores('BEPC'),
        )) {
    _loadLastResult();
  }

  void _loadLastResult() {
    final userId = _ref.read(currentUserProvider)?.id ?? '';
    final last = _ref
        .read(orientationLocalDataSourceProvider)
        .getLastResult(userId);
    if (last != null) state = state.copyWith(lastResult: last);
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  void selectExamType(String type) {
    state = state.copyWith(
      examType: type,
      scores: OrientationFormState.defaultScores(type),
      clearError: true,
    );
  }

  void updateScore(String subject, double score) {
    final updated = Map<String, double>.from(state.scores);
    updated[subject] = score.clamp(0, 20);
    state = state.copyWith(scores: updated);
  }

  Future<OrientationResultModel?> analyze() async {
    state = state.copyWith(isAnalyzing: true, clearError: true);
    try {
      final userId = _ref.read(currentUserProvider)?.id ?? '';
      final user   = _ref.read(currentUserProvider);
      final engine = _ref.read(orientationEngineProvider);
      final ds     = _ref.read(orientationLocalDataSourceProvider);

      final result = engine.analyze(
        userId:   userId,
        examType: state.examType,
        scores:   state.scores,
      );

      await ds.saveResult(result);
      state = state.copyWith(
        isAnalyzing: false,
        lastResult:  result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isAnalyzing:  false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<void> exportPdf() async {
    final result = state.lastResult;
    if (result == null) return;

    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final user    = _ref.read(currentUserProvider);
      final name    = user?.name ?? 'Élève';
      final service = _ref.read(pdfExportServiceProvider);
      final ds      = _ref.read(orientationLocalDataSourceProvider);

      final path = await service.exportReport(
        result: result,
        studentName: name,
      );
      await ds.updatePdfPath(result.id, path);
      await service.sharePdf(path);

      state = state.copyWith(isExporting: false);
    } catch (e) {
      state = state.copyWith(
        isExporting:  false,
        errorMessage: 'Erreur export PDF : ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void reset() {
    state = OrientationFormState(
      scores: OrientationFormState.defaultScores(state.examType),
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final orientationNotifierProvider =
    StateNotifierProvider<OrientationNotifier, OrientationFormState>(
  (ref) => OrientationNotifier(ref),
);

// History of all results for the current user
final orientationHistoryProvider =
    Provider<List<OrientationResultModel>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return ref
      .read(orientationLocalDataSourceProvider)
      .getAllResults(userId);
});
