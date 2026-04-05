import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIExplainer {

  late GenerativeModel model;

  AIExplainer() {
    model = GenerativeModel(
      model: "gemini-1.5-flash",
      apiKey: dotenv.env["GEMINI_API_KEY"]!,
    );
  }

  Future<String> explain(String label) async {

    final prompt =
        "Explain what a $label is and what it is used for in simple words for elderly users.";

    final response =
    await model.generateContent(
      [Content.text(prompt)],
    );

    return response.text ?? label;
  }
}