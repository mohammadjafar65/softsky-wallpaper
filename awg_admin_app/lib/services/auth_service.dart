import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String role;

  AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'].toString(),
        email: json['email'] ?? '',
        displayName: json['displayName'] ?? json['email'] ?? '',
        role: json['role'] ?? 'admin',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'role': role,
      };
}

class AuthService {
  static AuthUser? _currentUser;
  static String? _token;

  static AuthUser? get currentUser => _currentUser;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          _currentUser = AuthUser.fromJson(decoded);
        } else {
          await clearToken();
        }
      } catch (_) {
        await clearToken();
      }
    }
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    return _token;
  }

  static bool get isLoggedIn => _token != null;

  static Future<void> saveSession(String token, AuthUser user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearToken() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  static Future<void> logout() => clearToken();
}
