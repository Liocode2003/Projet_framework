import 'package:hive/hive.dart';

part 'exam_mode_model.g.dart';

@HiveType(typeId: 21)
class ExamModeModel extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final bool   active;
  @HiveField(2) final String startDate;   // ISO date
  @HiveField(3) final String endDate;     // ISO date
  @HiveField(4) final List<String> subjects;
  @HiveField(5) final bool parentNotified;

  const ExamModeModel({
    required this.userId,
    this.active          = false,
    this.startDate       = '',
    this.endDate         = '',
    this.subjects        = const [],
    this.parentNotified  = false,
  });

  bool get isExpired {
    if (!active || endDate.isEmpty) return false;
    final end = DateTime.tryParse(endDate);
    return end != null && DateTime.now().isAfter(end);
  }

  ExamModeModel copyWith({
    bool? active, String? startDate, String? endDate,
    List<String>? subjects, bool? parentNotified,
  }) =>
      ExamModeModel(
        userId:          userId,
        active:          active          ?? this.active,
        startDate:       startDate       ?? this.startDate,
        endDate:         endDate         ?? this.endDate,
        subjects:        subjects        ?? this.subjects,
        parentNotified:  parentNotified  ?? this.parentNotified,
      );
}
