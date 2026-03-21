import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/aura_drawer.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {
    "projected_revenue": "Loading...",
    "market_sentiment": "Loading...",
    "security_alerts": "Loading...",
  };
  List<String> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await ApiService.fetchDashboardStats();
    final insights = await ApiService.fetchInsights();
    if (mounted) {
      setState(() {
        _stats = stats;
        _insights = insights;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F2027),
      drawer: const AuraDrawer(),
      appBar: AppBar(
        title: Text("Intelligence Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatCard("Projected Revenue", _stats["projected_revenue"], Icons.account_balance, Colors.green),
                SizedBox(height: 16),
                _buildStatCard("Market Sentiment", _stats["market_sentiment"], Icons.psychology, Colors.blue),
                SizedBox(height: 16),
                _buildStatCard("Active Security Alerts", _stats["security_alerts"], Icons.gpp_good, Colors.orange),
                SizedBox(height: 30),
                Text("Recent AI Insights", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                ..._insights.map((insight) => _buildInsightItem(insight)).toList(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
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
          Icon(Icons.tips_and_updates, color: Colors.yellow, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}
