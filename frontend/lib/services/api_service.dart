import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get _base {
    if (kIsWeb) return 'http://localhost:8001/api/v1';
    
    // For Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android && !kDebugMode) {
      // In prod/real device, use local IP. 
      // Replace with your tunnel URL for external network access.
      return 'http://10.1.5.96:8001/api/v1'; 
    }
    
    // Default for Linux Desktop and Real Devices on same WiFi
    // 10.1.5.96 is your computer's current local IP
    return 'http://10.1.5.96:8001/api/v1';
  }

  // ─── Token Management ─────────────────────────────────────── //
  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token',  data['access_token']  ?? '');
    await prefs.setString('refresh_token', data['refresh_token'] ?? '');
    await prefs.setInt   ('user_id',       data['user_id']       ?? 0);
    await prefs.setInt   ('workspace_id',  data['workspace_id']  ?? 0);
  }

  static Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  static Future<int> getWorkspaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('workspace_id') ?? 0;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _post(String path, Map body) async {
    final headers = await _authHeaders();
    return http.post(Uri.parse('$_base$path'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> _get(String path) async {
    final headers = await _authHeaders();
    return http.get(Uri.parse('$_base$path'), headers: headers);
  }

  static Future<http.Response> _patch(String path, Map body) async {
    final headers = await _authHeaders();
    return http.patch(Uri.parse('$_base$path'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> _delete(String path) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse('$_base$path'), headers: headers);
  }

  // ─── Auth ─────────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> signup(String email, String password, String name) async {
    final res = await _post('/auth/signup', {'email': email, 'password': password, 'name': name});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveSession(data);
      return data;
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Signup failed');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _post('/auth/login', {'email': email, 'password': password});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveSession(data);
      return data;
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token') ?? '';
    if (refresh.isNotEmpty) {
      await _post('/auth/logout', {'refresh_token': refresh});
    }
    await clearSession();
  }

  // ─── Dashboard ────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/dashboard/stats?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  static Future<List<String>> fetchInsights() async {
    final res = await _get('/dashboard/insights');
    if (res.statusCode == 200) return List<String>.from(jsonDecode(res.body));
    return [];
  }

  // ─── Chat ─────────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> sendMessage(String msg) async {
    final userId = await getUserId();
    final wsId = await getWorkspaceId();
    final res = await _post('/chat', {
      'message': msg,
      if (userId > 0) 'user_id': userId,
      if (wsId > 0) 'workspace_id': wsId,
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {'response': 'Error: ${res.statusCode}', 'chat_id': null};
  }

  static Future<void> rateMessage(int chatId, String feedback) async {
    await _post('/chat/$chatId/feedback', {'chat_id': chatId, 'feedback': feedback});
  }

  static Future<List<Map<String, dynamic>>> fetchChatHistory() async {
    final userId = await getUserId();
    final res = await _get('/dashboard/history?user_id=$userId');
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return [];
  }

  // ─── Alerts ───────────────────────────────────────────────── //
  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/alerts?workspace_id=$wsId');
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return [];
  }

  // ─── Profile ──────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> fetchProfile() async {
    final userId = await getUserId();
    if (userId == 0) return {};
    final res = await _get('/profile/$userId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = await getUserId();
    await _patch('/profile/$userId', data);
  }

  // ─── Analytics ────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> fetchForecast(List<double> data) async {
    final res = await _post('/analytics/forecast', {'historical': data, 'periods_ahead': 4});
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Forecast failed');
  }

  static Future<List<dynamic>> fetchAnomalies(List<double> data) async {
    final res = await _post('/analytics/anomaly', {'series': data});
    if (res.statusCode == 200) return jsonDecode(res.body)['anomalies'];
    return [];
  }

  // ─── Market Intelligence ──────────────────────────────────── //
  static Future<List<dynamic>> fetchMarketNews(String topic) async {
    final res = await _get('/market/news?topic=${Uri.encodeComponent(topic)}');
    if (res.statusCode == 200) return jsonDecode(res.body)['articles'];
    return [];
  }

  // ─── Strategy ─────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> fetchSWOT() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/strategy/swot?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // ─── Ideas ────────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> generateIdeas(String domain, {int n = 4}) async {
    final wsId = await getWorkspaceId();
    final res = await _post('/ideas/generate', {'domain': domain, 'workspace_id': wsId, 'n_ideas': n});
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Idea generation failed');
  }

  static Future<List<dynamic>> fetchSavedIdeas() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/ideas?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // ─── OKRs ─────────────────────────────────────────────────── //
  static Future<List<dynamic>> fetchOKRs() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/okr?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> createOKR(String objective, List<Map<String, dynamic>> keyResults) async {
    final wsId = await getWorkspaceId();
    final res = await _post('/okr?workspace_id=$wsId', {'objective': objective, 'key_results': keyResults});
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('OKR creation failed');
  }

  static Future<void> updateOKR(int okrId, List<Map<String, dynamic>> keyResults) async {
    await _patch('/okr/$okrId', {'key_results': keyResults});
  }

  // ─── Subscription ─────────────────────────────────────────── //
  static Future<Map<String, dynamic>> fetchSubscription() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/subscription?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // ─── Workspace & Tasks ────────────────────────────────────── //
  static Future<List<dynamic>> fetchTasks() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/workspace/$wsId/tasks');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> createTask(String title, {String? description}) async {
    final wsId = await getWorkspaceId();
    final res = await _post('/workspace/$wsId/tasks', {'title': title, 'description': description ?? ''});
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Task creation failed');
  }

  static Future<void> updateTaskStatus(int taskId, String status) async {
    final wsId = await getWorkspaceId();
    await _patch('/workspace/$wsId/tasks/$taskId', {'status': status});
  }

  // ─── AI Status ────────────────────────────────────────────── //
  static Future<Map<String, dynamic>> fetchAIStatus() async {
    final res = await _get('/ai/status');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // ─── Integrations ─────────────────────────────────────────── //
  static Future<List<dynamic>> fetchIntegrations() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/integrations?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<void> saveSlackIntegration(String webhookUrl) async {
    final wsId = await getWorkspaceId();
    await _post('/integrations', {
      'workspace_id': wsId,
      'type': 'slack',
      'config': {'webhook_url': webhookUrl},
    });
  }

  // ─── Developer Keys ───────────────────────────────────────── //
  static Future<List<dynamic>> fetchApiKeys() async {
    final wsId = await getWorkspaceId();
    final res = await _get('/developer/api-keys?workspace_id=$wsId');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<String> createApiKey(String label) async {
    final wsId = await getWorkspaceId();
    final res = await _post('/developer/api-key?workspace_id=$wsId&label=${Uri.encodeComponent(label)}', {});
    if (res.statusCode == 200) return jsonDecode(res.body)['api_key'];
    throw Exception('Key generation failed');
  }
}
