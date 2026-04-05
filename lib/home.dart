import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'smart_eye_screen.dart';
import 'app_drawer.dart';
import 'reminders_screen.dart';
import 'chatbot.dart';
import 'family_page.dart';
import 'settings_provider.dart';
import 'visual_aide_screen.dart';
import 'sos_screen.dart';

class InteractiveFeatureCard extends StatelessWidget {
  const InteractiveFeatureCard({
    super.key,
    required this.iconWidget,
    required this.label,
    required this.onTap,
    required this.cardColor,
    required this.accentColor,
  });

  final Widget iconWidget;
  final String label;
  final VoidCallback onTap;
  final Color cardColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 3.0),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 15.0, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                child: iconWidget,
              ),
              const SizedBox(height: 12.0),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: settings.s(20.0),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2130),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _now;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => mounted ? setState(() => _now = DateTime.now()) : null);
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);
    const Color accentBlue = Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 180.0,
            pinned: true,
            leading: Builder(builder: (context) => IconButton(
              icon: const Icon(Icons.notes_rounded, size: 35.0, color: accentBlue),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Color(0xFFD6E4FF)])),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0, bottom: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome Home,", style: GoogleFonts.lexend(fontSize: 22.0, color: Colors.blueGrey)),
                      Text(settings.userName, style: GoogleFonts.lexend(fontSize: settings.s(42.0), fontWeight: FontWeight.w800, color: const Color(0xFF1A2130))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32.0)),
                child: Column(
                  children: [
                    Text(DateFormat('hh:mm a').format(_now), style: GoogleFonts.lexend(fontSize: settings.s(52.0), fontWeight: FontWeight.w900, color: accentBlue)),
                    Text(DateFormat('EEEE, MMMM d, y').format(_now), textAlign: TextAlign.center, style: GoogleFonts.lexend(fontSize: settings.s(20.0), color: Colors.blueGrey)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            //padding: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 120.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2, crossAxisSpacing: 18.0, mainAxisSpacing: 18.0, childAspectRatio: 0.9,
              children: [
                InteractiveFeatureCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RemindersScreen())),
                    iconWidget: const Icon(Icons.calendar_today_rounded, size: 38.0, color: Color(0xFFFFB38A)),
                    label: "My Schedule",
                    cardColor: const Color(0xFFFFF1E6),
                    accentColor: const Color(0xFFFFB38A)
                ),
                InteractiveFeatureCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
                    iconWidget: const Icon(Icons.forum_rounded, size: 38.0, color: Color(0xFF81C784)),
                    label: "Talk to Us",
                    cardColor: const Color(0xFFE8F5E9),
                    accentColor: const Color(0xFF81C784)
                ),
                InteractiveFeatureCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyPage())),
                    iconWidget: const Icon(Icons.favorite_rounded, size: 38.0, color: Color(0xFFFF8FA3)),
                    label: "Loved Ones",
                    cardColor: const Color(0xFFFFF0F3),
                    accentColor: const Color(0xFFFF8FA3)
                ),
                // InteractiveFeatureCard(
                //     // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VisualAideScreen())),
                //     // iconWidget: const Icon(Icons.visibility_rounded, size: 38.0, color: accentBlue),
                //     // label: "Helper Eye",
                //     // cardColor: const Color(0xFFD6E4FF),
                //     // accentColor: accentBlue
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => const VisualAideScreen(),
                //     ),
                //   ),
                //   iconWidget: const Icon(
                //     Icons.psychology,
                //     size: 38,
                //     color: Colors.deepPurple,
                //   ),
                //   label: "Smart AI",
                //   cardColor: Color(0xFFF3E5F5),
                //   accentColor: Colors.deepPurple,
                // ),
                InteractiveFeatureCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SOSScreen())),
                    iconWidget: const Icon(Icons.shield_rounded, size: 38.0, color: Color(0xFFD90429)),
                    label: "Get Help",
                    cardColor: const Color(0xFFFFE5E9), // Light red background
                    accentColor: const Color(0xFFD90429)
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 3.seconds, color: Colors.white)
                    .scale(end: const Offset(1.02, 1.02)),

              ],
            ),
          ),
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 120.0),
          //     child: GestureDetector(
          //       onTap: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(builder: (_) => SOSScreen()),
          //         );
          //       },
          //       child: Container(
          //         height: 110.0,
          //         decoration: BoxDecoration(
          //           gradient: const LinearGradient(
          //             colors: [Color(0xFFD90429), Color(0xFFFF4D6D)],
          //           ),
          //           borderRadius: BorderRadius.circular(30.0),
          //         ),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             const Icon(Icons.shield_rounded, color: Colors.white, size: 45.0),
          //             const SizedBox(width: 15.0),
          //             Column(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 Text("I NEED HELP",
          //                     style: GoogleFonts.lexend(
          //                         color: Colors.white,
          //                         fontSize: settings.s(24.0),
          //                         fontWeight: FontWeight.w900)),
          //                 Text("Press here to call for support",
          //                     style: GoogleFonts.lexend(
          //                         color: Colors.white.withOpacity(0.9),
          //                         fontSize: settings.s(14.0))),
          //               ],
          //             ),
          //           ],
          //         ),
          //       )
          //           .animate(onPlay: (c) => c.repeat(reverse: true))
          //           .shimmer(duration: 2.seconds)
          //           .scale(end: const Offset(1.03, 1.03)),
          //     ),
          //   ),
          // ),
        ],
      ),

      // ACCESSIBLE BOTTOM BAR INCORPORATED HERE
      bottomNavigationBar: Container(
        height: 90.0,
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.0, offset: const Offset(0, -5))]
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            Text("Text Size:", style: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 16.0)),
            const Spacer(),
            // Decrease button
            _buildSizeButton(Icons.text_fields, 20.0, () {
              double current = settings.fontSizeMultiplier;
              if (current > 0.85) {
                settings.updateFontSize(current - 0.1);
              }
            }, accentBlue),
            const SizedBox(width: 20.0),
            // Increase button
            _buildSizeButton(Icons.text_fields, 34.0, () {
              double current = settings.fontSizeMultiplier;
              if (current < 1.45) {
                settings.updateFontSize(current + 0.1);
              }
            }, accentBlue),
          ],
        ),
      ),
    );
  }

  // Helper widget for the increase/decrease buttons
  Widget _buildSizeButton(IconData icon, double iconSize, VoidCallback onPress, Color color) {
    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(15.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}