import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  static const String _packageName = 'com.webinessdesign.softskywallpaper';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_packageName';

  /// Check if an update is available on Play Store
  /// Returns true if a newer version exists
  Future<bool> isUpdateAvailable(String currentVersion) async {
    try {
      final box = Hive.box('cache');

      // Check if we recently checked (within last 6 hours)
      final lastCheck = box.get('last_version_check');
      final lastResult = box.get('update_available');

      if (lastCheck != null && lastResult != null) {
        final lastCheckTime = DateTime.parse(lastCheck);
        if (DateTime.now().difference(lastCheckTime).inHours < 6) {
          // Use cached result
          return lastResult as bool;
        }
      }

      // Fetch Play Store version
      final playStoreVersion = await _fetchPlayStoreVersion();

      if (playStoreVersion == null) {
        return false;
      }

      // Compare versions
      final isUpdateAvailable =
          _isVersionNewer(playStoreVersion, currentVersion);

      // Cache the result
      await box.put('last_version_check', DateTime.now().toIso8601String());
      await box.put('update_available', isUpdateAvailable);
      await box.put('play_store_version', playStoreVersion);

      return isUpdateAvailable;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Fetch the latest version from Play Store
  Future<String?> _fetchPlayStoreVersion() async {
    try {
      final response = await http.get(Uri.parse(_playStoreUrl));

      if (response.statusCode == 200) {
        // Parse the HTML to find version info
        // Play Store includes version in meta tags
        final versionRegex = RegExp(r'Current Version.*?>([\d.]+)<');
        final match = versionRegex.firstMatch(response.body);

        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }

        // Alternative regex pattern
        final altRegex = RegExp(r'\[\[\["([\d.]+?)"\]\]');
        final altMatch = altRegex.firstMatch(response.body);

        if (altMatch != null && altMatch.groupCount >= 1) {
          return altMatch.group(1);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching Play Store version: $e');
      return null;
    }
  }

  /// Compare two version strings
  /// Returns true if newVersion is newer than currentVersion
  bool _isVersionNewer(String newVersion, String currentVersion) {
    try {
      // Remove any build numbers (e.g., "3.0.5+8" -> "3.0.5")
      final cleanNew = newVersion.split('+')[0];
      final cleanCurrent = currentVersion.split('+')[0];

      final newParts = cleanNew.split('.').map(int.parse).toList();
      final currentParts = cleanCurrent.split('.').map(int.parse).toList();

      // Ensure both have same number of parts
      while (newParts.length < currentParts.length) {
        newParts.add(0);
      }
      while (currentParts.length < newParts.length) {
        currentParts.add(0);
      }

      // Compare each part
      for (int i = 0; i < newParts.length; i++) {
        if (newParts[i] > currentParts[i]) {
          return true;
        } else if (newParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// Get the Play Store URL for the app
  String getPlayStoreUrl() {
    return _playStoreUrl;
  }

  /// Clear version check cache
  Future<void> clearCache() async {
    final box = Hive.box('cache');
    await box.delete('last_version_check');
    await box.delete('update_available');
    await box.delete('play_store_version');
  }
}
