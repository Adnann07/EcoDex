import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://ecodex-production.up.railway.app';
  static String? _token;

  static void setToken(String token) => _token = token;

  static Future<void> addScan({
    required String itemName,
    required String category,
    required String emoji,
    required int confidence,
  }) async {
    if (_token == null) return;
    await http.post(
      Uri.parse('$_baseUrl/api/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'item_name':  itemName,
        'category':   category,
        'emoji':      emoji,
        'confidence': confidence,
      }),
    );
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/leaderboard'));
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['leaderboard']);
  }

  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    if (_token == null) return [];
    final res = await http.get(
      Uri.parse('$_baseUrl/api/scan/history'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['history']);
  }
}