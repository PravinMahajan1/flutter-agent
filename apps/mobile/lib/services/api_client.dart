import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_store.dart';
import 'dart:io';

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

  Future<List<dynamic>> listActivities() async {
    final res = await http.get(Uri.parse('$baseUrl/activities'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to load activities');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<void> joinActivity(String activityId) async {
    final res = await http.post(Uri.parse('$baseUrl/activities/$activityId/join'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to join');
  }

  Future<String?> getActivityCertificateUrl(String activityId) async {
    final res = await http.get(Uri.parse('$baseUrl/activities/$activityId/certificate'), headers: _headers());
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw Exception('Failed to fetch certificate');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return map['url'] as String?;
  }

  Future<void> submitAssignment({required String assignmentId, required File file}) async {
    final uri = Uri.parse('$baseUrl/assignments/$assignmentId/submit');
    final req = http.MultipartRequest('POST', uri);
    if (auth.token != null) req.headers['Authorization'] = 'Bearer ${auth.token}';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Submit failed: ${res.body}');
    }
  }

  Future<void> submitLeave({required DateTime from, required DateTime to, required String reason, File? attachment}) async {
    final uri = Uri.parse('$baseUrl/leaves');
    final req = http.MultipartRequest('POST', uri);
    if (auth.token != null) req.headers['Authorization'] = 'Bearer ${auth.token}';
    req.fields['fromDate'] = from.toIso8601String();
    req.fields['toDate'] = to.toIso8601String();
    req.fields['reason'] = reason;
    if (attachment != null) {
      req.files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
    }
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Leave submit failed: ${res.body}');
    }
  }

  Future<List<dynamic>> listLeaves() async {
    final res = await http.get(Uri.parse('$baseUrl/leaves'), headers: _headers());
    if (res.statusCode != 200) throw Exception('Failed to load leaves');
    return jsonDecode(res.body) as List<dynamic>;
  }
}

