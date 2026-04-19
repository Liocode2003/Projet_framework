import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/models/settings_model.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final DatabaseService _db;
  final String _userId;

  SettingsNotifier(this._db, this._userId)
      : super(SettingsModel.defaults(_userId)) {
    state = _db.getSettings(_userId);
  }

  Future<void> _save(SettingsModel updated) async {
    await _db.saveSettings(updated);
    state = updated;
  }

  Future<void> toggleDarkMode() =>
      _save(state.copyWith(darkMode: !state.darkMode));

  Future<void> toggleHighContrast() =>
      _save(state.copyWith(isHighContrast: !state.isHighContrast));

  Future<void> toggleLargeText() =>
      _save(state.copyWith(isLargeText: !state.isLargeText));

  Future<void> toggleVoiceReading() =>
      _save(state.copyWith(voiceReadingEnabled: !state.voiceReadingEnabled));

  Future<void> toggleTts() =>
      _save(state.copyWith(ttsEnabled: !state.ttsEnabled));

  Future<void> setTtsSpeed(double speed) =>
      _save(state.copyWith(ttsSpeed: speed.clamp(0.5, 2.0)));

  Future<void> setLanguage(String lang) =>
      _save(state.copyWith(language: lang));

  Future<void> setMaxStorageMb(int mb) =>
      _save(state.copyWith(maxStorageMb: mb));
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final userId = ref.watch(authNotifierProvider).userId ?? '';
  return SettingsNotifier(ref.read(databaseServiceProvider), userId);
});

/// Convenience — readable alias used in app.dart
final currentSettingsProvider = Provider<SettingsModel>((ref) {
  return ref.watch(settingsNotifierProvider);
});
