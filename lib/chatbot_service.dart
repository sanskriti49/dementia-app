
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'memory_service.dart';

class ChatbotService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  late final GenerativeModel _chatModel;
  late final GenerativeModel _routerModel;
  late final MemoryService _memoryService;

  ChatbotService() {
    if (_apiKey == 'API_KEY_NOT_FOUND') {
      throw Exception('API Key not found.');
    }

    // 1. The Chat Model (The gentle personality)
    _chatModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      ],
    );

    // 2. The Router Model (The Brain)
    // It outputs JSON to classify language and intent
    _routerModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    _memoryService = MemoryService(_apiKey);
    _memoryService.init();
  }

  Future<String> sendMessage(String rawUserMsg) async {
    try {
      // --- STEP 1: ANALYZE (Intent + Language + Translation) ---

      final routerPrompt = """
      You are the brain of an app for a dementia patient in India. 
      Analyze this text: "$rawUserMsg"
      
      The user might speak English, Hindi, or Hinglish (Hindi in English script) or even other South Asian languages!
      
      Return a JSON object with these fields:
      1. "intent": One of ["SAVE", "QUERY", "CHAT"].
         - SAVE: User is stating a location (e.g., "mene chabi drawer me rakhi", "i put key on table").
         - QUERY: User is asking a location (e.g., "chabi kahan hai?", "where key?").
         - CHAT: Greetings or random talk.
      2. "clean_english_text": Translate the user's text into clear, simple English (for database storage).
      3. "user_language": The language the user spoke (e.g., "Hindi", "English", "Hinglish", "Bengali", "Tamil", "Marathi", "Telugu").
      
      Example Output: 
      {"intent": "SAVE", "clean_english_text": "I put the keys on the table.", "user_language": "Hindi"}
      """;

      final routerResponse = await _routerModel.generateContent([Content.text(routerPrompt)]);
      final routerJson = routerResponse.text ?? "{}";

      // Quick & Dirty Parsing
      String intent = "CHAT";
      String cleanEnglish = rawUserMsg;
      String userLang = "English";

      if (routerJson.contains('"intent": "SAVE"')) intent = "SAVE";
      if (routerJson.contains('"intent": "QUERY"')) intent = "QUERY";

      // Extract Clean English
      final textMatch = RegExp(r'"clean_english_text":\s*"(.*?)"').firstMatch(routerJson);
      if (textMatch != null) cleanEnglish = textMatch.group(1) ?? rawUserMsg;

      // Extract Language
      final langMatch = RegExp(r'"user_language":\s*"(.*?)"').firstMatch(routerJson);
      if (langMatch != null) userLang = langMatch.group(1) ?? "English";

      print("DECISION: $intent | LANG: $userLang | TRANSLATION: $cleanEnglish");


      // --- STEP 2: EXECUTE ---

      if (intent == "SAVE") {
        // We save the ENGLISH version so the database is clean
        await _memoryService.addMemory(cleanEnglish);

        // But we confirm to the user in THEIR language
     //   final responsePrompt = "The user spoke $userLang. Tell them kindly (STRICTLY in $userLang) that you have saved this memory: '$cleanEnglish'.IMPORTANT: Do NOT provide an English translation. Only speak $userLang.";
        final responsePrompt="""
          The user spoke in $userLang. 
          The English translation of what they saved is: '$cleanEnglish'.
          
          Reply to the user in $userLang.
          Confirm that you have remembered this information.
          
          CRITICAL RULES:
          1. Translate the location/item details back into $userLang naturally.
          2. Do NOT mention that this is a translation.
          3. Do NOT say "The English translation is...".
          4. Do NOT output the English text if the user spoke any non-English language.
        """;
        final response = await _chatModel.generateContent([Content.text(responsePrompt)]);
        return response.text ?? "Saved.";
      }

      else if (intent == "QUERY") {
        // We search using the ENGLISH translation (matches better)
        String? memory = await _memoryService.findRelevantMemory(cleanEnglish);

        if (memory != null) {
          final prompt = """
           You are a gentle assistant.
           User Language: $userLang.
           User Question (Translated): "$cleanEnglish"
           Found Memory: "$memory"
           
           The user is asking a question. Answer them in $userLang based on the Found Memory.
           
           CRITICAL RULES:
           1. Use the Found Memory facts, but speak entirely in $userLang.
           2. Do NOT quote the English text directly.
           3. Be reassuring. Be reassuring and comfort them if they sound troubled. 
           IMPORTANT: Do NOT include an English translation in your response.
           """;
          final response = await _chatModel.generateContent([Content.text(prompt)]);
          return response.text ?? memory;
        } else {
          final prompt = "The user asked '$cleanEnglish' in $userLang. Tell them gently in $userLang that you don't remember that information. IMPORTANT: Do NOT provide an English translation.";
          final response = await _chatModel.generateContent([Content.text(prompt)]);
          return response.text ?? "I don't remember, sorry :/";
        }
      }

      // Fallback: Normal Chat
      final chatPrompt = "User said: '$rawUserMsg'. Reply naturally in the same language ($userLang). Do NOT switch languages.";
      final chatResponse = await _chatModel.generateContent([Content.text(chatPrompt)]);
      return chatResponse.text ?? "I'm listening.";

    } catch (e) {
      print("ERROR: $e");
      return "Network error. Can you check your internet?";
    }
  }
}