import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'orientation_result_model.g.dart';

@HiveType(typeId: HiveTypeIds.orientationResultModel)
class OrientationResultModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final String examType;           // BEPC | BAC
  @HiveField(3) final Map<String, double> scores; // subject → score (0–20)
  @HiveField(4) final String recommendedFiliere;  // Scientifique | Littéraire | Technique…
  @HiveField(5) final List<String> alternativeFilières;
  @HiveField(6) final double successProbability; // 0.0–1.0
  @HiveField(7) final String analysisText;
  @HiveField(8) final String createdAt;
  @HiveField(9) final String? pdfPath;           // exported PDF path

  OrientationResultModel({
    required this.id,
    required this.userId,
    required this.examType,
    required this.scores,
    required this.recommendedFiliere,
    required this.alternativeFilières,
    required this.successProbability,
    required this.analysisText,
    required this.createdAt,
    this.pdfPath,
  });

  double get average =>
      scores.isEmpty ? 0 : scores.values.reduce((a, b) => a + b) / scores.length;

  String get successLabel {
    if (successProbability >= 0.75) return 'Très bonne chance';
    if (successProbability >= 0.50) return 'Bonne chance';
    if (successProbability >= 0.30) return 'Chance modérée';
    return 'Difficile — revoir les fondamentaux';
  }

  factory OrientationResultModel.fromJson(Map<String, dynamic> j) =>
      OrientationResultModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        examType: j['exam_type'] as String,
        scores: Map<String, double>.from(
          (j['scores'] as Map? ?? {}).map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ),
        ),
        recommendedFiliere: j['recommended_filiere'] as String? ?? '',
        alternativeFilières:
            List<String>.from(j['alternative_filieres'] as List? ?? []),
        successProbability:
            (j['success_probability'] as num?)?.toDouble() ?? 0.0,
        analysisText: j['analysis_text'] as String? ?? '',
        createdAt: j['created_at'] as String,
        pdfPath: j['pdf_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'user_id': userId, 'exam_type': examType,
        'scores': scores, 'recommended_filiere': recommendedFiliere,
        'alternative_filieres': alternativeFilières,
        'success_probability': successProbability,
        'analysis_text': analysisText, 'created_at': createdAt, 'pdf_path': pdfPath,
      };
}

class OrientationResultModelAdapter extends TypeAdapter<OrientationResultModel> {
  @override
  final int typeId = HiveTypeIds.orientationResultModel;

  @override
  OrientationResultModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return OrientationResultModel(
      id: f[0] as String, userId: f[1] as String, examType: f[2] as String,
      scores: Map<String, double>.from(f[3] as Map? ?? {}),
      recommendedFiliere: f[4] as String,
      alternativeFilières: List<String>.from(f[5] as List? ?? []),
      successProbability: (f[6] as num?)?.toDouble() ?? 0.0,
      analysisText: f[7] as String,
      createdAt: f[8] as String, pdfPath: f[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrientationResultModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.userId, 2: obj.examType, 3: obj.scores,
      4: obj.recommendedFiliere, 5: obj.alternativeFilières,
      6: obj.successProbability, 7: obj.analysisText,
      8: obj.createdAt, 9: obj.pdfPath,
    });
  }
}
