import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool isListening = false;

  Future<bool> init() async {
    return await _speech.initialize();
  }

  Future<void> startListening(Function(String) onResult) async {
    bool available = await _speech.initialize();

    if (available) {
      isListening = true;

      _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    isListening = false;
  }
}