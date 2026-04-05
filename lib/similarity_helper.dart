import 'dart:math';

class SimilarityHelper {
  // A professional "Fuzzy Match" algorithm
  static double score(String s1, String s2) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int matchCount = 0;
    for (var char in s1.split('')) {
      if (s2.contains(char)) matchCount++;
    }
    // Returns a 0.0 to 1.0 score of how similar words are
    return matchCount / max(s1.length, s2.length);
  }
}