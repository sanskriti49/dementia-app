import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// Your Project Imports
import 'chatbot.dart';
import 'voice_service.dart';
import 'emergency_contacts_page.dart';
import 'emergency_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with SingleTickerProviderStateMixin {
  // Animation and Logic Variables
  late AnimationController _progressController;
  Timer? _vibrationTimer;
  bool _isHolding = false;
  bool _isDialogOpen = false;

  final VoiceService _voice = VoiceService();
  StreamSubscription? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _initServices();
    _startShakeDetection();

    // 2-second hold animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleHoldComplete();
      }
    });
  }

  Future<void> _initServices() async {
    await _voice.init();
    _voice.speak("You're safe. I am here to help.");
  }

  @override
  void dispose() {
    _progressController.dispose();
    _vibrationTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // --- ⚡ HOLD LOGIC ---

  void _startHolding() {
    setState(() => _isHolding = true);
    _progressController.forward();

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      HapticFeedback.lightImpact();
    });
  }

  void _stopHolding() {
    setState(() => _isHolding = false);
    _vibrationTimer?.cancel();
    _progressController.reverse();
  }

  void _handleHoldComplete() {
    _stopHolding();
    HapticFeedback.heavyImpact();
    _triggerFullEmergency();
  }

  // --- 🚨 EMERGENCY LOGIC ---

  void _startShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double acceleration = event.x.abs() + event.y.abs() + event.z.abs();
      if (acceleration > 32 && !_isDialogOpen) {
        HapticFeedback.heavyImpact();
        _showShakeAlert();
      }
    });
  }

  Future<void> _triggerFullEmergency() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String mapUrl = "https://www.google.com/maps?q=${pos.latitude},${pos.longitude}";
      String message = "🚨 EMERGENCY! This is an automated alert from $settings.userName. I need help. My location: $mapUrl";
      _showContactPicker(message);
    } catch (e) {
      _showSnackBar("Location error. Please check GPS permissions.");
    }
  }

  // --- 🎨 UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMainSOSButton(),
          const SizedBox(height: 2),

          _buildActionGrid(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "MEMOIR • Privacy-First Protection",
              style: GoogleFonts.lexend(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 5, 30, 35),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD90429), Color(0xFFEF233C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD90429).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Small branding element
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "SOS",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.wifi_rounded, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 25),
            Text(
              "Don't panic, $settings.userName.",
              style: GoogleFonts.lexend(
                color: Colors.white.withOpacity(0.85),
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Help is a tap away.",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSOSButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => _startHolding(),
        onTapUp: (_) => _stopHolding(),
        onTapCancel: () => _stopHolding(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Shadow Ring
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
                ],
              ),
            ),
            // The "Filling" Progress Ring
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFD90429).withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD90429)),
                  ),
                );
              },
            ),
            // Inner Core
            Container(
              width: 175,
              height: 175,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: _isHolding ? const Color(0xFFD90429) : Colors.grey, size: 40),
                  Text("SOS",
                      style: GoogleFonts.lexend(
                        color: const Color(0xFFD90429),
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      )),
                  Text(_isHolding ? "HOLDING..." : "Hold 2s",
                      style: GoogleFonts.lexend(color: Colors.black45, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _actionCard("Call Family", Icons.phone_in_talk_rounded, Colors.green,
                    () => _showContactPicker("I need help, please call me.")),
            _actionCard("I'm Lost", Icons.explore_rounded, Colors.blue, _triggerFullEmergency),
            _actionCard("Anxious", Icons.spa_rounded, Colors.purple, () {
              _showAnxietySupportMenu();
            }),
            _actionCard("Contacts", Icons.contact_emergency_rounded, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsPage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showContactPicker(String message) async {
    final contacts = await EmergencyService.getContacts();
    if (contacts.isEmpty) {
      _showSnackBar("No contacts found.");
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        itemCount: contacts.length,
        itemBuilder: (context, i) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(contacts[i].name),
          trailing: const Icon(Icons.send, color: Colors.green),
          onTap: () async {
            Navigator.pop(context);
            final cleanPhone = contacts[i].phone.replaceAll(RegExp(r'[^0-9]'), '');
            final whatsappUrl = "whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}";
            if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
              await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
            } else {
              final fallback = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
              await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  void _showShakeAlert() {
    setState(() => _isDialogOpen = true);
    _voice.speak("Are you okay? I detected a shake.");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("Shake Detected"),
        content: const Text("Should I alert your contacts?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(c); setState(() => _isDialogOpen = false); }, child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(c); setState(() => _isDialogOpen = false); _triggerFullEmergency(); },
            child: const Text("YES, ALERT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // --- 🧘 ANXIETY & CALM HELPERS ---

  void _showAnxietySupportMenu() {
    _voice.speak("I'm right here with you. What would help most?");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Take a moment for yourself",
                style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _anxietyOption(
              icon: Icons.air_rounded,
              color: Colors.blue,
              title: "Guided Breathing",
              subtitle: "Calm your heart rate",
              onTap: () {
                Navigator.pop(context);
                _showBreathingExercise();
              },
            ),

            _anxietyOption(
              icon: Icons.architecture_rounded,
              color: Colors.orange,
              title: "5-4-3-2-1 Grounding",
              subtitle: "Focus on your surroundings",
              onTap: () {
                Navigator.pop(context);
                _showGroundingExercise();
              },
            ),

            _anxietyOption(
              icon: Icons.chat_bubble_rounded,
              color: Colors.purple,
              title: "Talk to Memoir",
              subtitle: "Express what's on your mind",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _anxietyOption({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.lexend(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showBreathingExercise() {
    // Use a local controller within the dialog for the loop
    late AnimationController _breathingController;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Initialize inside the builder so we have access to the context
            _breathingController = AnimationController(
              vsync: Navigator.of(context),
              duration: const Duration(seconds: 4), // 4 seconds per breath phase
            );

            // Add listener for Voice Sync
            _breathingController.addStatusListener((status) {
              if (status == AnimationStatus.forward) {
                _voice.speak("Breathe in...");
              } else if (status == AnimationStatus.reverse) {
                _voice.speak("Breathe out...");
              }
            });

            // Start looping back and forth
            _breathingController.repeat(reverse: true);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Breathe with Memoir",
                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 50),

                  AnimatedBuilder(
                    animation: _breathingController,
                    builder: (context, child) {
                      // Scale from 1.0 to 1.8
                      double scale = 1.0 + (_breathingController.value * 0.8);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 20 * _breathingController.value,
                                spreadRadius: 10 * _breathingController.value,
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _breathingController.status == AnimationStatus.reverse
                                  ? "OUT" : "IN",
                              style: GoogleFonts.lexend(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () {
                      _breathingController.dispose();
                      Navigator.pop(context);
                      _voice.speak("I'm glad you're feeling better.");
                    },
                    child: const Text("I'M FEELING BETTER"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _showGroundingExercise() {
    int currentStep = 0;
    final steps = [
      {'count': 5, 'task': 'things you can see', 'voice': 'Look around. Tell me 5 things you can see.'},
      {'count': 4, 'task': 'things you can touch', 'voice': 'Great. Now, find 4 things you can touch.'},
      {'count': 3, 'task': 'things you can hear', 'voice': 'Listen closely. Identify 3 things you can hear.'},
      {'count': 2, 'task': 'things you can smell', 'voice': 'Almost there. Can you notice 2 things you can smell?'},
      {'count': 1, 'task': 'thing you can taste', 'voice': 'Finally, find 1 thing you can taste.'},
    ];

    _voice.speak(steps[0]['voice'] as String);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Grounding Exercise",
                    style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                const SizedBox(height: 30),

                // Large Step Number
                Text("${steps[currentStep]['count']}",
                    style: GoogleFonts.lexend(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.orange)),

                const SizedBox(height: 10),

                Text("Identify ${steps[currentStep]['task']}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w500)),

                const SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[50],
                      foregroundColor: Colors.orange[900],
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  onPressed: () {
                    if (currentStep < steps.length - 1) {
                      setDialogState(() {
                        currentStep++;
                      });
                      HapticFeedback.mediumImpact();
                      _voice.speak(steps[currentStep]['voice'] as String);
                    } else {
                      Navigator.pop(context);
                      _voice.speak("Excellent work. You are back in the present moment.");
                      _showSnackBar("Exercise Complete");
                    }
                  },
                  child: Text(currentStep == steps.length - 1 ? "FINISH" : "NEXT STEP"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}