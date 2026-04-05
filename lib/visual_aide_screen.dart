import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_provider.dart';
import 'vision_service.dart';
import 'ai_explainer.dart';

class VisualAideScreen extends StatefulWidget {
  const VisualAideScreen({super.key});

  @override
  State<VisualAideScreen> createState() => _VisualAideScreenState();
}

class _VisualAideScreenState extends State<VisualAideScreen> {
  File? _image;
  String _result = "Tap the button below to identify an object";
  bool _isProcessing = false;

  final VisionService _visionService = VisionService();
  final ImagePicker _picker = ImagePicker();

  static const Color navyText = Color(0xFF0F172A);
  static const Color accentPurple = Colors.deepPurple;
  static const Color softBackground = Color(0xFFF8F7FF);

  Future<void> _captureAndIdentify() async {

    final XFile? photo =
    await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo == null) return;

    setState(() {
      _image = File(photo.path);
      _isProcessing = true;
      _result = "Thinking...";
    });

    try {

      final label =
      await _visionService
          .detectObject(_image!);

      final explainer =
      AIExplainer();

      final explanation =
      await explainer.explain(label);

      setState(() {
        _result = explanation;
        _isProcessing = false;
      });

    } catch (e) {

      setState(() {
        _result =
        "Could not identify";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        toolbarHeight: 85,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyText),
        ),
        title: Text(
          "Smart AI Eye",
          style: GoogleFonts.lexend(
            color: navyText,
            fontWeight: FontWeight.w700,
            fontSize: settings.s(22),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Upper Instruction Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Point your camera at something you want to know about.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: settings.s(18),
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),

          // Main Viewport / Image Display
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: accentPurple.withOpacity(0.2), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: accentPurple.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: _image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 80,
                        color: accentPurple.withOpacity(0.3))
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 3.seconds),
                    const SizedBox(height: 16),
                    Text(
                      "Camera is Ready",
                      style: GoogleFonts.lexend(
                        color: accentPurple.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
          ),

          // Result Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator(color: accentPurple)
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: settings.s(26),
                        fontWeight: FontWeight.w800,
                        color: navyText,
                      ),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),

                // Giant SCAN Button
                GestureDetector(
                  onTap: _isProcessing ? null : _captureAndIdentify,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [accentPurple, Color(0xFF9C27B0)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: accentPurple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 40),
                        const SizedBox(width: 15),
                        Text(
                          "SCAN NOW",
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: settings.s(28),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 4.seconds)
                      .scale(end: const Offset(1.02, 1.02)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}