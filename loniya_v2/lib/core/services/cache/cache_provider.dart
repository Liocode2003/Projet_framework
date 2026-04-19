import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_service.dart';
import 'cache_manager_service.dart';

final cacheManagerProvider = Provider<CacheManagerService>((ref) {
  return CacheManagerService(ref.read(databaseServiceProvider));
});

/// Async provider — fetches storage usage report on demand.
final storageReportProvider =
    FutureProvider.autoDispose<StorageReport>((ref) async {
  return ref.read(cacheManagerProvider).storageReport();
});
