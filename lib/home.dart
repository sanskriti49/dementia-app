import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'chatbot.dart';

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
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formattedDate() {
    return '${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year}';
  }

  String _formattedTime() {
    return '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
             UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2D6A4F)),
               accountName: Text(
                 'Sanskriti Gupta',
                 style: TextStyle(fontSize: 18),
               ),
               accountEmail: Row(
                 children: [
                   Icon(Icons.call, size: 16, color: Colors.white70),
                   SizedBox(width: 6),
                   Text(
                     '+91 012345678',
                     style: TextStyle(fontSize: 14, color: Colors.white70),
                   ),
                 ],
               ),
               currentAccountPicture: CircleAvatar(
                 backgroundColor: Colors.white,
                 child: Icon(Icons.person, color: Color(0xFF2D6A4F), size:44),
               ),
               // child: Text(
               //  'Welcome, Sanskriti',
               //  style: TextStyle(
               //    color: Colors.white,
               //    fontSize: 22,
               //    fontWeight: FontWeight.bold,
               //  ),\
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chatbot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // logout logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () {
                // logout logic
              },
            ),
          ],
        ),
      ),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: const Color(0xFF2D6A4F),
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
              title: const Text(
                'Dementia Care',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 120.0, left: 16.0, right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),

              const Text(
                'Good Morning, Sanskriti!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40),
                  fontFamily: 'Inter',
                ),
              ),

              const SizedBox(height: 20),



              // Container(
              //   margin: const EdgeInsets.only(top: 10),
              //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(16),
              //     color: const Color(0xFFa6c6b7).withOpacity(0.25),
              //     boxShadow: const [
              //       BoxShadow(
              //         color: Colors.teal,
              //         blurRadius: 2,
              //         offset: Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     children: [
              //       Text(
              //         _formattedDate(),
              //         textAlign: TextAlign.center,
              //         style: const TextStyle(
              //           fontSize: 18,
              //           color: Color(0xFF004D40),
              //           fontFamily: 'Inter',
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         _formattedTime(),
              //         textAlign: TextAlign.center,
              //         style: const TextStyle(
              //           fontSize: 26,
              //           fontWeight: FontWeight.bold,
              //           color: Color(0xFF004D40),
              //           fontFamily: 'Inter',
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F2F1), Color(0xFFBFE0D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _formattedDate(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formattedTime(),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Open Chatbot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
