import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    // Helps with stability on Android
    if (Platform.isAndroid) {
      await _tts.setSilence(500);
    }
  }

  Future<void> speak(String text, {bool isEmotional = false}) async {
    // 1. Force stop anything currently playing
    await _tts.stop();

    // 2. Set parameters
    if (isEmotional) {
      await _tts.setSpeechRate(0.38); // Slightly faster than 0.35 for better flow
      await _tts.setPitch(0.9);
    } else {
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    }

    // 3. THE FIX: Tiny delay (100-300ms)
    // This prevents the "clipping" of the first word
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Speak
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}