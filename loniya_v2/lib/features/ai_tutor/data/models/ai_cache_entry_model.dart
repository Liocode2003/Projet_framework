import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'ai_cache_entry_model.g.dart';

@HiveType(typeId: HiveTypeIds.aiCacheEntryModel)
class AiCacheEntryModel extends HiveObject {
  @HiveField(0) final String queryHash;  // sha256(userId + stepId + question)
  @HiveField(1) final String question;
  @HiveField(2) final String response;
  @HiveField(3) final String stepId;
  @HiveField(4) final String createdAt;
  @HiveField(5) final int hitCount;      // how many times this cache was served

  AiCacheEntryModel({
    required this.queryHash,
    required this.question,
    required this.response,
    required this.stepId,
    required this.createdAt,
    this.hitCount = 0,
  });

  bool isExpired(int maxAgeHours) {
    final created = DateTime.parse(createdAt);
    return DateTime.now().difference(created).inHours > maxAgeHours;
  }

  AiCacheEntryModel incrementHit() => AiCacheEntryModel(
        queryHash: queryHash, question: question, response: response,
        stepId: stepId, createdAt: createdAt, hitCount: hitCount + 1,
      );
}

class AiCacheEntryModelAdapter extends TypeAdapter<AiCacheEntryModel> {
  @override
  final int typeId = HiveTypeIds.aiCacheEntryModel;

  @override
  AiCacheEntryModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return AiCacheEntryModel(
      queryHash: f[0] as String, question: f[1] as String,
      response: f[2] as String, stepId: f[3] as String,
      createdAt: f[4] as String, hitCount: f[5] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AiCacheEntryModel obj) {
    writer.writeMap({
      0: obj.queryHash, 1: obj.question, 2: obj.response,
      3: obj.stepId, 4: obj.createdAt, 5: obj.hitCount,
    });
  }
}
