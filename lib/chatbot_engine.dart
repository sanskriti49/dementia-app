import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotEngine {
  final EntityExtractor _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);

  Future<String> getLocalNLUContext(String text) async {
    try {
      final List<EntityAnnotation> annotations = await _entityExtractor.annotateText(text);
      if (annotations.isEmpty) return "No entities";
      return annotations.map((a) => "${a.text} (${a.entities.first.type})").join(", ");
    } catch (e) {
      return "NLU Offline";
    }
  }

  bool isNonEnglish(String text) {
    return RegExp(r'[^\x00-\x7F]').hasMatch(text);
  }

  Future<String> _classifyIntentWithGemini(String text) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    try {
      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are an intent classifier for a mobile assistant.

Understand ANY language including Hindi, Hinglish, or mixed languages.
MIRROR LANGUAGE: ALWAYS reply in the SAME language and tone as the user's message.
- If the user writes in Hindi → reply in Hindi
- If Hinglish → reply in Hinglish
- If English → reply in English
- Never translate unless asked

Classify the user message into ONE of these:
REMINDER, SAVE, QUERY, EMOTIONAL, CHAT

Rules:
- REMINDER → user wants to be reminded (yaad dilana, remind, alarm)
- SAVE → user storing info (I kept..., maine rakha...)
- QUERY → user asking where something is
- EMOTIONAL → feelings, loneliness, sadness
- CHAT → general talk

Return ONLY ONE WORD.

Examples:
"Remind me at 6" → REMINDER
"मुझे 6 बजे याद दिलाना" → REMINDER
"maine chabi table pe rakhi" → SAVE
"mere keys kaha hai" → QUERY
"i feel lonely" → EMOTIONAL

Message: "$text"
"""
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0,
            "maxOutputTokens": 5
          }
        }),
      );

      final data = jsonDecode(response.body);

      String result = data['candidates'][0]['content']['parts'][0]['text']
          .toString()
          .trim()
          .toUpperCase();

      const valid = ["REMINDER", "SAVE", "QUERY", "EMOTIONAL", "CHAT"];
      if (!valid.contains(result)) return "CHAT";

      return result;
    } catch (e) {
      return "CHAT";
    }
  }

  Future<String> classifyIntent(String text) async{
    text = text.toLowerCase();

    if (isNonEnglish(text)) {
      return await _classifyIntentWithGemini(text);
    }

    if (RegExp(r'(where|find|look|lost|search|locat|kahan|kidhar|dhund|pata|address)').hasMatch(text)) {
      return "QUERY";
    }

    if (RegExp(r'(keep|put|plac|sav|rememb|stor|rakh|yaad|left|putt)').hasMatch(text)) {
      return "SAVE";
    }

    if (RegExp(r'(miss|overwhelm|lonely|sad|mother|father|anxious|scared|love|feel|alone)').hasMatch(text)) {
      return "EMOTIONAL";
    }

    if (RegExp(r'(remind|alarm|notify)').hasMatch(text)) {
      return "REMINDER";
    }

    return await _classifyIntentWithGemini(text);
  }

  String extractSubject(String text) {
    text = text.toLowerCase();

    final Map<String, List<String>> synonyms = {
      'keys': ['key', 'chabi', 'chabbi'],
      'wallet': ['wallet', 'purse', 'batua', 'money', 'cash'],
      'medicine': ['med', 'pill', 'dawa', 'tablet', 'capsule'],
      'glasses': ['glass', 'spectacle', 'spec', 'chashma', 'specs'],
      'phone': ['phone', 'mobile', 'cell', 'iphone', 'android'],
      'watch': ['watch', 'ghadi', 'ghari'],
    };

    for (var entry in synonyms.entries) {
      for (var variant in entry.value) {
        if (text.contains(variant)) return entry.key;
      }
    }
    return "unknown";
  }

  String performFuzzyCorrection(String input) {
    input = input.toLowerCase().trim();

    final corrections = {
      'keepiny': 'keeping',
      'puttin': 'putting',
      'remembr': 'remember',
      'wlet': 'wallet',
      'kyes': 'keys',
      'mdcine': 'medicine',
      'ghari': 'ghadi',
      'chabi': 'chabi',
    };

    corrections.forEach((wrong, right) {
      input = input.replaceAll(wrong, right);
    });

    return input;
  }
}