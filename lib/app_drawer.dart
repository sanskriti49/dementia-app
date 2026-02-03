

import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'reminders.dart';
import 'visual_aide_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // track the selected item and highlight it
  int _selectedIndex = 0;

  void _onItemTapped(int index, VoidCallback navigate) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), navigate);     // delay allows the drawer to close smoothly before navigating
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  text: 'Home',
                  index: 0,
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_active_rounded,
                  text: 'Reminders',
                  index: 1,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReminderPage())),
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  text: 'Chat Buddy',
                  index: 2,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
                ),
                _buildDrawerItem(
                  icon: Icons.visibility_rounded,
                  text: 'Magic Eye',
                  index: 3, // Unique index
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VisualAideScreen())),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  text: 'Settings',
                  index: 3,
                  onTap: () { /* Navigate to Settings page */ },
                ),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            text: 'Logout',
            index: 4, // Use a different index
            onTap: () { /* Handle logout logic */ },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return const UserAccountsDrawerHeader(
      accountName: Text(
        'Sanskriti',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      accountEmail: Text('Your Personal Companion'),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          'S',
          style: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
          ),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.teal.withOpacity(0.1),
      onTap: () => _onItemTapped(index, onTap),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}