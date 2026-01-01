import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/services.dart';
import '../models/wallpaper.dart';
import 'api_service.dart';

/// Scheduling intervals for auto wallpaper
enum ScheduleInterval {
  hourly,
  every6Hours,
  daily,
  weekly,
}

/// Source of wallpapers for auto change
enum WallpaperSource {
  bookmarks,
  category,
  pack,
  all,
}

/// Settings for auto wallpaper feature
class AutoWallpaperSettings {
  bool isEnabled;
  ScheduleInterval interval;
  WallpaperSource source;
  String? categoryId;
  String? packId;
  bool isDayNightEnabled;
  String? dayWallpaperUrl;
  String? nightWallpaperUrl;
  int dayStartHour; // 6 = 6 AM
  int nightStartHour; // 18 = 6 PM
  DateTime? lastChangedAt;

  AutoWallpaperSettings({
    this.isEnabled = false,
    this.interval = ScheduleInterval.daily,
    this.source = WallpaperSource.bookmarks,
    this.categoryId,
    this.packId,
    this.isDayNightEnabled = false,
    this.dayWallpaperUrl,
    this.nightWallpaperUrl,
    this.dayStartHour = 6,
    this.nightStartHour = 18,
    this.lastChangedAt,
  });

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'interval': interval.index,
        'source': source.index,
        'categoryId': categoryId,
        'packId': packId,
        'isDayNightEnabled': isDayNightEnabled,
        'dayWallpaperUrl': dayWallpaperUrl,
        'nightWallpaperUrl': nightWallpaperUrl,
        'dayStartHour': dayStartHour,
        'nightStartHour': nightStartHour,
        'lastChangedAt': lastChangedAt?.toIso8601String(),
      };

  factory AutoWallpaperSettings.fromJson(Map<String, dynamic> json) {
    return AutoWallpaperSettings(
      isEnabled: json['isEnabled'] ?? false,
      interval: ScheduleInterval.values[json['interval'] ?? 2],
      source: WallpaperSource.values[json['source'] ?? 0],
      categoryId: json['categoryId'],
      packId: json['packId'],
      isDayNightEnabled: json['isDayNightEnabled'] ?? false,
      dayWallpaperUrl: json['dayWallpaperUrl'],
      nightWallpaperUrl: json['nightWallpaperUrl'],
      dayStartHour: json['dayStartHour'] ?? 6,
      nightStartHour: json['nightStartHour'] ?? 18,
      lastChangedAt: json['lastChangedAt'] != null
          ? DateTime.tryParse(json['lastChangedAt'])
          : null,
    );
  }
}

/// Callback dispatcher for WorkManager - must be a top-level function
@pragma('vm:entry-point')
void autoWallpaperCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Note: Hive should already be initialized in the main isolate
      // For background tasks, we initialize a new instance
      await Hive.initFlutter();
      final service = AutoWallpaperService();
      await service._initBox();

      if (task == AutoWallpaperService.autoChangeTask) {
        await service.setNextWallpaper();
      } else if (task == AutoWallpaperService.dayNightTask) {
        await service.applyDayNightWallpaper();
      }
      return true;
    } catch (e) {
      debugPrint('AutoWallpaper task failed: $e');
      return false;
    }
  });
}

/// Service for automatic wallpaper changes
class AutoWallpaperService {
  static const String autoChangeTask = 'autoWallpaperChange';
  static const String dayNightTask = 'dayNightWallpaper';
  static const String _boxName = 'auto_wallpaper_settings';
  static const String _settingsKey = 'settings';
  static const String _wallpaperHistoryKey = 'wallpaper_history';
  static const _wallpaperChannel = MethodChannel('com.awg.wallpaper/wallpaper');

  Box? _box;
  AutoWallpaperSettings _settings = AutoWallpaperSettings();

  AutoWallpaperService();

  /// Initialize the Hive box
  Future<void> _initBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      await _loadSettings();
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    await _initBox();

