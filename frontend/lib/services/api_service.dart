import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use the Nginx proxy address. 10.0.2.2 is usually the host machine in Android emulators.
  static const String baseUrl = "http://10.0.2.2/chat"; 

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
}
