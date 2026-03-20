import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F2027),
      appBar: AppBar(
        title: Text("Intelligence Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Projected Revenue", "\$42,500", Icons.trending_up, Colors.green),
            SizedBox(height: 16),
            _buildStatCard("Market Sentiment", "Positive (0.84)", Icons.analytics, Colors.blue),
            SizedBox(height: 16),
            _buildStatCard("Active Security Alerts", "None", Icons.security, Colors.orange),
            SizedBox(height: 30),
            Text("Recent AI Insights", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildInsightItem("Expand operations in city center based on peak demand analysis."),
            _buildInsightItem("Increase stock for electronic components for next quarter."),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}
