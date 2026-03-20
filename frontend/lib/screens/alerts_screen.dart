import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(title: Text("Intelligence Alerts")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildAlertItem("Revenue Anomaly", "Unusual dip in city center region.", Icons.warning, Colors.orange),
          _buildAlertItem("Market Opportunity", "High sentiment detected for green energy.", Icons.trending_up, Colors.green),
          _buildAlertItem("System Update", "New AI weights deployed to backend.", Icons.info, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String details, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text(details, style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
