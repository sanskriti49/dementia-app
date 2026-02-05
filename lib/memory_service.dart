import 'dart:math';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  final GenerativeModel _embeddingModel;
  Database? _db;

  // a local list in memory for speed and sync it with phone storage
 // List<String> _memories = [];

  MemoryService(String apiKey)
      : _embeddingModel = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: apiKey,
  );

  // Initialize: Load saved memories from DB
  Future<void> init() async {
    // final prefs = await SharedPreferences.getInstance();
    // _memories = prefs.getStringList('user_memories') ?? [];
    final dbPath=await getDatabasesPath();
    _db=await openDatabase(
      join(dbPath,'dementia_chatbot.db'),
      version:1,
      onCreate:(db,version){
        return db.execute(
          'CREATE TABLE memories(id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, embedding TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
      },
    );
  }

  // SAVE: STORES TEXT AND ITS VECTOR
  Future<void> addMemory(String cleanText) async {
    // if(!_memories.contains(cleanText)){
    //   _memories.add(cleanText);
    //   final prefs = await SharedPreferences.getInstance();
    //   await prefs.setStringList('user_memories', _memories);
    // }
    final embedding=await _embeddingModel.embedContent(Content.text(cleanText));
    final vectorString = jsonEncode(embedding.embedding.values);

    await _db?.insert(
      'memories',
      {'content':cleanText,'embedding':vectorString},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // SEARCH: Find the most relevant memory using Cosine Similarity
  // SEARCH: Uses Vector Similarity on all DB entries
  Future<String?> findRelevantMemory(String query) async {
    // if (_memories.isEmpty) return null;
    if (_db == null) return null;

    try {
      // Convert user question to numbers
      final queryEmbedding = await _embeddingModel.embedContent(Content.text(query));
      final queryVector = queryEmbedding.embedding.values;

      // final List<Map<String, dynamic>> rows = await _db!.query('memories');
      final List<Map<String, dynamic>> rows = await _db!.query('memories', orderBy: 'timestamp DESC');
      if(rows.isEmpty) return null;

      DateTime newest=DateTime.parse(rows.first['timestamp']);
      DateTime oldest=DateTime.parse(rows.last['timestamp']);
      int totalTimeGap=newest.difference(oldest).inSeconds;

      String? bestMemory;
      double bestScore = 0.35;

      // Compare against all saved memories
      for (var row in rows) {
        final List<double> memVector = List<double>.from(jsonDecode(row['embedding']));
        double vectorSimilarity=_cosineSimilarity(queryVector,memVector);
        // final memEmbedding = await _embeddingModel.embedContent(Content.text(memory));
        // final memVector = memEmbedding.embedding.values;

        double recencyFactor = 1.0;
        if(totalTimeGap>0){
          DateTime currentMemTime=DateTime.parse(row['timestamp']);
          int gapFromOldest=currentMemTime.difference(oldest).inSeconds;
          recencyFactor=gapFromOldest/totalTimeGap;
        }
        double finalScore=(vectorSimilarity*0.8)+(recencyFactor*0.2);

        // If the score is high (similar meaning), keep it.
        if (finalScore > bestScore) {
          bestScore = finalScore;
          // bestMemory = memory;
          bestMemory = row['content'];
        }
      }

      // Threshold: 0.6 means "fairly similar". Adjust if needed.
      return bestMemory;
    } catch (e) {
      print(" Error: $e");
      return null; // Fail gracefully
    }
  }

  // math helper to compare vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}