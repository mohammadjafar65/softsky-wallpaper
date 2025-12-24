import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import '../models/category.dart';

/// API Service for connecting to the AWG Backend
class ApiService {
  // TODO: Update this URL to your deployed backend URL
  static const String baseUrl = 'https://softskyapi.softsky.studio/api';

  String? _authToken;

  // Set authentication token (from Firebase)
  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==================== WALLPAPERS ====================

  /// Get wallpapers with pagination
  Future<WallpapersResponse> getWallpapers({
    int page = 1,
    int limit = 20,
    String? category,
    bool? isPro,
    bool? isWide,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }
      if (isPro != null) {
        queryParams['isPro'] = isPro.toString();
      }
      if (isWide != null) {
        queryParams['isWide'] = isWide.toString();
      }

      final uri = Uri.parse('$baseUrl/wallpapers')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WallpapersResponse.fromJson(data);
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching wallpapers: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Check your internet connection');
      }
      rethrow;
    }
  }

  /// Search wallpapers
  Future<WallpapersResponse> searchWallpapers(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/wallpapers/search')
          .replace(queryParameters: {'q': query});
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WallpapersResponse.fromJson(data);
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching wallpapers: $e');
      rethrow;
    }
  }

  /// Get single wallpaper by ID
  Future<Wallpaper> getWallpaperById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/wallpapers/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Wallpaper.fromJson(data);
      } else {
        throw Exception('Failed to load wallpaper: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching wallpaper: $e');
      rethrow;
    }
  }

  /// Track wallpaper download
  Future<void> trackDownload(String id) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/wallpapers/$id/download'),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('Error tracking download: $e');
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/categories'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categoriesJson = data['categories'] ?? [];
        return categoriesJson.map((c) => Category.fromJson(c)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  // ==================== SUBSCRIPTION ====================

  /// Verify subscription purchase
  Future<SubscriptionStatus> verifySubscription({
    required String purchaseToken,
    required String plan,
    String? productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/verify'),
        headers: _headers,
        body: json.encode({
          'purchaseToken': purchaseToken,
          'plan': plan,
          'productId': productId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionStatus.fromJson(data['subscription']);
      } else {
        throw Exception('Verification failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error verifying subscription: $e');
      rethrow;
    }
  }

  /// Get subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionStatus.fromJson(data);
      } else {
        throw Exception('Failed to get status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      rethrow;
    }
  }

  // ==================== AUTH ====================

  /// Sync Firebase user with backend
  Future<UserSyncResponse> syncFirebaseUser({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
    String authProvider = 'google',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase/verify'),
        headers: _headers,
        body: json.encode({
          'firebaseUid': firebaseUid,
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'authProvider': authProvider,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserSyncResponse.fromJson(data);
      } else {
        throw Exception('User sync failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error syncing user: $e');
      rethrow;
    }
  }

  /// Update FCM token
  Future<void> updateFCMToken(String token) async {
    try {
      if (_authToken == null) {
        debugPrint('Cannot update FCM token: No auth token');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: _headers,
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to update FCM token: ${response.body}');
      } else {
        debugPrint('FCM token updated successfully on backend');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}

// ==================== RESPONSE MODELS ====================

class WallpapersResponse {
  final List<Wallpaper> wallpapers;
  final int page;
  final int limit;
  final int total;
  final int pages;

  WallpapersResponse({
    required this.wallpapers,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory WallpapersResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> wallpapersJson = json['wallpapers'] ?? [];
    final pagination = json['pagination'] ?? {};

    return WallpapersResponse(
      wallpapers: wallpapersJson.map((w) => Wallpaper.fromJson(w)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      total: pagination['total'] ?? 0,
      pages: pagination['pages'] ?? 1,
    );
  }
}

class SubscriptionStatus {
  final String plan;
  final DateTime? expiryDate;
  final bool isPro;
  final bool isExpired;

  SubscriptionStatus({
    required this.plan,
    this.expiryDate,
    required this.isPro,
    required this.isExpired,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan'] ?? 'free',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isPro: json['isPro'] ?? false,
      isExpired: json['isExpired'] ?? false,
    );
  }
}

class UserSyncResponse {
  final String token;
  final Map<String, dynamic> user;

  UserSyncResponse({required this.token, required this.user});

  factory UserSyncResponse.fromJson(Map<String, dynamic> json) {
    return UserSyncResponse(
      token: json['token'] ?? '',
      user: json['user'] ?? {},
    );
  }
}
