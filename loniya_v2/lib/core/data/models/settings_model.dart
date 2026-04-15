import 'package:hive/hive.dart';
import '../../constants/hive_boxes.dart';

part 'settings_model.g.dart';

@HiveType(typeId: HiveTypeIds.settingsModel)
class SettingsModel extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final String language;        // fr | bm
  @HiveField(2) final bool ttsEnabled;
  @HiveField(3) final double ttsSpeed;        // 0.5–2.0
  @HiveField(4) final bool notificationsEnabled;
  @HiveField(5) final bool darkMode;
  @HiveField(6) final bool onboardingDone;
  @HiveField(7) final bool offlineWarningShown;
  @HiveField(8) final int maxStorageMb;       // user-set download limit
  @HiveField(9) final String? selectedGrade;

  SettingsModel({
    required this.userId,
    this.language = 'fr',
    this.ttsEnabled = false,
    this.ttsSpeed = 1.0,
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.onboardingDone = false,
    this.offlineWarningShown = false,
    this.maxStorageMb = 500,
    this.selectedGrade,
  });

  factory SettingsModel.defaults(String userId) => SettingsModel(userId: userId);

  SettingsModel copyWith({
    String? language, bool? ttsEnabled, double? ttsSpeed,
    bool? notificationsEnabled, bool? darkMode, bool? onboardingDone,
    bool? offlineWarningShown, int? maxStorageMb, String? selectedGrade,
  }) =>
      SettingsModel(
        userId: userId,
        language: language ?? this.language,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        ttsSpeed: ttsSpeed ?? this.ttsSpeed,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        darkMode: darkMode ?? this.darkMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        offlineWarningShown: offlineWarningShown ?? this.offlineWarningShown,
        maxStorageMb: maxStorageMb ?? this.maxStorageMb,
        selectedGrade: selectedGrade ?? this.selectedGrade,
      );
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = HiveTypeIds.settingsModel;

  @override
  SettingsModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return SettingsModel(
      userId: f[0] as String, language: f[1] as String? ?? 'fr',
      ttsEnabled: f[2] as bool? ?? false,
      ttsSpeed: (f[3] as num?)?.toDouble() ?? 1.0,
      notificationsEnabled: f[4] as bool? ?? true,
      darkMode: f[5] as bool? ?? false,
      onboardingDone: f[6] as bool? ?? false,
      offlineWarningShown: f[7] as bool? ?? false,
      maxStorageMb: f[8] as int? ?? 500,
      selectedGrade: f[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer.writeMap({
      0: obj.userId, 1: obj.language, 2: obj.ttsEnabled, 3: obj.ttsSpeed,
      4: obj.notificationsEnabled, 5: obj.darkMode, 6: obj.onboardingDone,
      7: obj.offlineWarningShown, 8: obj.maxStorageMb, 9: obj.selectedGrade,
    });
  }
}
