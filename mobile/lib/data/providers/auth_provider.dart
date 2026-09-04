import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vks_app/data/services/api_service.dart';
import 'package:vks_app/core/constants/app_constants.dart';

class UserModel {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String dateJoined;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    required this.dateJoined,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'] ?? '',
        username: json['username'] ?? '',
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        phone: json['phone'],
        role: json['role'] ?? kRolePublic,
        dateJoined: json['date_joined'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': role,
        'date_joined': dateJoined,
      };
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _accessToken != null;
  bool get isStaff => _user?.role == kRoleAdmin || _user?.role == kRoleStaff;

  final ApiService _api = ApiService();

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(kTokenKey);
    _refreshToken = prefs.getString(kRefreshTokenKey);
    final userJson = prefs.getString(kUserKey);
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString(kTokenKey, _accessToken!);
    if (_refreshToken != null) await prefs.setString(kRefreshTokenKey, _refreshToken!);
    if (_user != null) await prefs.setString(kUserKey, jsonEncode(_user!.toJson()));
  }

  Future<bool> register({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String password2,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.register({
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'password2': password2,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      _accessToken = data['access'];
      _refreshToken = data['refresh'];
      _user = UserModel.fromJson(data['user']);
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      _accessToken = data['access'];
      _refreshToken = data['refresh'];
      _user = UserModel.fromJson(data['user']);
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await _api.logout(_refreshToken!);
      } catch (_) {}
    }
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);
    await prefs.remove(kRefreshTokenKey);
    await prefs.remove(kUserKey);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
