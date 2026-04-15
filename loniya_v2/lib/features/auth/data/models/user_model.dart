import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveTypeIds.userModel)
class UserModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String phone;
  @HiveField(2) final String role;           // student | teacher | parent
  @HiveField(3) final String? name;
  @HiveField(4) final String? avatarPath;
  @HiveField(5) final String pinHash;
  @HiveField(6) final String createdAt;
  @HiveField(7) final String? schoolName;
  @HiveField(8) final String? gradeLevel;    // CM2, 6ème, 3ème, Terminale…
  @HiveField(9) final bool consentGiven;
  @HiveField(10) final String? deviceId;

  UserModel({
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

  factory UserModel.fromEntity(UserEntity e) => UserModel(
        id: e.id,
        phone: e.phone,
        role: e.role,
        name: e.name,
        avatarPath: e.avatarPath,
        pinHash: e.pinHash,
        createdAt: e.createdAt.toIso8601String(),
        schoolName: e.schoolName,
        gradeLevel: e.gradeLevel,
        consentGiven: e.consentGiven,
        deviceId: e.deviceId,
      );

  UserEntity toEntity() => UserEntity(
        id: id,
        phone: phone,
        role: role,
        name: name,
        avatarPath: avatarPath,
        pinHash: pinHash,
        createdAt: DateTime.parse(createdAt),
        schoolName: schoolName,
        gradeLevel: gradeLevel,
        consentGiven: consentGiven,
        deviceId: deviceId,
      );

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String,
        name: j['name'] as String?,
        avatarPath: j['avatar_path'] as String?,
        pinHash: j['pin_hash'] as String? ?? '',
        createdAt: j['created_at'] as String,
        schoolName: j['school_name'] as String?,
        gradeLevel: j['grade_level'] as String?,
        consentGiven: j['consent_given'] as bool? ?? false,
        deviceId: j['device_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'role': role,
        'name': name,
        'avatar_path': avatarPath,
        'pin_hash': pinHash,
        'created_at': createdAt,
        'school_name': schoolName,
        'grade_level': gradeLevel,
        'consent_given': consentGiven,
        'device_id': deviceId,
      };

  UserModel copyWith({
    String? name,
    String? avatarPath,
    String? schoolName,
    String? gradeLevel,
    String? pinHash,
  }) =>
      UserModel(
        id: id,
        phone: phone,
        role: role,
        name: name ?? this.name,
        avatarPath: avatarPath ?? this.avatarPath,
        pinHash: pinHash ?? this.pinHash,
        createdAt: createdAt,
        schoolName: schoolName ?? this.schoolName,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        consentGiven: consentGiven,
        deviceId: deviceId,
      );
}

// ─── Manual TypeAdapter (replaces build_runner output) ───────────────────────
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = HiveTypeIds.userModel;

  @override
  UserModel read(BinaryReader reader) {
    final fields = reader.readMap().cast<int, dynamic>();
    return UserModel(
      id: fields[0] as String,
      phone: fields[1] as String,
      role: fields[2] as String,
      name: fields[3] as String?,
      avatarPath: fields[4] as String?,
      pinHash: fields[5] as String,
      createdAt: fields[6] as String,
      schoolName: fields[7] as String?,
      gradeLevel: fields[8] as String?,
      consentGiven: fields[9] as bool,
      deviceId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.phone,
      2: obj.role,
      3: obj.name,
      4: obj.avatarPath,
      5: obj.pinHash,
      6: obj.createdAt,
      7: obj.schoolName,
      8: obj.gradeLevel,
      9: obj.consentGiven,
      10: obj.deviceId,
    });
  }
}
