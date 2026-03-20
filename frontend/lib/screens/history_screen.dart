import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(title: Text("Chat History")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildHistoryItem("Revenue Forecast Q3", "2026-03-15"),
          _buildHistoryItem("Market Analysis: Tech Sector", "2026-03-14"),
          _buildHistoryItem("Security Protocol Audit", "2026-03-12"),
          _buildHistoryItem("Transport Logistics Optimization", "2026-03-10"),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.history, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text(date, style: TextStyle(color: Colors.white54)),
        trailing: Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}
