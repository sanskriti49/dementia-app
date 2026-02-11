import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'memory_service.dart';

class ChatbotService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  late final GenerativeModel _chatModel;
  late final GenerativeModel _routerModel;
  late final MemoryService _memoryService;
  final Completer<void> _initCompleter = Completer<void>();

  ChatbotService() {
    if (_apiKey == 'API_KEY_NOT_FOUND') {
      throw Exception('API Key not found.');
    }
    _setup();
  }

  Future<void> _setup() async {
    try {
      _chatModel = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      _routerModel = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      _memoryService = MemoryService(_apiKey);
      await _memoryService.init();

      print("✅ ChatbotService & Memory DB Initialized");
      _initCompleter.complete();
    } catch (e) {
      print("❌ Initialization Error: $e");
      if (!_initCompleter.isCompleted) _initCompleter.completeError(e);
    }
  }

  // Future<String> sendMessage(String rawUserMsg) async {
  //   String userLang = "English";
  //   String intent = "CHAT";
  //   String cleanEnglish = rawUserMsg;
  //   String directReply = "";
  //
  //   try {
  //     if (!_initCompleter.isCompleted) {
  //       print("⏳ Waiting for initialization...");
  //       await _initCompleter.future;
  //     }
  //
  //     final routerPrompt = """
  //       Analyze: "$rawUserMsg"
  //       Return ONLY a JSON object:
  //       {
  //         "intent": "SAVE" | "QUERY" | "CHAT",
  //         "clean_english_text": "simple english for db",
  //         "user_language": "Hindi, English, or Hinglish",
  //         "direct_reply": "Warm response in the user's language"
  //       }
  //     """;
  //
  //     final routerResponse = await _routerModel.generateContent([Content.text(routerPrompt)]);
  //     final String jsonString = routerResponse.text ?? "{}";
  //
  //     final cleanedJson = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
  //     final Map<String, dynamic> data = jsonDecode(cleanedJson);
  //
  //     intent = data['intent'] ?? "CHAT";
  //     cleanEnglish = data['clean_english_text'] ?? rawUserMsg;
  //     userLang = data['user_language'] ?? "English";
  //     directReply = data['direct_reply'] ?? "";
  //
  //     if (intent == "SAVE") {
  //       await _memoryService.addMemory(cleanEnglish);
  //       return directReply.isNotEmpty ? directReply : "ठीक है, मैंने याद रखा।";
  //     }
  //
  //     if (intent == "QUERY") {
  //       String? memory = await _memoryService.findRelevantMemory(cleanEnglish);
  //       if (memory != null) {
  //         final prompt = "User Language: $userLang. Memory: $memory. Answer: $rawUserMsg";
  //         final response = await _chatModel.generateContent([Content.text(prompt)]);
  //         return response.text ?? memory;
  //       } else {
  //         return userLang == "Hindi" || userLang == "Hinglish"
  //             ? "मुझे अभी यह याद नहीं है।"
  //             : "I don't remember that yet.";
  //       }
  //     }
  //
  //     return directReply.isNotEmpty ? directReply : "I am here for you.";
  //
  //   } catch (e) {
  //     if (e.toString().contains("429") || e.toString().contains("quota")) {
  //       return "Server busy. Please wait 1 minute.";
  //     }
  //     return "Network error. Try again.";
  //   }
  // }
  Future<String> sendMessage(String rawUserMsg) async {
    String userLang = "English";
    String intent = "CHAT";
    String cleanEnglish = rawUserMsg;
    String directReply = "";

    try {
      if (!_initCompleter.isCompleted) await _initCompleter.future;

      // final routerPrompt = """
      //   You are 'Memoir', a gentle assistant for a senior citizen with memory loss in India.
      //   User said: "$rawUserMsg"
      //
      //   Task:
      //   1. Identify intent (SAVE, QUERY, CHAT).
      //   2. Translate to clean English for the database.
      //   3. Determine language (Hindi, English, or Hinglish).
      //   4. If SAVE/CHAT, write a 'direct_reply' in the user's language.
      //      BE WARM. Use "aap" (not "tum"). Be comforting.
      //
      //   Return ONLY JSON:
      //   {
      //     "intent": "SAVE",
      //     "clean_english_text": "I put my glasses in the wooden cabinet",
      //     "user_language": "Hinglish",
      //     "direct_reply": "Ji, bilkul. Maine yaad rakha hai ki aapne chashma wooden cabinet mein rakha hai. Chinta mat kijiye!"
      //   }
      // """;

      final routerPrompt = """
  You are an intent classifier for a senior's memory app.
  User message: "$rawUserMsg"

  Rules:
  - If the user is stating a fact they want to remember (e.g., "I put my keys in the drawer", "Mera chashma table par hai"), set intent to "SAVE".
  - If the user is asking where something is, set intent to "QUERY".
  - Otherwise, set intent to "CHAT".

  Return ONLY JSON:
  {
    "intent": "SAVE" | "QUERY" | "CHAT",
    "clean_english_text": "The core fact in simple English",
    "user_language": "Hindi/English/Hinglish",
    "direct_reply": "A warm response to the user in the user's language"
  }
""";
      final routerResponse = await _routerModel.generateContent([Content.text(routerPrompt)]);
      String jsonString = routerResponse.text ?? "{}";
      jsonString = jsonString.replaceAll(RegExp(r'```json|```'), '').trim();

      Map<String, dynamic> data = jsonDecode(jsonString);
      intent = data['intent'] ?? "CHAT";
      cleanEnglish = data['clean_english_text'] ?? rawUserMsg;
      userLang = data['user_language'] ?? "English";
      directReply = data['direct_reply'] ?? "";

      if (intent == "SAVE") {
        await _memoryService.addMemory(cleanEnglish);
        return directReply;
      }

      if (intent == "QUERY") {
        String? memory = await _memoryService.findRelevantMemory(cleanEnglish);
        if (memory != null) {
          final prompt = """
            You are Memoir, a comforting assistant. 
            Language: $userLang.
            Memory Found: "$memory"
            User asked: "$rawUserMsg"
            
            Tell the user where their item is. 
            Rules:
            - Speak directly to them: "Aapka [item] [location] mein hai."
            - Be very gentle and kind.
            - Do NOT say "The memory says...".
            - Use $userLang only.
          """;
          final response = await _chatModel.generateContent([Content.text(prompt)]);
          return response.text ?? memory;
        } else {
          return userLang == "Hindi" || userLang == "Hinglish"
              ? "Mujhe dukh hai, par mujhe abhi yeh yaad nahi aa raha. Kya aapne usey kamre mein rakha tha?"
              : "I'm so sorry, I don't remember that right now. Could it be in the other room?";
        }
      }

      return directReply.isNotEmpty ? directReply : "Ji, main sun raha hoon. Bataiye?";

    } catch (e) {
      print("Actual Error: $e");
      return (userLang == "Hindi" || userLang == "Hinglish")
          ? "Maaf kijiye, mujhe thoda network issue ho raha hai."
          : "I'm having a little trouble connecting. Could you say that again?";
    }
  }
}