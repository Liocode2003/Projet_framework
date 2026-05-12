import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Thin wrapper around Supabase.
/// Call [initialize] once at startup — it's a no-op when Supabase is not
/// configured (no --dart-define provided).
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabase || _initialized) return;
    await Supabase.initialize(
      url:     AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isAvailable => _initialized && AppConfig.hasSupabase;

  static Session? get currentSession =>
      isAvailable ? client.auth.currentSession : null;

  static User? get currentUser =>
      isAvailable ? client.auth.currentUser : null;

  static String? get currentUserId => currentUser?.id;
}
