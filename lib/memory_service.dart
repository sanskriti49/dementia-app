import 'dart:math';
import 'database_helper.dart';
import 'chatbot_engine.dart';
import 'package:sqflite/sqflite.dart';

class MemoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ChatbotEngine _engine = ChatbotEngine();

  Future<void> init() async {
    await _dbHelper.database;
  }

  Future<int> addMemory(String text, {String? aiSubject}) async {
    try {
      final db = await _dbHelper.database;

      String subject = aiSubject ?? _engine.extractSubject(text);

      if (subject == "unknown") {
        List<String> words = text.split(' ');
        subject = words.length > 5 ? words.skip(4).take(2).join(' ') : "general";
      }

      int id = await db.insert('memories', {
        'content': text,
        'subject': subject,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print("💾 [DB] Saved Item ID: $id as $subject");
      return id;
    } catch (e) {
      print("❌ [DB] Error saving: $e");
      return -1;
    }
  }

  Future<String?> findRelevantMemory(String query) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> allMemories = await db.query('memories');

      if (allMemories.isEmpty) return null;

      Map<String, dynamic>? bestMatch;
      double highestScore = 0.0;

      String cleanQuery = query.toLowerCase()
          .replaceAll(RegExp(r'(where|is|my|find|the|tell|me|about|at|did|i|put|keep|keeping)'), '')
          .trim();

      for (var memory in allMemories) {
        double subjScore = _calculateSimilarity(cleanQuery, memory['subject'].toString().toLowerCase());
        double contScore = _calculateSimilarity(cleanQuery, memory['content'].toString().toLowerCase());

        double currentMax = max(subjScore, contScore);

        if (currentMax > highestScore) {
          highestScore = currentMax;
          bestMatch = memory;
        }
      }

      // 3. Confidence Threshold: Only return if it's a decent match (> 0.3)
      if (highestScore > 0.3) {
        print("🎯 [ML Search] Found match: '${bestMatch!['subject']}' with confidence: ${highestScore.toStringAsFixed(2)}");
        return bestMatch['content'];
      }

      return null;
    } catch (e) {
      print("❌ [DB] Retrieval error: $e");
      return null;
    }
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    Set<String> getPairs(String s) {
      Set<String> pairs = {};
      for (int i = 0; i < s.length - 1; i++) {
        pairs.add(s.substring(i, i + 2));
      }
      return pairs;
    }

    var pairs1 = getPairs(s1);
    var pairs2 = getPairs(s2);

    var intersection = pairs1.intersection(pairs2).length;
    var union = pairs1.length + pairs2.length;

    return (2.0 * intersection) / union;
  }

  // --- OTHER HELPERS ---

  Future<List<Map<String, dynamic>>> getAllMemories() async {
    final db = await _dbHelper.database;
    return await db.query('memories', orderBy: 'timestamp DESC');
  }

  Future<void> updateMemory(int id, String newContent) async {
    final db = await _dbHelper.database;
    String newSubject = _engine.extractSubject(newContent);
    await db.update('memories', {
      'content': newContent,
      'subject': newSubject,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMemory(int id) async {
    final db = await _dbHelper.database;
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> nukeDatabase() async => await clearAll();

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('memories');
    print("⚠️ [DB] All memories wiped.");
  }

  Future<void> debugDumpDatabase() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> allRows = await db.query('memories');
    print("------- 🔎 DATABASE DUMP -------");
    if (allRows.isEmpty) {
      print("Empty: No memories stored yet.");
    } else {
      for (var row in allRows) {
        print("ID: ${row['id']} | Subj: ${row['subject']} | Content: ${row['content']}");
      }
    }
    print("--------------------------------");
  }
}