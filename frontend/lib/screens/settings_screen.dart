import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSwitchTile("Enable AI Notifications", true),
          _buildSwitchTile("Auto-predict Revenue", false),
          _buildSwitchTile("High Precision Mode", true),
          Divider(color: Colors.white24, height: 40),
          _buildActionTile("API Key Configuration", Icons.vpn_key),
          _buildActionTile("Connected Accounts", Icons.account_tree),
          _buildActionTile("Clear Search History", Icons.delete_sweep, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: Colors.white)),
      value: value,
      onChanged: (bool newValue) {},
      activeColor: Colors.blueAccent,
    );
  }

  Widget _buildActionTile(String title, IconData icon, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}
