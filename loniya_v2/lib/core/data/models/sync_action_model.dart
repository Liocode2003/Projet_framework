import 'package:hive/hive.dart';
import '../../constants/hive_boxes.dart';

part 'sync_action_model.g.dart';

/// Represents a single offline action queued for remote sync.
@HiveType(typeId: HiveTypeIds.syncActionModel)
class SyncActionModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String type;        // progress.update | gamification.xp | etc.
  @HiveField(2) final String entityId;   // ID of the entity being synced
  @HiveField(3) final Map<String, dynamic> payload;
  @HiveField(4) final String createdAt;
  @HiveField(5) final int retries;
  @HiveField(6) final String status;     // pending | processing | done | failed
  @HiveField(7) final String? lastError;
  @HiveField(8) final String? processedAt;

  SyncActionModel({
    required this.id,
    required this.type,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retries = 0,
    this.status = 'pending',
    this.lastError,
    this.processedAt,
  });

  bool get isPending   => status == 'pending';
  bool get isFailed    => status == 'failed';
  bool get isDone      => status == 'done';
  bool get canRetry    => retries < 3;

  SyncActionModel incrementRetry(String error) => SyncActionModel(
        id: id, type: type, entityId: entityId, payload: payload,
        createdAt: createdAt, retries: retries + 1,
        status: retries + 1 >= 3 ? 'failed' : 'pending',
        lastError: error,
      );

  SyncActionModel markDone() => SyncActionModel(
        id: id, type: type, entityId: entityId, payload: payload,
        createdAt: createdAt, retries: retries, status: 'done',
        processedAt: DateTime.now().toIso8601String(),
      );
}

class SyncActionModelAdapter extends TypeAdapter<SyncActionModel> {
  @override
  final int typeId = HiveTypeIds.syncActionModel;

  @override
  SyncActionModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return SyncActionModel(
      id: f[0] as String, type: f[1] as String, entityId: f[2] as String,
      payload: Map<String, dynamic>.from(f[3] as Map? ?? {}),
      createdAt: f[4] as String, retries: f[5] as int? ?? 0,
      status: f[6] as String? ?? 'pending',
      lastError: f[7] as String?, processedAt: f[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncActionModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.type, 2: obj.entityId, 3: obj.payload,
      4: obj.createdAt, 5: obj.retries, 6: obj.status,
      7: obj.lastError, 8: obj.processedAt,
    });
  }
}
