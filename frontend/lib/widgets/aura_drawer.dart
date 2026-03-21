import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/history_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';

class AuraDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF1E1E1E),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/ai_logo.png', height: 60),
                  SizedBox(height: 10),
                  Text("AURA Suite", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, "Dashboard", DashboardScreen()),
          _buildDrawerItem(context, Icons.chat, "AURA Assistant", ChatScreen()),
          _buildDrawerItem(context, Icons.history, "History", HistoryScreen()),
          _buildDrawerItem(context, Icons.notifications, "Alerts", AlertsScreen()),
          _buildDrawerItem(context, Icons.settings, "Settings", SettingsScreen()),
          _buildDrawerItem(context, Icons.business, "Profile", ProfileScreen()),
          Spacer(),
          Divider(color: Colors.white24),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
      },
    );
  }
}
