import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'core/services/storage/hive_storage_service.dart';
import 'core/services/encryption/aes_encryption_service.dart';
import 'core/services/encryption/encryption_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for low-end device optimization
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register all Hive adapters
  _registerHiveAdapters();

  // Initialize encryption key (stored securely in Android Keystore)
  final encryptionService = AesEncryptionService();
  await encryptionService.init();

  // Open all Hive boxes (non-encrypted)
  await HiveStorageService.openBoxes(encryptionService);

  runApp(
    // ProviderScope wraps the entire app — makes Riverpod available everywhere
    ProviderScope(
      overrides: [
        // Override encryptionServiceProvider with initialized instance
        encryptionServiceProvider.overrideWithValue(encryptionService),
      ],
      child: const LoniyaApp(),
    ),
  );
}

/// Register all Hive type adapters here.
/// Adapters are generated via build_runner + hive_generator.
void _registerHiveAdapters() {
  // Adapters will be registered here as models are created in subsequent phases.
  // Example (to be uncommented when models are generated):
  // if (!Hive.isAdapterRegistered(HiveTypeIds.userModel)) {
  //   Hive.registerAdapter(UserModelAdapter());
  // }
}
