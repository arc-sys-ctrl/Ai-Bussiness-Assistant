import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await ApiService.fetchAlerts();
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text("Intelligence Alerts"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () {
            setState(() => _isLoading = true);
            _loadAlerts();
          }),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _alerts.isEmpty
          ? Center(child: Text("No alerts found.", style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return _buildAlertItem(
                  alert["title"] ?? "Unknown",
                  alert["details"] ?? "",
                  _getIcon(alert["level"]),
                  _getColor(alert["level"]),
                );
              },
            ),
    );
  }

  IconData _getIcon(String? level) {
    switch (level) {
      case 'warning': return Icons.report_problem;
      case 'success': return Icons.check_circle;
      case 'info': return Icons.info_outline;
      default: return Icons.notification_important;
    }
  }

  Color _getColor(String? level) {
    switch (level) {
      case 'warning': return Colors.orange;
      case 'success': return Colors.green;
      case 'info': return Colors.blue;
      default: return Colors.blueGrey;
    }
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
