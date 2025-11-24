import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_drawer.dart';
import 'reminders.dart';
import 'chatbot.dart';
import 'family_page.dart';
import 'settings_provider.dart';

// WIDGET 1: The interactive, 3D tilting feature card
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
              elevation: 8,
              shadowColor: widget.cardColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.cardColor.withOpacity(0.3),
                        Colors.white,
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.cardColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: widget.iconWidget,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: (18 * widget.fontSizeMultiplier).toDouble(),
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                            fontFamily: 'Raleway',
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
    const Color lightGreenCard = Color(0xFFE8F5E9);
    const Color lightTealCard = Color(0xFFE0F2F1);

    final List<Map<String, dynamic>> featureItems = [
      {'icon': const Icon(Icons.notifications_active_rounded, size: 32, color: primaryTextColor),
        'label': 'Reminders',
        'color': lightTealCard,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReminderPage())),
      },
      {'icon': SvgPicture.asset('assets/images/chat.svg', height: 32, width: 32, colorFilter: const ColorFilter.mode(primaryTextColor, BlendMode.srcIn)),
        'label': 'Chat Buddy',
        'color': lightGreenCard,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
      },
      {
        'icon': SvgPicture.asset('assets/images/photos.svg',  height: 32, width: 32, colorFilter: const ColorFilter.mode(primaryTextColor, BlendMode.srcIn)),
        'label': 'Loved Ones',
        'color': lightGreenCard,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyPage())),
      },
      {'icon': SvgPicture.asset('assets/images/games.svg', height: 32, width: 32, colorFilter: const ColorFilter.mode(primaryTextColor, BlendMode.srcIn)),
        'label': 'Games',
        'color': lightTealCard,
        'onTap': () {},
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      drawer: const AppDrawer(),
      body: Builder(
        builder: (scaffoldContext) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                // --- FIX 1: Increased height to 280 to give more room ---
                expandedHeight: 218,
                stretch: true,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  background: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Decorative Circles
                      Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1))),
                      Positioned(bottom: -30, left: 20, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.1))),

                      // --- FIX 2: Increased bottom padding to 80 ---
                      // This pushes the "Good Morning" and Name UP, away from the overlapping time box.
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formattedDate(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const Spacer(),
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                  fontSize: 28 * settings.fontSizeMultiplier,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withOpacity(0.9)),
                            ).animate().fadeIn().slideX(),
                            Text(
                              'Sanskriti',
                              style: TextStyle(
                                  fontSize: 36 * settings.fontSizeMultiplier,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1),
                            ).animate().fadeIn(delay: 200.ms).slideX(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Time Capsule
              SliverToBoxAdapter(
                child: Transform.translate(
                  // This pulls the box up slightly to overlap the green header
                  // nicely, but because we added padding above, it won't cover text.
                  offset: const Offset(0, 6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_filled, color: Color(0xFF26A69A)),
                          const SizedBox(width: 10),
                          Text(
                            _formattedTime(),
                            style: TextStyle(
                              fontSize: 18 * settings.fontSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF004D40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
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

              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(80, 24, 80, 40),
              //     child: Container(
              //       decoration: BoxDecoration(
              //         color: Colors.white,
              //         borderRadius: BorderRadius.circular(40), // Pill shape
              //         boxShadow: [
              //           BoxShadow(
              //             color: const Color(0xFF26A69A).withOpacity(0.15),
              //             blurRadius: 15,
              //             offset: const Offset(0, 8),
              //           ),
              //         ],
              //       ),
              //       child: Material(
              //         color: Colors.transparent,
              //         child: InkWell(
              //           onTap: _showFontSizeSlider,
              //           borderRadius: BorderRadius.circular(40),
              //           child: Padding(
              //             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              //             child: Row(
              //               mainAxisAlignment: MainAxisAlignment.center,
              //               children: [
              //                 // 1. The Icon Bubble
              //                 Container(
              //                   padding: const EdgeInsets.all(10),
              //                   decoration: BoxDecoration(
              //                     color: const Color(0xFFE0F2F1), // Soft Teal
              //                     shape: BoxShape.circle,
              //                   ),
              //                   child: Icon(
              //                     Icons.format_size_rounded, // Better icon for "Size"
              //                     color: const Color(0xFF004D40),
              //                     size: 22 * settings.fontSizeMultiplier,
              //                   ),
              //                 ),
              //
              //                 const SizedBox(width: 16),
              //
              //                 // 2. The Text
              //                 Text(
              //                   'Adjust Text Size',
              //                   style: TextStyle(
              //                     color: const Color(0xFF004D40),
              //                     fontSize: 16 * settings.fontSizeMultiplier,
              //                     fontWeight: FontWeight.bold,
              //                     letterSpacing: 0.5,
              //                   ),
              //                 ),
              //
              //                 const SizedBox(width: 12),
              //               ],
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),


              // SliverToBoxAdapter(
              //
              //   child: Center(
              //
              //     child: Padding(
              //
              //       padding: const EdgeInsets.all(32.0),
              //
              //       child: TextButton.icon(
              //
              //         onPressed: _showFontSizeSlider,
              //
              //         icon: Icon(Icons.text_fields_rounded, color: primaryTextColor.withOpacity(0.7)),
              //
              //         label: Text('Text Size', style: TextStyle(color: primaryTextColor.withOpacity(0.7), fontSize: 16)),
              //
              //         style: TextButton.styleFrom(
              //
              //           backgroundColor: Colors.white,
              //
              //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              //
              //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              //
              //         ),
              //
              //       ),
              //
              //     ),
              //
              //   ),
              //
              // ),

              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: TextButton(
                      onPressed: _showFontSizeSlider,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        // Using a standard rounded rect, not a pill
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        elevation: 0, // Flat look you prefer
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The nice Icon Bubble you liked
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1), // Soft Teal
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.format_size_rounded,
                              color: const Color(0xFF004D40),
                              size: 20 * settings.fontSizeMultiplier,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // The Bold Text
                          Text(
                            'Adjust Text Size',
                            style: TextStyle(
                              color: const Color(0xFF004D40).withOpacity(0.7),
                              fontSize: 16 * settings.fontSizeMultiplier,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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