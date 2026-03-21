import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _profile = {
    "name": "Loading...",
    "suite": "Enterprise Suite",
    "region": "N/A",
    "industry": "N/A",
    "team_size": "N/A",
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ApiService.fetchProfile();
    if (mounted && profile.isNotEmpty) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F2027),
      appBar: AppBar(title: Text("Company Profile")),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Image.asset('assets/images/ai_logo.png', height: 100),
                  ),
                  SizedBox(height: 16),
                  Text(_profile["name"], style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_profile["suite"], style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 40),
                  _buildInfoRow(Icons.map, "Primary Region", _profile["region"]),
                  _buildInfoRow(Icons.domain, "Industry", _profile["industry"]),
                  _buildInfoRow(Icons.groups_3, "Team Size", _profile["team_size"]),
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
          Icon(icon, color: Colors.blueAccent, size: 24),
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
