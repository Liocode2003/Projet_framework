import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'badge_model.g.dart';

@HiveType(typeId: HiveTypeIds.badgeModel)
class BadgeModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String description;
  @HiveField(3) final String iconAsset;
  @HiveField(4) final String category;    // streak | subject | milestone | special
  @HiveField(5) final int xpReward;
  @HiveField(6) final String condition;   // human-readable trigger condition
  @HiveField(7) final String? unlockedAt; // null = locked

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.category,
    required this.xpReward,
    required this.condition,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        iconAsset: j['icon_asset'] as String? ?? 'assets/icons/badge_default.svg',
        category: j['category'] as String? ?? 'milestone',
        xpReward: j['xp_reward'] as int? ?? 0,
        condition: j['condition'] as String? ?? '',
        unlockedAt: j['unlocked_at'] as String?,
      );

  BadgeModel unlock() => BadgeModel(
        id: id, title: title, description: description,
        iconAsset: iconAsset, category: category, xpReward: xpReward,
        condition: condition, unlockedAt: DateTime.now().toIso8601String(),
      );
}

class BadgeModelAdapter extends TypeAdapter<BadgeModel> {
  @override
  final int typeId = HiveTypeIds.badgeModel;

  @override
  BadgeModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return BadgeModel(
      id: f[0] as String, title: f[1] as String, description: f[2] as String,
      iconAsset: f[3] as String, category: f[4] as String,
      xpReward: f[5] as int, condition: f[6] as String,
      unlockedAt: f[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BadgeModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.title, 2: obj.description, 3: obj.iconAsset,
      4: obj.category, 5: obj.xpReward, 6: obj.condition, 7: obj.unlockedAt,
    });
  }
}
