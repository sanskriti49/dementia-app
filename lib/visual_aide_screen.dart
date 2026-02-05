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
    try {

      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final prefs=await SharedPreferences.getInstance();
        await prefs.setInt('last_interaction_time', DateTime.now().millisecondsSinceEpoch);

        setState(() {
          _selectedImage = File(photo.path);
          _isLoading = true;
          _description = null;
        });

        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
        final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
        final imageBytes = await _selectedImage!.readAsBytes();

        String systemPrompt;
        if (_targetLanguage == "Hindi") {
          systemPrompt = "इस चित्र में मुख्य वस्तु की पहचान करें। केवल हिंदी (Hindi) में उत्तर दें। वरिष्ठ नागरिक के लिए एक छोटा, सरल और आरामदायक वाक्य लिखें। तकनीकी शब्दों का प्रयोग न करें।";
        } else {
          systemPrompt = "Identify the main object in this picture. Respond ONLY in English. Describe it in one short, simple, and comforting sentence for a senior citizen. Do not use technical jargon.";
        }

        final content = [
          Content.multi([
            TextPart(systemPrompt),
            DataPart('image/jpeg', imageBytes),
          ])
        ];

        final response = await model.generateContent(content);
        setState(() {
          _description = response.text;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _description = _targetLanguage == "Hindi" ? "क्षमा करें, कुछ तकनीकी त्रुटि हुई।" : "Sorry, I ran into a technical issue.";
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final flutterNotifications = FlutterLocalNotificationsPlugin();

    // For Android 13+
    final platformImplementation = flutterNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (platformImplementation != null) {
      await platformImplementation.requestNotificationsPermission();
    }
  }
  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);
    final bool isHindi = _targetLanguage == "Hindi";

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F5),
      appBar: _buildAppBar(context, isHindi),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _selectedImage == null
                      ? _buildEmptyState(isHindi)
                      : Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: _isLoading
                      ? _buildLoadingIndicator()
                      : SingleChildScrollView(
                    child: Text(
                      _description ?? (isHindi ? "कुछ देखने के लिए बटन दबाएं।" : "Tap the button to start seeing."),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22 * settings.fontSizeMultiplier,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                        height: 1.4,
                      ),
                    ).animate(key: ValueKey(_description)).fadeIn().slideY(begin: 0.1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(settings.fontSizeMultiplier, isHindi),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isHindi) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D6A4F)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isHindi ? "जादुई आँख" : "Magic Eye",
        style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(isHindi ? "English" : "हिन्दी"),
            selected: false,
            onSelected: (val) {
              HapticFeedback.mediumImpact(); // Vibration feedback
              setState(() {
                _targetLanguage = isHindi ? "English" : "Hindi";
                _description = _targetLanguage == "Hindi"
                    ? "कुछ देखने के लिए बटन दबाएं।"
                    : "Tap the button to start seeing.";
              });
            },
            backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1),
            labelStyle: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_enhance_outlined, size: 70, color: const Color(0xFF2D6A4F).withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          isHindi ? "तस्वीर लें" : "Take a Photo",
          style: const TextStyle(color: Colors.black26, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFF26A69A), strokeWidth: 3),
        const SizedBox(height: 16),
        Text("Identifying...", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButton(double fontSizeMultiplier, bool isHindi) {
    return GestureDetector(
      onTap: _isLoading ? null : _identifyObject,
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Text(
              isHindi ? "यह क्या है?" : "WHAT IS THIS?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * fontSizeMultiplier,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: _isLoading ? 0 : 1).scale(duration: 200.ms);
  }
}