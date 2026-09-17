import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import '../models/category.dart';

/// API Service for connecting to the AWG Backend
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Deployed backend URL
  static const String baseUrl = 'https://softskyapi.softsky.studio/api';

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  String? _authToken;

  /// Helper method to execute HTTP requests with retry logic
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        attempt++;
        final response = await request();

        // Retry on 503 (Service Unavailable) or 502 (Bad Gateway)
        if ((response.statusCode == 503 || response.statusCode == 502) &&
            attempt < maxRetries) {
          debugPrint(
              'Server returned ${response.statusCode}, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }

        return response;
      } on TimeoutException {
        if (attempt >= maxRetries) {
          debugPrint('Request timed out after $maxRetries attempts');
          rethrow;
        }
        debugPrint(
            'Request timed out, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
        await Future.delayed(delay);
        delay *= 2;
      } catch (e) {
        if (attempt >= maxRetries) {
          rethrow;
        }
        // Only retry on network-related errors
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection')) {
          debugPrint(
              'Network error, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          delay *= 2;
        } else {
          rethrow;
        }
      }
    }
  }

  // Set authentication token (from Firebase)
  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  bool get hasAuthToken => _authToken != null && _authToken!.isNotEmpty;

  Map<String, String> get headers {
    final headersMap = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headersMap['Authorization'] = 'Bearer $_authToken';
    }
    return headersMap;
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
      final response = await _executeWithRetry(
        () => http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WallpapersResponse.fromJson(data);
      } else {
        debugPrint('Request failed: ${response.statusCode} - ${response.body}');
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
      final response = await _executeWithRetry(
        () => http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

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
      final response = await _executeWithRetry(
        () => http
            .get(
              Uri.parse('$baseUrl/wallpapers/$id'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 30)),
      );

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
  Future<int?> trackDownload(String id) async {
    try {
      final response = await _executeWithRetry(
        () => http
            .post(
              Uri.parse('$baseUrl/wallpapers/$id/download'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 20)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return int.tryParse(data['downloads']?.toString() ?? '');
      }

      debugPrint('Failed to track download: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error tracking download: $e');
      return null;
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _executeWithRetry(
        () => http
            .get(
              Uri.parse('$baseUrl/categories'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 30)),
      );

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
        headers: headers,
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
        headers: headers,
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
        headers: headers,
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
  Future<bool> updateFCMToken(String token) async {
    try {
      if (_authToken == null) {
        debugPrint('Cannot update FCM token: No auth token');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: headers,
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to update FCM token: ${response.body}');
        return false;
      } else {
        debugPrint('FCM token updated successfully on backend');
        return true;
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return false;
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

// ==================== COMMUNITY API METHODS ====================

extension CommunityApiExtension on ApiService {
  static String get _communityBase => '${ApiService.baseUrl}/community';

  /// Upload community post image file directly to custom hosting backend
  Future<Map<String, dynamic>> uploadCommunityPostFile({
    required File file,
    String? title,
    String? description,
    int? width,
    int? height,
  }) async {
    final uri = Uri.parse('$_communityBase/posts');
    final request = http.MultipartRequest('POST', uri);

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    if (title != null && title.isNotEmpty) request.fields['title'] = title;
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (width != null) request.fields['width'] = width.toString();
    if (height != null) request.fields['height'] = height.toString();

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      file.path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 404) {
      throw Exception('Community server endpoint not found (404). Please ensure the backend server has the latest community update deployed.');
    }

    Map<String, dynamic> data = {};
    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Server error (${response.statusCode}): ${response.body.isNotEmpty ? response.body : "Empty response"}');
      }
    }

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? data['message'] ?? 'Failed to upload post (${response.statusCode})');
    }
    return data;
  }

  /// Create a new community post via json
  Future<Map<String, dynamic>> createCommunityPost({
    required String imageUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    int? width,
    int? height,
  }) async {
    final response = await _executeWithRetry(() => http.post(
          Uri.parse('$_communityBase/posts'),
          headers: headers,
          body: jsonEncode({
            'imageUrl': imageUrl,
            if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (width != null) 'width': width,
            if (height != null) 'height': height,
          }),
        ));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) throw Exception(data['error'] ?? 'Failed to create post');
    return data;
  }

  /// Get community feed (following + own)
  Future<Map<String, dynamic>> getCommunityFeed({int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$_communityBase/feed').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'});
    final response = await _executeWithRetry(() => http.get(uri, headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load feed');
    return data;
  }

  /// Get trending posts
  Future<Map<String, dynamic>> getTrendingPosts({int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$_communityBase/trending').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'});
    final response = await _executeWithRetry(() => http.get(uri, headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load trending');
    return data;
  }

  /// Toggle like on a post
  Future<bool> toggleLike(int postId) async {
    final response = await _executeWithRetry(() => http.post(
          Uri.parse('$_communityBase/posts/$postId/like'),
          headers: headers,
        ));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to like post');
    return data['liked'] as bool;
  }

  /// Toggle save on a post
  Future<bool> toggleSave(int postId) async {
    final response = await _executeWithRetry(() => http.post(
          Uri.parse('$_communityBase/posts/$postId/save'),
          headers: headers,
        ));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to save post');
    return data['saved'] as bool;
  }

  /// Add comment to a post
  Future<Map<String, dynamic>> addComment(int postId, String content) async {
    final response = await _executeWithRetry(() => http.post(
          Uri.parse('$_communityBase/posts/$postId/comment'),
          headers: headers,
          body: jsonEncode({'content': content}),
        ));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) throw Exception(data['error'] ?? 'Failed to add comment');
    return data;
  }

  /// Get comments for a post
  Future<Map<String, dynamic>> getComments(int postId, {int page = 1}) async {
    final uri = Uri.parse('$_communityBase/posts/$postId/comments').replace(
        queryParameters: {'page': '$page', 'limit': '20'});
    final response = await _executeWithRetry(() => http.get(uri, headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load comments');
    return data;
  }

  /// Follow a user
  Future<void> followUser(int userId) async {
    final response = await _executeWithRetry(() => http.post(
          Uri.parse('$_communityBase/follow/$userId'),
          headers: headers,
        ));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to follow user');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(int userId) async {
    final response = await _executeWithRetry(() => http.delete(
          Uri.parse('$_communityBase/follow/$userId'),
          headers: headers,
        ));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to unfollow user');
    }
  }

  /// Get public user profile
  Future<Map<String, dynamic>> getCommunityUser(int userId) async {
    final response = await _executeWithRetry(
        () => http.get(Uri.parse('$_communityBase/users/$userId'), headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'User not found');
    return data;
  }

  /// Get user's community posts
  Future<Map<String, dynamic>> getUserPosts(int userId, {int page = 1}) async {
    final uri = Uri.parse('$_communityBase/users/$userId/posts').replace(
        queryParameters: {'page': '$page', 'limit': '20'});
    final response = await _executeWithRetry(() => http.get(uri, headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load posts');
    return data;
  }

  /// Get current user's posts
  Future<Map<String, dynamic>> getMyPosts({int page = 1}) async {
    final uri = Uri.parse('$_communityBase/me/posts').replace(
        queryParameters: {'page': '$page', 'limit': '20'});
    final response = await _executeWithRetry(() => http.get(uri, headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load your posts');
    return data;
  }

  /// Report a post
  Future<void> reportPost(int postId, String reason) async {
    final response = await _executeWithRetry(() => http.post(
          Uri.parse('$_communityBase/posts/$postId/report'),
          headers: headers,
          body: jsonEncode({'reason': reason}),
        ));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to report post');
    }
  }

  /// Delete own post
  Future<void> deleteCommunityPost(int postId) async {
    final response = await _executeWithRetry(() => http.delete(
          Uri.parse('$_communityBase/posts/$postId'),
          headers: headers,
        ));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to delete post');
    }
  }

  /// Get saved community posts
  Future<Map<String, dynamic>> getSavedPosts({int page = 1}) async {
    final uri = Uri.parse('$_communityBase/saved').replace(
        queryParameters: {'page': '$page', 'limit': '20'});
    final response = await _executeWithRetry(() => http.get(uri, headers: headers));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load saved posts');
    return data;
  }

  /// Track community wallpaper download
  Future<int?> trackCommunityDownload(int postId) async {
    try {
      final response = await _executeWithRetry(
        () => http
            .post(
              Uri.parse('$_communityBase/posts/$postId/download'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 20)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return int.tryParse(data['downloads']?.toString() ?? '');
      }
      return null;
    } catch (e) {
      debugPrint('Error tracking community download: $e');
      return null;
    }
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
