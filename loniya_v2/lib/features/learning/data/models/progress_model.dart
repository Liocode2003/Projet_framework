import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'progress_model.g.dart';

@HiveType(typeId: HiveTypeIds.progressModel)
class ProgressModel extends HiveObject {
  @HiveField(0)  final String id;             // userId_lessonId
  @HiveField(1)  final String userId;
  @HiveField(2)  final String lessonId;
  @HiveField(3)  final int currentStepIndex;
  @HiveField(4)  final bool isCompleted;
  @HiveField(5)  final int score;             // 0–100
  @HiveField(6)  final int xpEarned;
  @HiveField(7)  final String startedAt;
  @HiveField(8)  final String? completedAt;
  @HiveField(9)  final List<int> completedSteps;
  @HiveField(10) final int attempts;
  @HiveField(11) final bool syncPending;      // needs sync to remote
  @HiveField(12) final int version;

  ProgressModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.currentStepIndex,
    required this.isCompleted,
    required this.score,
    required this.xpEarned,
    required this.startedAt,
    this.completedAt,
    required this.completedSteps,
    required this.attempts,
    this.syncPending = true,
    this.version = 1,
  });

  double get progressPercent =>
      completedSteps.isEmpty ? 0 : completedSteps.length / (currentStepIndex + 1);

  factory ProgressModel.start({
    required String userId,
    required String lessonId,
  }) =>
      ProgressModel(
        id: '${userId}_$lessonId',
        userId: userId,
        lessonId: lessonId,
        currentStepIndex: 0,
        isCompleted: false,
        score: 0,
        xpEarned: 0,
        startedAt: DateTime.now().toIso8601String(),
        completedSteps: [],
        attempts: 1,
        syncPending: true,
        version: 1,
      );

  ProgressModel copyWith({
    int? currentStepIndex,
    bool? isCompleted,
    int? score,
    int? xpEarned,
    String? completedAt,
    List<int>? completedSteps,
    bool? syncPending,
    int? version,
  }) =>
      ProgressModel(
        id: id, userId: userId, lessonId: lessonId,
        startedAt: startedAt, attempts: attempts,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        isCompleted: isCompleted ?? this.isCompleted,
        score: score ?? this.score,
        xpEarned: xpEarned ?? this.xpEarned,
        completedAt: completedAt ?? this.completedAt,
        completedSteps: completedSteps ?? this.completedSteps,
        syncPending: syncPending ?? this.syncPending,
        version: version ?? this.version,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'user_id': userId, 'lesson_id': lessonId,
        'current_step_index': currentStepIndex, 'is_completed': isCompleted,
        'score': score, 'xp_earned': xpEarned,
        'started_at': startedAt, 'completed_at': completedAt,
        'completed_steps': completedSteps, 'attempts': attempts, 'version': version,
      };
}

class ProgressModelAdapter extends TypeAdapter<ProgressModel> {
  @override
  final int typeId = HiveTypeIds.progressModel;

  @override
  ProgressModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return ProgressModel(
      id: f[0] as String, userId: f[1] as String, lessonId: f[2] as String,
      currentStepIndex: f[3] as int, isCompleted: f[4] as bool,
      score: f[5] as int, xpEarned: f[6] as int,
      startedAt: f[7] as String, completedAt: f[8] as String?,
      completedSteps: List<int>.from(f[9] as List? ?? []),
      attempts: f[10] as int, syncPending: f[11] as bool? ?? true,
      version: f[12] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.userId, 2: obj.lessonId,
      3: obj.currentStepIndex, 4: obj.isCompleted,
      5: obj.score, 6: obj.xpEarned, 7: obj.startedAt,
      8: obj.completedAt, 9: obj.completedSteps,
      10: obj.attempts, 11: obj.syncPending, 12: obj.version,
    });
  }
}
