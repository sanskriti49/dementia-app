import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'settings_provider.dart';


class VisualAideScreen extends StatefulWidget {
  const VisualAideScreen({super.key});

  @override
  State<VisualAideScreen> createState() => _VisualAideScreenState();
}

class _VisualAideScreenState extends State<VisualAideScreen> {
  File? _selectedImage;
  String? _description;
  bool _isLoading = false;
  String _targetLanguage = "English";
  final ImagePicker _picker = ImagePicker();

  Future<void> _identifyObject() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    if (apiKey.isEmpty) {
      _showError("API Key is missing!");
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _isLoading = true;
          _description = null;
        });

        final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
        final imageBytes = await _selectedImage!.readAsBytes();

        final prompt = _targetLanguage == "Hindi"
            ? "इस चित्र में मुख्य वस्तु की पहचान करें। वरिष्ठ नागरिक के लिए एक छोटा, सरल वाक्य लिखें।"
            : "Identify the main object in this picture. Write one short, simple, comforting sentence for a senior citizen.";

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ])
        ];

        final response = await model.generateContent(content);

        setState(() {
          _description = response.text ?? "I couldn't identify that.";
          _isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_interaction_time', DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint("Gemini Error: $e");
      setState(() {
        _description = _targetLanguage == "Hindi" ? "कनेक्शन की समस्या।" : "Connection issue. Please try again.";
        _isLoading = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);
    final bool isHindi = _targetLanguage == "Hindi";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: _buildAppBar(isHindi),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: _selectedImage == null
                    ? _buildEmptyState(isHindi)
                    : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                  child: Text(
                    _description ?? (isHindi ? "जानने के लिए बटन दबाएं" : "Tap the eye to see"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24 * settings.fontSizeMultiplier,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D6A4F),
                    ),
                  ).animate().fadeIn(),
                ),
              ),
            ),
          ),

          // Large High-Contrast Button
          _buildBigButton(isHindi, settings.fontSizeMultiplier),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFF2D6A4F), strokeWidth: 5),
        const SizedBox(height: 15),
        Text("Looking...", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBigButton(bool isHindi, double scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: _isLoading ? null : _identifyObject,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F),
            borderRadius: BorderRadius.circular(45),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.remove_red_eye, color: Colors.white, size: 40),
              const SizedBox(width: 15),
              Text(
                isHindi ? "यह क्या है?" : "WHAT IS THIS?",
                style: TextStyle(color: Colors.white, fontSize: 22 * scale, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ).animate(target: _isLoading ? 0 : 1).scale(duration: 200.ms),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isHindi) {
    return AppBar(
      title: Text(isHindi ? "जादुई आँख" : "Magic Eye"),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () => setState(() => _targetLanguage = isHindi ? "English" : "Hindi"),
          child: Text(isHindi ? "English" : "हिन्दी", style: const TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Icon(Icons.camera_alt_outlined, size: 100, color: Colors.grey[300]),
    );
  }
}