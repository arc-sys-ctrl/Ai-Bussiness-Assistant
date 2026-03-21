import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/market_screen.dart';
import '../screens/ideas_screen.dart';
import '../screens/okr_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

class AuraDrawer extends StatelessWidget {
  const AuraDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A1628),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Image.asset('assets/images/ai_logo.png', height: 50),
                const SizedBox(height: 10),
                const Text("AURA Suite", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const Text("Enterprise Intelligence Platform", style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            ),

            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
                _section("CORE"),
                _drawerItem(context, Icons.dashboard_rounded,       "Dashboard",         () => DashboardScreen()),
                _drawerItem(context, Icons.chat_bubble_outline,     "AI Assistant",      () => ChatScreen()),
                _drawerItem(context, Icons.analytics_outlined,      "Analytics",         () => AnalyticsScreen()),

                _section("WORKSPACE"),
                _drawerItem(context, Icons.task_alt_outlined,       "Tasks",             () => TasksScreen()),
                _drawerItem(context, Icons.flag_outlined,           "OKR Tracker",       () => OKRScreen()),
                _drawerItem(context, Icons.lightbulb_outline,       "Idea Engine",       () => IdeasScreen()),

                _section("INTELLIGENCE"),
                _drawerItem(context, Icons.newspaper_outlined,      "Market Intelligence", () => MarketScreen()),
                _drawerItem(context, Icons.notifications_outlined,  "Alerts",            () => AlertsScreen()),
                _drawerItem(context, Icons.history,                 "Chat History",      () => HistoryScreen()),

                _section("ACCOUNT"),
                _drawerItem(context, Icons.person_outline,          "Profile",           () => ProfileScreen()),
                _drawerItem(context, Icons.settings_outlined,       "Settings",          () => SettingsScreen()),
              ]),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.red.withOpacity(0.05),
                onTap: () async {
                  await ApiService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (_) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
      child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _drawerItem(BuildContext ctx, IconData icon, String label, Widget Function() builder) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      hoverColor: Colors.white.withOpacity(0.04),
      onTap: () {
        Navigator.pop(ctx);
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => builder()));
      },
    );
  }
}
