import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'memory_service.dart';
import 'reminder_service.dart';
import 'chatbot_engine.dart';

class ChatbotService {
  final String _groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final String _geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _groqUrl = "https://api.groq.com/openai/v1/chat/completions";

  final ChatbotEngine _engine = ChatbotEngine();
  final MemoryService _memory = MemoryService();

  ChatbotService();

  final List<Map<String, String>> _conversationHistory = [];

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _memory.init();
      _isInitialized = true;
    }
  }
  DateTime extractTime(String text) {
    final now = DateTime.now();
    text = text.toLowerCase();

    // ========================
    // 1️⃣ RELATIVE TIME FIRST
    // ("in 20 minutes", "after 2 hours", including hr/hr(s)")
    // ========================
    final relativeMatch = RegExp(
      r'(in|after)\s*(\d+)\s*(minute|minutes|min|hour|hours|hr|hrs)',
    ).firstMatch(text);

    if (relativeMatch != null) {
      int value = int.parse(relativeMatch.group(2)!);
      String unit = relativeMatch.group(3)!;

      if (unit.contains('hour') || unit.contains('hr')) {
        return now.add(Duration(hours: value));
      } else {
        return now.add(Duration(minutes: value));
      }
    }

    // ========================
    // 2️⃣ DAY CONTEXT
    // ========================
    int dayOffset = 0;
    if (text.contains("tomorrow") || text.contains("kal")) {
      dayOffset = 1;
    } else if (text.contains("day after")) {
      dayOffset = 2;
    } else if (text.contains("today") || text.contains("aaj")) {
      dayOffset = 0;
    }

    // ========================
    // 3️⃣ DEFAULT HOUR BASED ON TIME OF DAY
    // ========================
    int defaultHour = 9; // fallback if no time specified
    if (text.contains("morning") || text.contains("subah")) {
      defaultHour = 8;
    } else if (text.contains("afternoon") || text.contains("dopahar")) {
      defaultHour = 14;
    } else if (text.contains("evening") || text.contains("shaam")) {
      defaultHour = 18;
    } else if (text.contains("night") || text.contains("raat")) {
      defaultHour = 21;
    }

    // 4️⃣ ABSOLUTE TIME (with AM/PM or HH:MM)
    final timeMatch = RegExp(r'(\d{1,2})[.:\s]?(\d{2})?\s*(am|pm)?').firstMatch(text);
    int hour = defaultHour;
    int minute = 0;

    if (timeMatch != null) {
      hour = int.parse(timeMatch.group(1)!);

      if (timeMatch.group(2) != null) {
        minute = int.parse(timeMatch.group(2)!);
      } else {
        minute = 0;
      }

      String? period = timeMatch.group(3);
      if (period != null) {
        period = period.toLowerCase();
        if (period == "pm" && hour < 12) hour += 12;
        if (period == "am" && hour == 12) hour = 0;
      } else if (hour < 12 && (text.contains("evening") || text.contains("night") || text.contains("pm"))) {
        hour += 12;
      }
    }

    DateTime result = DateTime(
      now.year,
      now.month,
      now.day + dayOffset,
      hour,
      minute,
    );
    // 6️⃣ IF TIME ALREADY PASSED → SHIFT FORWARD
    if (result.isBefore(now)) {
      result = result.add(const Duration(days: 1));
    }

    return result;
  }

  Future<String> extractObjectWithAI(String text) async {
    try{
      final response = await http.post(Uri.parse(_groqUrl),
        headers: {"Authorization": "Bearer $_groqKey", "Content-Type": "application/json"},
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {"role": "system", "content": "Extract the reminder title in 2-4 words. Example: 'take medicine', 'call mom', 'drink water'. Respond with only words."},
            {"role": "user", "content": text}
          ],
          "max_tokens": 5,
          "temperature": 0.1,
        }),
      );
      final data = jsonDecode(response.body);
      String result = data['choices'][0]['message']['content'].toString().toLowerCase().trim();
      return result.replaceAll(RegExp(r'[^\w\s]'), '');
    } catch (e) {
      return "unknown";
    }
  }

  Future<Map<String, dynamic>> getSmartResponse(String prompt) async {
    await _ensureInitialized();

    final String lowPrompt = prompt.toLowerCase().trim();
    if (lowPrompt == "clear all memories" || lowPrompt == "forget everything") {
      await _memory.nukeDatabase();
      _conversationHistory.clear();
      print("💥 [System] Database and History wiped by user command.");
      return {
        'text': "I have cleared all my stored memories. We are starting with a blank slate! How can I help you today?",
        'usedMemory': false,
        'intent':"CHAT",
      };
    }

    await _memory.debugDumpDatabase();
    try {
      final String cleanPrompt = _engine.performFuzzyCorrection(prompt);

      final String nluExtractions = await _engine.getLocalNLUContext(cleanPrompt);
      final String intent = await _engine.classifyIntent(cleanPrompt);
      print("🤖 Chatbot Intent Detected: $intent");

      String memoryContext = "No history relevant to this specific message.";
      String situationalInstruction = "";
      bool usedMemory = false;

      if (intent == "REMINDER") {
        final time = extractTime(cleanPrompt);
        String title = await extractObjectWithAI(cleanPrompt);

        if (title == "unknown" || title.isEmpty) {
          title = cleanPrompt;
        }
        return {
          "text": "Got it! I’ll remind you 😊",
          "action": "CREATE_REMINDER",
          "title": title,
          "time": time,
          "usedMemory": false,
          "intent": "REMINDER",
        };
      }

      if (intent == "SAVE") {
        // STEP A: Use AI to understand WHAT the object is
        String detectedSubject = await extractObjectWithAI(cleanPrompt);

        // STEP B: Save the raw text + the AI identified subject
        await _memory.addMemory(cleanPrompt,aiSubject:detectedSubject);
        await _memory.debugDumpDatabase();

        print("✅ ML Extraction: $detectedSubject Saved.");

        situationalInstruction = "The user is telling you a location. Respond with ONE warm sentence acknowledging you've noted THE EXACT object and location of the $detectedSubject. Ignore all previous database facts for this response.";
      }
      else if (intent == "QUERY") {
        // ONLY search the database when the user asks a question
        String? found = await _memory.findRelevantMemory(cleanPrompt);
        String subject = _engine.extractSubject(cleanPrompt);
        final reminder = await ReminderService.getNextReminderFor(subject);

        String reminderHint = "";

        if (reminder != null) {
          reminderHint = " You also have a reminder at ${reminder.timeString}.";
        }
        if (found != null) {
          memoryContext = "DATABASE TRUTH: $found$reminderHint";
          situationalInstruction = "The user is looking for an object. Use the DATABASE TRUTH to answer.";
          usedMemory = true;
        } else {
          situationalInstruction = "Item not found in memory. Be a memory coach and ask where they last saw it.";
        }
      }
      else if (intent == "EMOTIONAL") {
        situationalInstruction = "The user is sharing a feeling. Focus entirely on empathy. Do not mention any objects or locations.";
      }
      else {
        situationalInstruction = "General friendly conversation.";
      }

      // 2. CONSTRUCT PAYLOAD
      List<Map<String, String>> messages = [
        {
          "role": "system",
          "content": """
            IDENTITY: You are 'Companion', a loving digital caregiver for seniors. 
            
            UNIVERSAL RULES:
            1. MIRROR LANGUAGE: Speak the language the user is using.
            2. NO HALLUCINATION: You must be 100% literal. If the user says 'Keys', do not say 'Phone'. 
            3. PRIORITY: The [CURRENT USER MESSAGE] is always more accurate than [MEMORY DATA] if they conflict.
            4. DIGITAL LIMIT: You cannot move or fetch items physically.
            5. NO REPETITION: Never repeat the same fact twice in one response. 

            SITUATION: $situationalInstruction
            [MEMORY DATA]: $memoryContext
            [LOCAL NLU]: $nluExtractions

            INSTRUCTION: Be warm, concise, and stay focused ONLY on the object mentioned in the last message, if any.
          """
        }
      ];

      messages.addAll(_conversationHistory);
      messages.add({"role": "user", "content": cleanPrompt});

      // 3. API CALL
      final response = await http.post(Uri.parse(_groqUrl),
        headers: {"Authorization": "Bearer $_groqKey", "Content-Type": "application/json"},
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": messages,
          "temperature": 0.4, // Lower temperature reduces hallucinations
        }),
      );

      final data = jsonDecode(response.body);
      String botResponse = data['choices'][0]['message']['content'];

      // 4. UPDATE HISTORY
      _conversationHistory.add({"role": "user", "content": cleanPrompt});
      _conversationHistory.add({"role": "assistant", "content": botResponse});
      if (_conversationHistory.length > 8) _conversationHistory.removeRange(0, 2);

      return {
        'text': botResponse,
        'usedMemory': usedMemory,
        'intent': intent,
      };
    } catch (e) {
      return {'text': "I'm here with you. I'm having a little trouble thinking. Say that again?", 'usedMemory': false};
    }
  }

}
