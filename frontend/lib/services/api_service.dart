import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use the Nginx proxy address. 10.0.2.2 is usually the host machine in Android emulators.
  static const String baseUrl = "http://10.0.2.2/api/v1/chat"; 
  static const String dashboardUrl = "http://10.0.2.2/api/v1/dashboard";

  static Future<String> sendMessage(String msg) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": msg}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body)["response"];
      } else {
        return "Error: ${res.statusCode} - ${res.reasonPhrase}";
      }
    } catch (e) {
      return "Connection Error: Please ensure the backend is running.";
    }
  }

  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final res = await http.get(Uri.parse("$dashboardUrl/stats"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Error fetching stats: $e");
    }
    return {
      "projected_revenue": "N/A",
      "market_sentiment": "N/A",
      "security_alerts": "N/A",
    };
  }

  static Future<List<String>> fetchInsights() async {
    try {
      final res = await http.get(Uri.parse("$dashboardUrl/insights"));
      if (res.statusCode == 200) {
        return List<String>.from(jsonDecode(res.body));
      }
    } catch (e) {
      print("Error fetching insights: $e");
    }
    return ["Unable to load insights."];
  }

  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final res = await http.get(Uri.parse("http://10.0.2.2/api/v1/alerts"));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final res = await http.get(Uri.parse("http://10.0.2.2/api/v1/profile"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return {};
  }
}
