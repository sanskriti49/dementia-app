import 'dart:math';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MemoryService {
  static MemoryService? _instance;

  factory MemoryService(String apiKey) {
    _instance ??= MemoryService._internal(apiKey);
    return _instance!;
  }

  MemoryService._internal(String apiKey)
      : _embeddingModel = GenerativeModel(
    model: 'gemini-embedding-001',
    apiKey: apiKey,
  );

  final GenerativeModel _embeddingModel;
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'dementia_chatbot.db'),
      version: 3,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE memories(id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, embedding TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('DELETE FROM memories');
          print("Database cleared due to model upgrade.");
        }
      },
    );
  }

  // SAVE: STORES TEXT AND ITS VECTOR
  Future<void> addMemory(String cleanText) async {
    int retries = 0;
    while (_db == null && retries < 5) {
      print("⏳ DB not ready, waiting... (Attempt $retries)");
      await Future.delayed(Duration(milliseconds: 500));
      retries++;
    }
    if (_db == null) {
      print("ERROR: Database is null in addMemory!");
      return;
    }
    try {
      final embedding = await _embeddingModel.embedContent(Content.text(cleanText));
      final vectorString = jsonEncode(embedding.embedding.values);

      final id = await _db?.insert(
        'memories',
        {'content': cleanText, 'embedding': vectorString},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Memory Saved with ID: $id | Content: $cleanText");
    } catch (e) {
      print("Error in addMemory: $e");
    }
  }

  // SEARCH: Find the most relevant memory
  Future<String?> findRelevantMemory(String query) async {
    if (_db == null) return null;

    try {
      final queryEmbedding = await _embeddingModel.embedContent(Content.text(query));
      final queryVector = queryEmbedding.embedding.values;

      final List<Map<String, dynamic>> rows = await _db!.query('memories', orderBy: 'timestamp DESC');
      if (rows.isEmpty) return null;

      DateTime newest = DateTime.parse(rows.first['timestamp']);
      DateTime oldest = DateTime.parse(rows.last['timestamp']);
      int totalTimeGap = newest.difference(oldest).inSeconds;

      String? bestMemory;
      double bestScore = 0.35;

      for (var row in rows) {
        final List<double> memVector = List<double>.from(jsonDecode(row['embedding']));
        double vectorSimilarity = _cosineSimilarity(queryVector, memVector);

        double recencyFactor = 1.0;
        if (totalTimeGap > 0) {
          DateTime currentMemTime = DateTime.parse(row['timestamp']);
          int gapFromOldest = currentMemTime.difference(oldest).inSeconds;
          recencyFactor = gapFromOldest / totalTimeGap;
        }

        // Final score: 80% similarity, 20% recency
        double finalScore = (vectorSimilarity * 0.8) + (recencyFactor * 0.2);

        if (finalScore > bestScore) {
          bestScore = finalScore;
          bestMemory = row['content'];
        }
      }
      return bestMemory;
    } catch (e) {
      print("❌ Error in search: $e");
      return null;
    }
  }

  Future<void> clearAllMemories() async {
    if (_db == null) return;
    try {
      await _db!.delete('memories');
      print("Database Cleared Successfully");
    } catch (e) {
      print("Error clearing database: $e");
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dotProduct = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}