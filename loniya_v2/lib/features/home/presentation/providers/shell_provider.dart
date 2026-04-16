import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// Offline status — watched by AppShell for the banner.
final offlineStatusProvider = Provider<bool>((ref) {
  final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
  return !online;
});

/// Current user role — determines which nav items to show.
/// Delegates to the auth notifier (single source of truth).
final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(currentUserRoleProvider);
});
