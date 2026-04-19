import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _enabled = false;

  Future<void> init() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) _tts.stop();
  }

  Future<void> speak(String text) async {
    if (!_enabled || text.isEmpty) return;
    await _tts.stop();
    // Strip markdown bold/italic markers before speaking
    final clean = text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'#+\s?'), '');
    await _tts.speak(clean);
  }

  Future<void> stop() async => _tts.stop();

  void dispose() => _tts.stop();
}
