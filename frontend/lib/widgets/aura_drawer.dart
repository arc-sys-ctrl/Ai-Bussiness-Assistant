import 'package:flutter/material.dart';
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
                _drawerItem(context, Icons.dashboard_rounded,       "Dashboard",         "/dashboard"),
                _drawerItem(context, Icons.chat_bubble_outline,     "AI Assistant",      "/chat"),
                _drawerItem(context, Icons.analytics_outlined,      "Analytics",         "/analytics"),

                _section("WORKSPACE"),
                _drawerItem(context, Icons.task_alt_outlined,       "Tasks",             "/tasks"),
                _drawerItem(context, Icons.flag_outlined,           "OKR Tracker",       "/okr"),
                _drawerItem(context, Icons.lightbulb_outline,       "Idea Engine",       "/ideas"),

                _section("INTELLIGENCE"),
                _drawerItem(context, Icons.newspaper_outlined,      "Market Intelligence", "/market"),
                _drawerItem(context, Icons.notifications_outlined,  "Alerts",            "/alerts"),
                _drawerItem(context, Icons.history,                 "Chat History",      "/history"),

                _section("ACCOUNT"),
                _drawerItem(context, Icons.person_outline,          "Profile",           "/profile"),
                _drawerItem(context, Icons.settings_outlined,       "Settings",          "/settings"),
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
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

  Widget _drawerItem(BuildContext ctx, IconData icon, String label, String route) {
    final currentRoute = ModalRoute.of(ctx)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.blueAccent, size: 22),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
      hoverColor: Colors.white.withOpacity(0.04),
      onTap: () {
        Navigator.pop(ctx);
        if (!isSelected) {
          Navigator.pushReplacementNamed(ctx, route);
        }
      },
    );
  }
}
