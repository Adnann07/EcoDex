import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://ecodex-production.up.railway.app';
  static String? _token;

  static void setToken(String token) => _token = token;

  static Future<void> addPoints(int points) async {
    if (_token == null) return;
    await http.post(
      Uri.parse('$_baseUrl/api/points/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'points': points}),
    );
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/leaderboard'));
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['leaderboard']);
  }
}