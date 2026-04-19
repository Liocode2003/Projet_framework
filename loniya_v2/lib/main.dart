import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/errors/app_error_handler.dart';
import 'core/services/cache/cache_manager_service.dart';
import 'core/services/database/database_service.dart';
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
import 'features/teacher/data/models/subscription_model.dart';
import 'features/teacher/data/models/purchase_model.dart';

Future<void> main() async {
  // ── Error handlers (installed before runApp) ─────────────────────────────
  FlutterError.onError = onFlutterError;
  PlatformDispatcher.instance.onError = onPlatformError;

  WidgetsFlutterBinding.ensureInitialized();

  // ── Device configuration ─────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Storage bootstrap ────────────────────────────────────────────────────
  await Hive.initFlutter();
  _registerHiveAdapters();

  final encryptionService = AesEncryptionService();
  await encryptionService.init();
  await HiveStorageService.openBoxes(encryptionService);

  // ── Startup cache maintenance (non-blocking) ─────────────────────────────
  final db = const DatabaseService();
  CacheManagerService(db).startup().ignore();

  // ── Launch app ───────────────────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        encryptionServiceProvider.overrideWithValue(encryptionService),
      ],
      observers: [LoniyaProviderObserver()],
      child: const LoniyaApp(),
    ),
  );
}

// ─── Hive adapter registration ────────────────────────────────────────────────
void _registerHiveAdapters() {
  void reg<T>(TypeAdapter<T> a) {
    if (!Hive.isAdapterRegistered(a.typeId)) Hive.registerAdapter(a);
  }

  reg(SyncActionModelAdapter());
  reg(SettingsModelAdapter());
  reg(UserModelAdapter());
  reg(SessionModelAdapter());
  reg(StepModelAdapter());     // must precede LessonModel
  reg(LessonModelAdapter());
  reg(ProgressModelAdapter());
  reg(MarketplaceItemModelAdapter());
  reg(GamificationModelAdapter());
  reg(BadgeModelAdapter());
  reg(OrientationResultModelAdapter());
  reg(AiCacheEntryModelAdapter());
  reg(ClassroomModelAdapter());
  reg(SubscriptionModelAdapter());
  reg(PurchaseModelAdapter());
}
