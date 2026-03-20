import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F2027),
      appBar: AppBar(title: Text("Company Profile")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.business, size: 50, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text("Arc-Sys-Ctrl Ltd.", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Enterprise Suite", style: TextStyle(color: Colors.white54, fontSize: 16)),
              SizedBox(height: 40),
              _buildInfoRow(Icons.location_on, "Primary Region", "North America"),
              _buildInfoRow(Icons.category, "Industry", "Financial Technology"),
              _buildInfoRow(Icons.people, "Team Size", "50-200 Employees"),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: Text("Edit Business Details", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
