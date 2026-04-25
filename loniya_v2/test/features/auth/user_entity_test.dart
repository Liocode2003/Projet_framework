import 'package:flutter_test/flutter_test.dart';
import 'package:loniya_v2/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    late UserEntity student;
    late UserEntity teacher;
    late UserEntity parent;

    setUp(() {
      student = UserEntity(
        id: 'u1', phone: '70000001', role: 'student',
        name: 'Kofi', pinHash: 'hash', createdAt: DateTime(2024),
        consentGiven: true,
      );
      teacher = student.copyWith(role: 'teacher', name: null);
      parent  = student.copyWith(role: 'parent');
    });

    test('isStudent is true only for student role', () {
      expect(student.isStudent, isTrue);
      expect(teacher.isStudent, isFalse);
      expect(parent.isStudent,  isFalse);
    });

    test('isTeacher is true only for teacher role', () {
      expect(teacher.isTeacher, isTrue);
      expect(student.isTeacher, isFalse);
    });

    test('isParent is true only for parent role', () {
      expect(parent.isParent, isTrue);
      expect(student.isParent, isFalse);
    });

    test('displayName returns name when set', () {
      expect(student.displayName, 'Kofi');
    });

    test('displayName falls back to phone when name is null', () {
      expect(teacher.displayName, '70000001');
    });

    test('equality based on id, phone, role only', () {
      final copy = UserEntity(
        id: 'u1', phone: '70000001', role: 'student',
        name: 'Different Name',          // ignored in ==
        pinHash: 'hash', createdAt: DateTime(2024), consentGiven: true,
      );
      expect(student, equals(copy));
    });
  });
}

extension on UserEntity {
  UserEntity copyWith({String? role, String? name}) => UserEntity(
    id: id, phone: phone,
    role:         role ?? this.role,
    name:         name,
    pinHash:      pinHash,
    createdAt:    createdAt,
    consentGiven: consentGiven,
  );
}
