import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import 'step_model.dart';

part 'lesson_model.g.dart';

@HiveType(typeId: HiveTypeIds.lessonModel)
class LessonModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String title;
  @HiveField(2)  final String subject;
  @HiveField(3)  final String gradeLevel;
  @HiveField(4)  final String situation;     // APC: situation de départ
  @HiveField(5)  final List<StepModel> steps;
  @HiveField(6)  final String contentItemId; // FK to MarketplaceItemModel
  @HiveField(7)  final int estimatedMinutes;
  @HiveField(8)  final List<String> competencies; // APC competencies targeted
  @HiveField(9)  final String? audioPath;    // TTS pre-recorded audio
  @HiveField(10) final List<String> tags;
  @HiveField(11) final String createdAt;

  LessonModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.situation,
    required this.steps,
    required this.contentItemId,
    required this.estimatedMinutes,
    required this.competencies,
    this.audioPath,
    required this.tags,
    required this.createdAt,
  });

  int get totalSteps => steps.length;

  factory LessonModel.fromJson(Map<String, dynamic> j) => LessonModel(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String,
        gradeLevel: j['grade_level'] as String,
        situation: j['situation'] as String? ?? '',
        steps: (j['steps'] as List? ?? [])
            .map((s) => StepModel.fromJson(s as Map<String, dynamic>))
            .toList(),
        contentItemId: j['content_item_id'] as String? ?? '',
        estimatedMinutes: j['estimated_minutes'] as int? ?? 30,
        competencies: List<String>.from(j['competencies'] as List? ?? []),
        audioPath: j['audio_path'] as String?,
        tags: List<String>.from(j['tags'] as List? ?? []),
        createdAt: j['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'grade_level': gradeLevel,
        'situation': situation,
        'steps': steps.map((s) => s.toJson()).toList(),
        'content_item_id': contentItemId,
        'estimated_minutes': estimatedMinutes,
        'competencies': competencies,
        'audio_path': audioPath,
        'tags': tags,
        'created_at': createdAt,
      };
}

class LessonModelAdapter extends TypeAdapter<LessonModel> {
  @override
  final int typeId = HiveTypeIds.lessonModel;

  @override
  LessonModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return LessonModel(
      id: f[0] as String,
      title: f[1] as String,
      subject: f[2] as String,
      gradeLevel: f[3] as String,
      situation: f[4] as String,
      steps: (f[5] as List? ?? []).cast<StepModel>(),
      contentItemId: f[6] as String,
      estimatedMinutes: f[7] as int,
      competencies: List<String>.from(f[8] as List? ?? []),
      audioPath: f[9] as String?,
      tags: List<String>.from(f[10] as List? ?? []),
      createdAt: f[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LessonModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.title, 2: obj.subject, 3: obj.gradeLevel,
      4: obj.situation, 5: obj.steps, 6: obj.contentItemId,
      7: obj.estimatedMinutes, 8: obj.competencies,
      9: obj.audioPath, 10: obj.tags, 11: obj.createdAt,
    });
  }
}
