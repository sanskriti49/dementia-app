// lib/home.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_drawer.dart';
import 'reminders.dart';
import 'chatbot.dart';
import 'settings_provider.dart';

// ... (SectionTitle and InteractiveFeatureCard widgets remain the same)
// ... (No changes needed in the widgets above this point)

// WIDGET 1: A reusable title for sections of the UI.
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF004D40);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18 * SettingsProvider.of(context).fontSizeMultiplier,
          fontWeight: FontWeight.bold,
          color: primaryTextColor.withOpacity(0.8),
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideX(begin: -0.1),
    );
  }
}

// WIDGET 2: The interactive, 3D tilting feature card.
class InteractiveFeatureCard extends StatefulWidget {
  const InteractiveFeatureCard({
    Key? key,
    required this.iconWidget,
    required this.label,
    required this.onTap,
    required this.cardColor,
    required this.textColor,
    required this.fontSizeMultiplier,
  }) : super(key: key);

  final Widget iconWidget;
  final String label;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textColor;
  final double fontSizeMultiplier;

  @override
  State<InteractiveFeatureCard> createState() => _InteractiveFeatureCardState();
}

class _InteractiveFeatureCardState extends State<InteractiveFeatureCard> {
  double _x = 0.0;
  double _y = 0.0;
  final double _amplitude = 0.1;

  void _updateTilt(Offset localPosition, Size size) {
    setState(() {
      _x = (localPosition.dy / size.height - 0.5) * 2;
      _y = -(localPosition.dx / size.width - 0.5) * 2;
    });
  }

  void _resetTilt() => setState(() { _x = 0; _y = 0; });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: (details) => _updateTilt(details.localPosition, (context.findRenderObject() as RenderBox).size),
      onPanEnd: (_) => _resetTilt(),
      onPanCancel: () => _resetTilt(),
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 150),
        tween: Tween<double>(begin: _x, end: _x),
        builder: (context, double x, child) {
          return TweenAnimationBuilder(
            duration: const Duration(milliseconds: 150),
            tween: Tween<double>(begin: _y, end: _y),
            builder: (context, double y, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(x * _amplitude)
                  ..rotateY(y * _amplitude),
                alignment: FractionalOffset.center,
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              elevation: 6,
              shadowColor: widget.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.iconWidget,
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: (16 * widget.fontSizeMultiplier).toDouble(),
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// The main HomePage widget.
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
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _getGreeting() {
    final hour = _now.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }

  String _formattedDate() => '${DateFormat('EEEE, MMMM').format(_now)} ${_now.day}${_getDaySuffix(_now.day)}';
  String _formattedTime() => DateFormat('hh:mm a').format(_now);

  void _showFontSizeSlider() {
    final settings = SettingsProvider.of(context);
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Adjust Font Size', style: TextStyle(
                        fontSize: (20 * settings.fontSizeMultiplier).toDouble(),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF004D40))),
                    const SizedBox(height: 16),
                    Slider(
                      value: settings.fontSizeMultiplier, min: 0.8, max: 1.5, divisions: 7,
                      label: '${(settings.fontSizeMultiplier * 100).toStringAsFixed(0)}%',
                      activeColor: const Color(0xFF26A69A),
                      inactiveColor: Colors.grey[300],
                      onChanged: (newValue) {
                        setModalState(() => settings.updateFontSize(newValue));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    const Color primaryTextColor = Color(0xFF004D40);
    const Color lightGreenCard = Color(0xFFC8E6C9);
    const Color lightTealCard = Color(0xFFA6E4D9);

    final List<Map<String, dynamic>> featureItems = [
      {'icon': const Icon(Icons.notifications_active_rounded, size: 48, color: primaryTextColor),
        'label': 'Reminders',
        'color': lightTealCard,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReminderPage())),
      },
      {'icon': SvgPicture.asset('assets/images/chat.svg', height: 48, width: 48, colorFilter: const ColorFilter.mode(primaryTextColor, BlendMode.srcIn)),
        'label': 'Chat Buddy',
        'color': lightGreenCard,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
      },
      {'icon': SvgPicture.asset('assets/images/photos.svg', height: 48, width: 48, colorFilter: const ColorFilter.mode(primaryTextColor, BlendMode.srcIn)),
        'label': 'Memories',
        'color': lightGreenCard,
        'onTap': () {},
      },
      {'icon': SvgPicture.asset('assets/images/games.svg', height: 48, width: 48, colorFilter: const ColorFilter.mode(primaryTextColor, BlendMode.srcIn)),
        'label': 'Games',
        'color': lightTealCard,
        'onTap': () {},
      },
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      // ✨ FIX: Wrap the body of the Scaffold in a Builder
      body: Builder(
        builder: (scaffoldContext) { // This `scaffoldContext` is now a child of the Scaffold
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                expandedHeight: 170,
                stretch: true,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(bottom: 10),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: topPadding, right: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                            onPressed: () {
                              // ✨ FIX: Use the new `scaffoldContext` to find the Scaffold
                              Scaffold.of(scaffoldContext).openDrawer();
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                      fontSize: 32 * settings.fontSizeMultiplier,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white.withOpacity(0.8)),
                                ),
                                Text(
                                  'Sanskriti',
                                  style: TextStyle(
                                      fontSize: 32 * settings.fontSizeMultiplier,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primaryTextColor.withOpacity(0.6), size: 16),
                      const SizedBox(width: 8),
                      Text(_formattedDate(), style: TextStyle(fontSize: 14 * settings.fontSizeMultiplier, color: primaryTextColor.withOpacity(0.8))),
                      const Spacer(),
                      Icon(Icons.access_time, color: primaryTextColor.withOpacity(0.6), size: 16),
                      const SizedBox(width: 8),
                      Text(_formattedTime(), style: TextStyle(fontSize: 14 * settings.fontSizeMultiplier, color: primaryTextColor.withOpacity(0.8))),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
              ),
              const SliverToBoxAdapter(child: SectionTitle(title: 'Explore Features')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1),
                  itemCount: featureItems.length,
                  itemBuilder: (context, index) {
                    final item = featureItems[index];
                    return InteractiveFeatureCard(
                      iconWidget: item['icon'],
                      label: item['label'],
                      cardColor: item['color'],
                      textColor: primaryTextColor,
                      onTap: item['onTap'],
                      fontSizeMultiplier: settings.fontSizeMultiplier,
                    ).animate()
                        .fadeIn(duration: 600.ms, delay: (150 * index).ms)
                        .scaleXY(begin: 0.8, duration: 400.ms, curve: Curves.easeOutBack);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: TextButton.icon(
                    onPressed: _showFontSizeSlider,
                    icon: Icon(Icons.font_download, color: primaryTextColor.withOpacity(0.7)),
                    label: Text('Change Font Size', style: TextStyle(color: primaryTextColor.withOpacity(0.7))),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}