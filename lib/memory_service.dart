// lib/memory_service.dart
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  final GenerativeModel _embeddingModel;

  // We keep a local list in memory for speed, and sync it with phone storage
  List<String> _memories = [];

  MemoryService(String apiKey)
      : _embeddingModel = GenerativeModel(
    model: 'text-embedding-004', // Dedicated model for understanding meaning
    apiKey: apiKey,
  );

  // Initialize: Load saved memories from phone storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _memories = prefs.getStringList('user_memories') ?? [];
  }

  // 1. SAVE: Add a new memory
  Future<void> addMemory(String cleanText) async {
    //
    // _memories.add(text);
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setStringList('user_memories', _memories);

    if(!_memories.contains(cleanText)){
      _memories.add(cleanText);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_memories', _memories);
    }
  }

  // 2. SEARCH: Find the most relevant memory using Cosine Similarity
  Future<String?> findRelevantMemory(String query) async {
    if (_memories.isEmpty) return null;

    try {
      // Convert user question to numbers
      final queryEmbedding = await _embeddingModel.embedContent(Content.text(query));
      final queryVector = queryEmbedding.embedding.values;

      String? bestMemory;
     // double bestScore = -1.0;
      double bestScore = 0.35;

      // Compare against all saved memories
      for (var memory in _memories) {
        final memEmbedding = await _embeddingModel.embedContent(Content.text(memory));
        final memVector = memEmbedding.embedding.values;

        double score = _cosineSimilarity(queryVector, memVector);

        // If the score is high (similar meaning), keep it.
        if (score > bestScore) {
          bestScore = score;
          bestMemory = memory;
        }
      }

      // Threshold: 0.6 means "fairly similar". Adjust if needed.
      return bestMemory;
    } catch (e) {
      print("Embedding Error: $e");
      return null; // Fail gracefully
    }
  }

  // Math helper to compare vectors
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