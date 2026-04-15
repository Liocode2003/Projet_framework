import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/storage/hive_storage_service.dart';
import 'core/services/encryption/aes_encryption_service.dart';
import 'core/services/encryption/encryption_provider.dart';

// ─── Hive model imports ───────────────────────────────────────────────────────
import 'core/data/models/sync_action_model.dart';
import 'core/data/models/settings_model.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/data/models/session_model.dart';
import 'features/learning/data/models/progress_model.dart';
import 'features/learning/data/models/lesson_model.dart';
import 'features/learning/data/models/step_model.dart';
import 'features/gamification/data/models/gamification_model.dart';
import 'features/gamification/data/models/badge_model.dart';
import 'features/marketplace/data/models/marketplace_item_model.dart';
import 'features/ai_tutor/data/models/ai_cache_entry_model.dart';
import 'features/local_classroom/data/models/classroom_model.dart';
import 'features/orientation/data/models/orientation_result_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — optimizes low-end rendering
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 1. Initialize Hive
  await Hive.initFlutter();

  // 2. Register all TypeAdapters (order doesn't matter, but IDs must be unique)
  _registerHiveAdapters();

  // 3. Initialize AES-256 encryption (reads/creates key from Android Keystore)
  final encryptionService = AesEncryptionService();
  await encryptionService.init();

  // 4. Open all Hive boxes (encrypted + plain)
  await HiveStorageService.openBoxes(encryptionService);

  // 5. Run the app inside ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        encryptionServiceProvider.overrideWithValue(encryptionService),
      ],
      child: const LoniyaApp(),
    ),
  );
}

/// Registers all 14 Hive TypeAdapters.
/// Must be called before any box is opened.
void _registerHiveAdapters() {
  void register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  // Core models
  register(SyncActionModelAdapter());   // typeId: 5
  register(SettingsModelAdapter());     // typeId: 7

  // Auth models
  register(UserModelAdapter());         // typeId: 0
  register(SessionModelAdapter());      // typeId: 1

  // Learning models
  register(StepModelAdapter());         // typeId: 13  ← must be before LessonModel
  register(LessonModelAdapter());       // typeId: 12
  register(ProgressModelAdapter());     // typeId: 3

  // Marketplace
  register(MarketplaceItemModelAdapter()); // typeId: 11

  // Gamification
  register(GamificationModelAdapter()); // typeId: 4
  register(BadgeModelAdapter());        // typeId: 10

  // Orientation
  register(OrientationResultModelAdapter()); // typeId: 8

  // AI Tutor
  register(AiCacheEntryModelAdapter()); // typeId: 6

  // Classroom
  register(ClassroomModelAdapter());    // typeId: 9
}
