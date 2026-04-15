import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/services/connectivity/connectivity_service.dart';

/// Provides offline status — watched by AppShell for the banner.
/// Derives from the ConnectivityService stream (inverted: offline = !online).
final offlineStatusProvider = Provider<bool>((ref) {
  final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
  return !online;
});

/// Provides current user role — determines which nav items to show
final userRoleProvider = Provider<String?>((ref) {
  try {
    final box = Hive.box(HiveBoxes.sessions);
    if (box.isEmpty) return null;
    final session = box.get('current');
    return session?['role'] as String?;
  } catch (_) {
    return null;
  }
});
