import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../models/orientation_result_model.dart';

class OrientationLocalDataSource {
  OrientationResultModel? getLastResult(String userId) {
    final box = Hive.box(HiveBoxes.orientation);
    final all = box.values
        .cast<OrientationResultModel>()
        .where((r) => r.userId == userId)
        .toList();
    if (all.isEmpty) return null;
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.first;
  }

  List<OrientationResultModel> getAllResults(String userId) {
    return Hive.box(HiveBoxes.orientation)
        .values
        .cast<OrientationResultModel>()
        .where((r) => r.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveResult(OrientationResultModel result) async {
    await Hive.box(HiveBoxes.orientation).put(result.id, result);
  }

  Future<void> updatePdfPath(String resultId, String pdfPath) async {
    final box = Hive.box(HiveBoxes.orientation);
    final existing = box.get(resultId) as OrientationResultModel?;
    if (existing == null) return;
    final updated = OrientationResultModel(
      id: existing.id,
      userId: existing.userId,
      examType: existing.examType,
      scores: existing.scores,
      recommendedFiliere: existing.recommendedFiliere,
      alternativeFilières: existing.alternativeFilières,
      successProbability: existing.successProbability,
      analysisText: existing.analysisText,
      createdAt: existing.createdAt,
      pdfPath: pdfPath,
    );
    await box.put(resultId, updated);
  }
}
