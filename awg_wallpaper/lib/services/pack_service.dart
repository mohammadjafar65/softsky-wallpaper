import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/wallpaper_pack.dart';
import '../models/wallpaper.dart';

class PackService {
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

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
              'PackService: Server returned ${response.statusCode}, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }

        return response;
      } on TimeoutException {
        if (attempt >= maxRetries) {
          debugPrint(
              'PackService: Request timed out after $maxRetries attempts');
          rethrow;
        }
        debugPrint(
            'PackService: Request timed out, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
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
              'PackService: Network error, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          delay *= 2;
        } else {
          rethrow;
        }
      }
    }
  }

  Future<List<WallpaperPack>> getPacks({int page = 1, int limit = 20}) async {
    try {
      final response = await _executeWithRetry(
        () => http
            .get(Uri.parse(
                '${ApiService.baseUrl}/packs?page=$page&limit=$limit'))
            .timeout(const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('PackService: Loaded ${data['packs']?.length ?? 0} packs');
        final List<dynamic> packsJson = data['packs'] ?? [];
        return packsJson.map((json) => WallpaperPack.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load packs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PackService: Error fetching packs: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Check your internet connection');
      }
      rethrow;
    }
  }

  Future<WallpaperPack> getPackDetails(String id) async {
    try {
      final response = await _executeWithRetry(
        () => http
            .get(Uri.parse('${ApiService.baseUrl}/packs/$id'))
            .timeout(const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final packData = data['pack'];
        final List<dynamic> wallpapersJson = data['wallpapers'] ?? [];

        final Map<String, dynamic> mergedJson = Map.from(packData);
        mergedJson['wallpapers'] = wallpapersJson;

        return WallpaperPack.fromJson(mergedJson);
      } else {
        throw Exception('Failed to load pack details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PackService: Error fetching pack details: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Check your internet connection');
      }
      rethrow;
    }
  }
}
