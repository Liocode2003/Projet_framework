import 'package:flutter_test/flutter_test.dart';
import 'package:loniya_v2/core/config/app_config.dart';

void main() {
  // In tests (no --dart-define), all fromEnvironment values use defaults.
  group('AppConfig defaults (no --dart-define)', () {
    test('groqApiKey is empty by default', () {
      expect(AppConfig.groqApiKey, isEmpty);
    });

    test('hasGroqKey is false when groqApiKey is empty', () {
      expect(AppConfig.hasGroqKey, isFalse);
    });

    test('supabaseUrl is empty by default', () {
      expect(AppConfig.supabaseUrl, isEmpty);
    });

    test('supabaseAnonKey is empty by default', () {
      expect(AppConfig.supabaseAnonKey, isEmpty);
    });

    test('hasSupabase is false when either URL or key is empty', () {
      expect(AppConfig.hasSupabase, isFalse);
    });

    test('isDemoMode is false by default (APP_ENV defaults to production)', () {
      expect(AppConfig.isDemoMode, isFalse);
    });
  });

  group('AppConfig logic invariants', () {
    test('hasGroqKey reflects groqApiKey non-emptiness', () {
      // groqApiKey is a const — we verify the getter logic is correct by
      // checking the relationship: hasGroqKey ↔ groqApiKey.isNotEmpty
      expect(AppConfig.hasGroqKey, AppConfig.groqApiKey.isNotEmpty);
    });

    test('hasSupabase requires both URL and anon key', () {
      expect(
        AppConfig.hasSupabase,
        AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty,
      );
    });
  });
}
