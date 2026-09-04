import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vks_app/core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTokenKey);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(res);
  }

  Future<void> logout(String refreshToken) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$kBaseUrl/auth/logout/'),
      headers: headers,
      body: jsonEncode({'refresh': refreshToken}),
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$kBaseUrl/auth/profile/'), headers: headers);
    return _handleResponse(res);
  }

  Future<List<dynamic>> getCourses() async {
    final res = await http.get(Uri.parse('$kBaseUrl/courses/'));
    final data = _handleResponse(res);
    return (data['results'] as List?) ?? (data.values.first is List ? data.values.first : [data]);
  }

  Future<Map<String, dynamic>> getActivities({int? year, int? projectId, String? search, int page = 1}) async {
    final params = <String, String>{'page': page.toString()};
    if (year != null) params['year'] = year.toString();
    if (projectId != null) params['project'] = projectId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$kBaseUrl/activities/').replace(queryParameters: params);
    final res = await http.get(uri);
    return _handleResponse(res);
  }

  Future<List<dynamic>> getProjects() async {
    final res = await http.get(Uri.parse('$kBaseUrl/activities/projects/'));
    final data = _handleResponse(res);
    return (data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> submitAdmission(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$kBaseUrl/admissions/'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<List<dynamic>> getMyAdmissions() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$kBaseUrl/admissions/my/'), headers: headers);
    final data = _handleResponse(res);
    return (data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> submitEnquiry(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$kBaseUrl/enquiries/submit/'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getGallery({String? album, String? type}) async {
    final params = <String, String>{};
    if (album != null) params['album'] = album;
    if (type != null) params['type'] = type;
    final uri = Uri.parse('$kBaseUrl/gallery/').replace(queryParameters: params);
    final res = await http.get(uri);
    return _handleResponse(res);
  }

  Future<List<dynamic>> getAllEnquiries({String? status}) async {
    final headers = await _authHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$kBaseUrl/enquiries/').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: headers);
    final data = _handleResponse(res);
    return (data['results'] as List?) ?? (data is List ? data as List : []);
  }

  Future<List<dynamic>> getAllAdmissions({String? status}) async {
    final headers = await _authHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$kBaseUrl/admissions/all/').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: headers);
    final data = _handleResponse(res);
    return (data['results'] as List?) ?? (data is List ? data as List : []);
  }

  Future<List<dynamic>> getNotifications() async {
    final res = await http.get(Uri.parse('$kBaseUrl/notifications/'));
    final data = _handleResponse(res);
    return (data['results'] as List?) ?? [];
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    final data = jsonDecode(body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (data is List) return {'results': data};
      return data as Map<String, dynamic>;
    }
    final error = data is Map
        ? (data['detail'] ?? data['message'] ?? data.values.first)
        : 'An error occurred';
    throw Exception(error.toString());
  }
}
