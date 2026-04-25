import 'package:flutter_test/flutter_test.dart';
import 'package:loniya_v2/features/homework/data/models/homework_model.dart';

HomeworkModel _hw({
  String status   = 'pending',
  String deadline = '',
  int?   score,
}) =>
    HomeworkModel(
      id: 'hw1', studentId: 'u1', teacherId: 't1', classCode: 'CL-001',
      title: 'Test HW', subject: 'Maths',
      deadline:   deadline.isEmpty
          ? DateTime.now().add(const Duration(hours: 12)).toIso8601String()
          : deadline,
      durationMin: 30,
      status:      status,
      score:       score,
      assignedAt:  DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    );

void main() {
  group('HomeworkModel', () {
    test('isDone is true only when status is "done"', () {
      expect(_hw(status: 'done').isDone,       isTrue);
      expect(_hw(status: 'pending').isDone,    isFalse);
      expect(_hw(status: 'inProgress').isDone, isFalse);
    });

    test('isUrgent is true when deadline < 24h and not done', () {
      final urgent = _hw(
        deadline: DateTime.now().add(const Duration(hours: 10)).toIso8601String(),
      );
      expect(urgent.isUrgent, isTrue);
    });

    test('isUrgent is false when done, even if deadline passed', () {
      final done = _hw(
        status: 'done',
        deadline: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      );
      expect(done.isUrgent, isFalse);
    });

    test('isUrgent is false when deadline > 24h away', () {
      final farAway = _hw(
        deadline: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      );
      expect(farAway.isUrgent, isFalse);
    });

    test('copyWith only updates specified fields', () {
      final original = _hw(status: 'pending');
      final updated  = original.copyWith(status: 'done', score: 18);
      expect(updated.status, 'done');
      expect(updated.score, 18);
      expect(updated.title, original.title);   // unchanged
      expect(updated.subject, original.subject); // unchanged
    });

    test('copyWith without args preserves all fields', () {
      final original = _hw(status: 'inProgress', score: 12);
      final copy     = original.copyWith();
      expect(copy.status, original.status);
      expect(copy.score,  original.score);
    });
  });
}
