import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'classroom_model.g.dart';

@HiveType(typeId: HiveTypeIds.classroomModel)
class ClassroomModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String teacherId;
  @HiveField(2) final String name;
  @HiveField(3) final String sessionCode;     // 6-char code students use to join
  @HiveField(4) final List<String> studentIds;
  @HiveField(5) final List<String> sharedContentIds;
  @HiveField(6) final String? serverHost;     // teacher's LAN IP
  @HiveField(7) final int? serverPort;
  @HiveField(8) final bool isActive;
  @HiveField(9) final String createdAt;
  @HiveField(10) final String? endedAt;

  ClassroomModel({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.sessionCode,
    required this.studentIds,
    required this.sharedContentIds,
    this.serverHost,
    this.serverPort,
    required this.isActive,
    required this.createdAt,
    this.endedAt,
  });

  factory ClassroomModel.create({
    required String teacherId,
    required String name,
  }) {
    final code = _generateCode();
    return ClassroomModel(
      id: '${teacherId}_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: teacherId,
      name: name,
      sessionCode: code,
      studentIds: [],
      sharedContentIds: [],
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buf = StringBuffer();
    for (int i = 0; i < 6; i++) {
      buf.write(chars[(DateTime.now().microsecond + i * 7) % chars.length]);
    }
    return buf.toString();
  }

  ClassroomModel copyWith({
    List<String>? studentIds,
    List<String>? sharedContentIds,
    String? serverHost,
    int? serverPort,
    bool? isActive,
    String? endedAt,
  }) =>
      ClassroomModel(
        id: id, teacherId: teacherId, name: name, sessionCode: sessionCode,
        createdAt: createdAt,
        studentIds: studentIds ?? this.studentIds,
        sharedContentIds: sharedContentIds ?? this.sharedContentIds,
        serverHost: serverHost ?? this.serverHost,
        serverPort: serverPort ?? this.serverPort,
        isActive: isActive ?? this.isActive,
        endedAt: endedAt ?? this.endedAt,
      );
}

class ClassroomModelAdapter extends TypeAdapter<ClassroomModel> {
  @override
  final int typeId = HiveTypeIds.classroomModel;

  @override
  ClassroomModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return ClassroomModel(
      id: f[0] as String, teacherId: f[1] as String, name: f[2] as String,
      sessionCode: f[3] as String,
      studentIds: List<String>.from(f[4] as List? ?? []),
      sharedContentIds: List<String>.from(f[5] as List? ?? []),
      serverHost: f[6] as String?, serverPort: f[7] as int?,
      isActive: f[8] as bool, createdAt: f[9] as String, endedAt: f[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassroomModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.teacherId, 2: obj.name, 3: obj.sessionCode,
      4: obj.studentIds, 5: obj.sharedContentIds,
      6: obj.serverHost, 7: obj.serverPort,
      8: obj.isActive, 9: obj.createdAt, 10: obj.endedAt,
    });
  }
}
