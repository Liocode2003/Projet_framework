import 'package:equatable/equatable.dart';

/// Pure domain entity — no Flutter, no Hive, no JSON dependencies.
class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String role;
  final String? name;
  final String? avatarPath;
  final String pinHash;
  final DateTime createdAt;
  final String? schoolName;
  final String? gradeLevel;
  final bool consentGiven;
  final String? deviceId;

  const UserEntity({
    required this.id,
    required this.phone,
    required this.role,
    this.name,
    this.avatarPath,
    required this.pinHash,
    required this.createdAt,
    this.schoolName,
    this.gradeLevel,
    required this.consentGiven,
    this.deviceId,
  });

  bool get isStudent  => role == 'student';
  bool get isTeacher  => role == 'teacher';
  bool get isParent   => role == 'parent';
  String get displayName => name ?? phone;

  @override
  List<Object?> get props => [id, phone, role];
}
