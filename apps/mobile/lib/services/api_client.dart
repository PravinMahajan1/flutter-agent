import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_store.dart';

class ApiClient {
  ApiClient(this.auth);
  final AuthStore auth;

  // Update to your machine IP/port if needed
  static const String baseUrl = 'http://localhost:3000/api';

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'), headers: _headers(), body: jsonEncode({ 'email': email, 'password': password }));
    if (res.statusCode != 200) throw Exception('Login failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listSubjects() async {
    final res = await http.get(Uri.parse('$baseUrl/subjects'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to load subjects');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAttendanceSession({required String subjectId, required String type, int? labNumber, String? batch, required int durationMinutes, double? latitude, double? longitude, int? radiusMeters}) async {
    final res = await http.post(Uri.parse('$baseUrl/attendance/session'), headers: _headers(), body: jsonEncode({
      'subjectId': subjectId,
      'type': type,
      'labNumber': labNumber,
      'batch': batch,
      'durationMinutes': durationMinutes,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    }));
    if (res.statusCode != 200) throw Exception('Failed to create session');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> scanAttendance({required String token, double? lat, double? lon}) async {
    final res = await http.post(Uri.parse('$baseUrl/attendance/scan'), headers: _headers(), body: jsonEncode({ 'token': token, 'deviceId': auth.deviceId, 'lat': lat, 'lon': lon }));
    if (res.statusCode != 200) throw Exception('Scan failed');
  }

  Future<Map<String, dynamic>> listAssignments({String? subjectId, int page = 1, int pageSize = 20}) async {
    final uri = Uri.parse('$baseUrl/assignments').replace(queryParameters: { if (subjectId != null) 'subjectId': subjectId, 'page': '$page', 'pageSize': '$pageSize' });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to load assignments');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listResults({String? subjectId, int page = 1, int pageSize = 20}) async {
    final uri = Uri.parse('$baseUrl/results').replace(queryParameters: { if (subjectId != null) 'subjectId': subjectId, 'page': '$page', 'pageSize': '$pageSize' });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to load results');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return map['rows'] as List<dynamic>;
  }
}