    // Initialize WorkManager
    await Workmanager().initialize(
      autoWallpaperCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Re-schedule if settings are enabled
    if (_settings.isEnabled) {
      await _scheduleAutoChange();
    }
    if (_settings.isDayNightEnabled) {
      await _scheduleDayNightCheck();
    }
  }

  /// Load settings from Hive
  Future<void> _loadSettings() async {
    final data = _box?.get(_settingsKey);
    if (data != null) {
      _settings =
          AutoWallpaperSettings.fromJson(Map<String, dynamic>.from(data));
    }
  }

  /// Save settings to Hive
  Future<void> _saveSettings() async {
    await _box?.put(_settingsKey, _settings.toJson());
  }

  /// Get current settings
  AutoWallpaperSettings get settings => _settings;

  /// Update settings
  Future<void> updateSettings(AutoWallpaperSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();

    // Cancel existing schedules
    await Workmanager().cancelAll();

    // Re-schedule based on new settings
    if (_settings.isEnabled) {
      await _scheduleAutoChange();
    }
    if (_settings.isDayNightEnabled) {
      await _scheduleDayNightCheck();
    }
  }

  /// Schedule automatic wallpaper change
  Future<void> _scheduleAutoChange() async {
    final duration = _getIntervalDuration(_settings.interval);

    await Workmanager().registerPeriodicTask(
      'auto_wallpaper_periodic',
      autoChangeTask,
      frequency: duration,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint(
        'Scheduled auto wallpaper change every ${duration.inHours} hours');
  }

  /// Schedule day/night wallpaper check
  Future<void> _scheduleDayNightCheck() async {
    // Check every hour for day/night transitions
    await Workmanager().registerPeriodicTask(
      'day_night_wallpaper_periodic',
      dayNightTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint('Scheduled day/night wallpaper check');
  }

  /// Get duration for interval
  Duration _getIntervalDuration(ScheduleInterval interval) {
    switch (interval) {
      case ScheduleInterval.hourly:
        return const Duration(hours: 1);
      case ScheduleInterval.every6Hours:
        return const Duration(hours: 6);
      case ScheduleInterval.daily:
        return const Duration(hours: 24);
      case ScheduleInterval.weekly:
        return const Duration(days: 7);
    }
  }

  /// Set the next wallpaper based on source
  Future<void> setNextWallpaper() async {
    await _initBox();

    try {
      final wallpaper = await _getNextWallpaper();
      if (wallpaper != null) {
        await _applyWallpaper(wallpaper.imageUrl);
        _settings.lastChangedAt = DateTime.now();
        await _saveSettings();

        // Save to history
        await _saveToHistory(wallpaper.id);
      }
    } catch (e) {
      debugPrint('Failed to set next wallpaper: $e');
    }
  }

  /// Get next wallpaper from configured source
  Future<Wallpaper?> _getNextWallpaper() async {
    List<Wallpaper> wallpapers = [];

    switch (_settings.source) {
      case WallpaperSource.bookmarks:
        // Get bookmarks from Hive
        final bookmarksBox = await Hive.openBox('bookmarks');
        final bookmarksList = bookmarksBox.get('wallpapers', defaultValue: []);
        if (bookmarksList is List) {
          wallpapers = bookmarksList
              .map((e) => Wallpaper.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        break;

      case WallpaperSource.category:
        if (_settings.categoryId != null) {
          final response = await ApiService().getWallpapers(
            category: _settings.categoryId,
            limit: 50,
          );
          wallpapers = response.wallpapers;
        }
        break;

      case WallpaperSource.pack:
        // Packs require separate API call - use all for now
        final response = await ApiService().getWallpapers(limit: 50);
        wallpapers = response.wallpapers;
        break;

      case WallpaperSource.all:
        final response = await ApiService().getWallpapers(limit: 50);
        wallpapers = response.wallpapers;
        break;
    }

    if (wallpapers.isEmpty) return null;

    // Get history to avoid repeats
    final history = await _getHistory();

    // Filter out recently used wallpapers
    final available = wallpapers.where((w) => !history.contains(w.id)).toList();

    // If all wallpapers used, clear history and use all
    final pool = available.isEmpty ? wallpapers : available;

    // Random selection
    final random = Random();
    return pool[random.nextInt(pool.length)];
  }

  /// Apply day/night wallpaper based on current time
  Future<void> applyDayNightWallpaper() async {
    await _initBox();

    if (!_settings.isDayNightEnabled) return;

    final now = DateTime.now();
    final currentHour = now.hour;

    String? wallpaperUrl;

    if (currentHour >= _settings.dayStartHour &&
        currentHour < _settings.nightStartHour) {
      // Day time
      wallpaperUrl = _settings.dayWallpaperUrl;
    } else {
      // Night time
      wallpaperUrl = _settings.nightWallpaperUrl;
    }

    if (wallpaperUrl != null) {
      await _applyWallpaper(wallpaperUrl);
    }
  }

  /// Apply wallpaper using native method channel
  Future<void> _applyWallpaper(String imageUrl) async {
    try {
      // Download the image first
      final file = await DefaultCacheManager().getSingleFile(imageUrl);

      // Apply using native channel
      await _wallpaperChannel.invokeMethod('setWallpaper', {
        'path': file.path,
        'location': 2, // Both home and lock screen
      });

      debugPrint('Wallpaper applied successfully: $imageUrl');
    } catch (e) {
      debugPrint('Failed to apply wallpaper: $e');
      rethrow;
    }
  }

  /// Save wallpaper ID to history
  Future<void> _saveToHistory(String wallpaperId) async {
    final history = await _getHistory();
    history.add(wallpaperId);

    // Keep only last 20 entries
    if (history.length > 20) {
      history.removeAt(0);
    }

    await _box?.put(_wallpaperHistoryKey, history);
  }

  /// Get wallpaper history
  Future<List<String>> _getHistory() async {
    final data = _box?.get(_wallpaperHistoryKey);
    if (data != null && data is List) {
      return List<String>.from(data);
    }
    return [];
  }

  /// Cancel all scheduled tasks
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    _settings.isEnabled = false;
    _settings.isDayNightEnabled = false;
    await _saveSettings();
  }

  /// Toggle auto wallpaper
  Future<void> toggleAutoWallpaper(bool enabled) async {
    _settings.isEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      await _scheduleAutoChange();
    } else {
      await Workmanager().cancelByUniqueName('auto_wallpaper_periodic');
    }
  }

  /// Toggle day/night mode
  Future<void> toggleDayNightMode(bool enabled) async {
    _settings.isDayNightEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      await _scheduleDayNightCheck();
      // Apply immediately
      await applyDayNightWallpaper();
    } else {
      await Workmanager().cancelByUniqueName('day_night_wallpaper_periodic');
    }
  }

  /// Set day wallpaper
  Future<void> setDayWallpaper(String url) async {
    _settings.dayWallpaperUrl = url;
    await _saveSettings();
  }

  /// Set night wallpaper
  Future<void> setNightWallpaper(String url) async {
    _settings.nightWallpaperUrl = url;
    await _saveSettings();
  }

  /// Set interval
  Future<void> setInterval(ScheduleInterval interval) async {
    _settings.interval = interval;
    await _saveSettings();

    if (_settings.isEnabled) {
      await Workmanager().cancelByUniqueName('auto_wallpaper_periodic');
      await _scheduleAutoChange();
    }
  }

  /// Set source
  Future<void> setSource(WallpaperSource source,
      {String? categoryId, String? packId}) async {
    _settings.source = source;
    _settings.categoryId = categoryId;
    _settings.packId = packId;
    await _saveSettings();
  }

  /// Manually trigger wallpaper change
  Future<void> changeNow() async {
    await setNextWallpaper();
  }
}
