import 'package:hive/hive.dart';

part 'homework_model.g.dart';

enum HomeworkStatus { pending, inProgress, done }

@HiveType(typeId: 22)
class HomeworkModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String studentId;
  @HiveField(2)  final String teacherId;
  @HiveField(3)  final String classCode;
  @HiveField(4)  final String title;
  @HiveField(5)  final String subject;
  @HiveField(6)  final String deadline;     // ISO date
  @HiveField(7)  final int    durationMin;  // durée estimée en minutes
  @HiveField(8)  final String courseId;     // cours associé (peut être vide)
  @HiveField(9)  final String status;       // pending | inProgress | done
  @HiveField(10) final int?   score;        // score obtenu si done
  @HiveField(11) final String assignedAt;

  const HomeworkModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.classCode,
    required this.title,
    required this.subject,
    required this.deadline,
    this.durationMin = 30,
    this.courseId    = '',
    this.status      = 'pending',
    this.score,
    required this.assignedAt,
  });

  bool get isUrgent {
    final d = DateTime.tryParse(deadline);
    if (d == null) return false;
    return d.difference(DateTime.now()).inHours < 24 && status != 'done';
  }

  bool get isDone => status == 'done';

  HomeworkModel copyWith({
    String? status, int? score,
  }) =>
      HomeworkModel(
        id: id, studentId: studentId, teacherId: teacherId,
        classCode: classCode, title: title, subject: subject,
        deadline: deadline, durationMin: durationMin, courseId: courseId,
        status:     status ?? this.status,
        score:      score  ?? this.score,
        assignedAt: assignedAt,
      );
}
