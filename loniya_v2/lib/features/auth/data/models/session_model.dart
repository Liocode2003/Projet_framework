import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'session_model.g.dart';

@HiveType(typeId: HiveTypeIds.sessionModel)
class SessionModel extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final String role;
  @HiveField(2) final String createdAt;
  @HiveField(3) final String expiresAt;
  @HiveField(4) final bool pinSet;
  @HiveField(5) final String? deviceId;
  @HiveField(6) final int version;           // for sync conflict resolution

  SessionModel({
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    required this.pinSet,
    this.deviceId,
    this.version = 1,
  });

  bool get isExpired => DateTime.now().isAfter(DateTime.parse(expiresAt));

  factory SessionModel.create({
    required String userId,
    required String role,
    required String deviceId,
    int expiryDays = 30,
  }) {
    final now = DateTime.now();
    return SessionModel(
      userId: userId,
      role: role,
      createdAt: now.toIso8601String(),
      expiresAt: now.add(Duration(days: expiryDays)).toIso8601String(),
      pinSet: false,
      deviceId: deviceId,
      version: 1,
    );
  }

  SessionModel copyWith({bool? pinSet, int? version}) => SessionModel(
        userId: userId,
        role: role,
        createdAt: createdAt,
        expiresAt: expiresAt,
        pinSet: pinSet ?? this.pinSet,
        deviceId: deviceId,
        version: version ?? this.version,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'created_at': createdAt,
        'expires_at': expiresAt,
        'pin_set': pinSet,
        'device_id': deviceId,
        'version': version,
      };
}

class SessionModelAdapter extends TypeAdapter<SessionModel> {
  @override
  final int typeId = HiveTypeIds.sessionModel;

  @override
  SessionModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return SessionModel(
      userId: f[0] as String,
      role: f[1] as String,
      createdAt: f[2] as String,
      expiresAt: f[3] as String,
      pinSet: f[4] as bool,
      deviceId: f[5] as String?,
      version: f[6] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, SessionModel obj) {
    writer.writeMap({
      0: obj.userId,
      1: obj.role,
      2: obj.createdAt,
      3: obj.expiresAt,
      4: obj.pinSet,
      5: obj.deviceId,
      6: obj.version,
    });
  }
}
