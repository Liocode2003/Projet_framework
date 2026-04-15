import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'step_model.g.dart';

/// A single step in an APC lesson flow.
@HiveType(typeId: HiveTypeIds.stepModel)
class StepModel extends HiveObject {
  @HiveField(0) final int index;
  @HiveField(1) final String title;
  @HiveField(2) final String content;        // Rich text / Markdown
  @HiveField(3) final String type;           // read | question | exercise | validation
  @HiveField(4) final String? imagePath;
  @HiveField(5) final String? expectedAnswer; // for auto-validation steps
  @HiveField(6) final List<String> hints;     // AI tutor uses these
  @HiveField(7) final List<String> keywords;  // AI matching tags
  @HiveField(8) final int xpReward;

  StepModel({
    required this.index,
    required this.title,
    required this.content,
    required this.type,
    this.imagePath,
    this.expectedAnswer,
    required this.hints,
    required this.keywords,
    this.xpReward = 10,
  });

  factory StepModel.fromJson(Map<String, dynamic> j) => StepModel(
        index: j['index'] as int? ?? 0,
        title: j['title'] as String,
        content: j['content'] as String,
        type: j['type'] as String? ?? 'read',
        imagePath: j['image_path'] as String?,
        expectedAnswer: j['expected_answer'] as String?,
        hints: List<String>.from(j['hints'] as List? ?? []),
        keywords: List<String>.from(j['keywords'] as List? ?? []),
        xpReward: j['xp_reward'] as int? ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'content': content,
        'type': type,
        'image_path': imagePath,
        'expected_answer': expectedAnswer,
        'hints': hints,
        'keywords': keywords,
        'xp_reward': xpReward,
      };
}

class StepModelAdapter extends TypeAdapter<StepModel> {
  @override
  final int typeId = HiveTypeIds.stepModel;

  @override
  StepModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return StepModel(
      index: f[0] as int,
      title: f[1] as String,
      content: f[2] as String,
      type: f[3] as String,
      imagePath: f[4] as String?,
      expectedAnswer: f[5] as String?,
      hints: List<String>.from(f[6] as List? ?? []),
      keywords: List<String>.from(f[7] as List? ?? []),
      xpReward: f[8] as int? ?? 10,
    );
  }

  @override
  void write(BinaryWriter writer, StepModel obj) {
    writer.writeMap({
      0: obj.index, 1: obj.title, 2: obj.content, 3: obj.type,
      4: obj.imagePath, 5: obj.expectedAnswer,
      6: obj.hints, 7: obj.keywords, 8: obj.xpReward,
    });
  }
}
