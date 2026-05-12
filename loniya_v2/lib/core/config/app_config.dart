/// Build-time configuration injected via --dart-define.
///
/// Build commands:
///   flutter run  --dart-define=GROQ_KEY=gsk_... --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
///   flutter build apk --dart-define=GROQ_KEY=gsk_... ...
///
/// The key is never stored in source code — it lives only in the compiled
/// binary and in the device Keychain (SecureKeyService).
class AppConfig {
  AppConfig._();

  // ── Groq ────────────────────────────────────────────────────────────────────
  static const groqApiKey =
      String.fromEnvironment('GROQ_KEY', defaultValue: '');

  static bool get hasGroqKey => groqApiKey.isNotEmpty;

  // ── Supabase ────────────────────────────────────────────────────────────────
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── Environment ─────────────────────────────────────────────────────────────
  static const _env =
      String.fromEnvironment('APP_ENV', defaultValue: 'production');
  static bool get isDemoMode => _env == 'demo';
}
