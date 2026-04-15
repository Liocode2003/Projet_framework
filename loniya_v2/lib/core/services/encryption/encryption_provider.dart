import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aes_encryption_service.dart';

/// Provider — overridden in main.dart with the fully initialized instance.
final encryptionServiceProvider = Provider<AesEncryptionService>(
  (ref) => throw UnimplementedError('Must be overridden in ProviderScope'),
);
