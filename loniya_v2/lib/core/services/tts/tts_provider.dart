import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

/// Tracks whether TTS is currently active.
final ttsEnabledProvider = StateProvider<bool>((ref) => false);
