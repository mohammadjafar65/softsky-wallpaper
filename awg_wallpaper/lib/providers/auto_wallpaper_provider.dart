import 'package:flutter/foundation.dart';
import '../services/auto_wallpaper_service.dart';
import '../models/wallpaper.dart';

/// Provider for Auto Wallpaper feature state management
class AutoWallpaperProvider extends ChangeNotifier {
  final AutoWallpaperService _service = AutoWallpaperService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters for settings
  bool get isEnabled => _service.settings.isEnabled;
  ScheduleInterval get interval => _service.settings.interval;
  WallpaperSource get source => _service.settings.source;
  String? get categoryId => _service.settings.categoryId;
  String? get packId => _service.settings.packId;
  bool get isDayNightEnabled => _service.settings.isDayNightEnabled;
  String? get dayWallpaperUrl => _service.settings.dayWallpaperUrl;
  String? get nightWallpaperUrl => _service.settings.nightWallpaperUrl;
  int get dayStartHour => _service.settings.dayStartHour;
  int get nightStartHour => _service.settings.nightStartHour;
  DateTime? get lastChangedAt => _service.settings.lastChangedAt;

  /// Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.initialize();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('AutoWallpaperProvider init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle auto wallpaper on/off
  Future<void> toggleAutoWallpaper(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.toggleAutoWallpaper(enabled);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle day/night mode
  Future<void> toggleDayNightMode(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.toggleDayNightMode(enabled);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set schedule interval
  Future<void> setInterval(ScheduleInterval newInterval) async {
    try {
      await _service.setInterval(newInterval);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set wallpaper source
  Future<void> setSource(WallpaperSource newSource,
      {String? categoryId, String? packId}) async {
    try {
      await _service.setSource(newSource,
          categoryId: categoryId, packId: packId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set day wallpaper for day/night mode
  Future<void> setDayWallpaper(Wallpaper wallpaper) async {
    try {
      await _service.setDayWallpaper(wallpaper.imageUrl);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set night wallpaper for day/night mode
  Future<void> setNightWallpaper(Wallpaper wallpaper) async {
    try {
      await _service.setNightWallpaper(wallpaper.imageUrl);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set day/night times
  Future<void> setDayNightTimes(int dayHour, int nightHour) async {
    try {
      final settings = _service.settings;
      settings.dayStartHour = dayHour;
      settings.nightStartHour = nightHour;
      await _service.updateSettings(settings);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Manually change wallpaper now
  Future<void> changeNow() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.changeNow();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Apply day/night wallpaper immediately
  Future<void> applyDayNightNow() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.applyDayNightWallpaper();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cancel all scheduled tasks
  Future<void> cancelAll() async {
    try {
      await _service.cancelAll();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get interval display name
  String getIntervalName(ScheduleInterval interval) {
    switch (interval) {
      case ScheduleInterval.hourly:
        return 'Every Hour';
      case ScheduleInterval.every6Hours:
        return 'Every 6 Hours';
      case ScheduleInterval.daily:
        return 'Daily';
      case ScheduleInterval.weekly:
        return 'Weekly';
    }
  }

  /// Get source display name
  String getSourceName(WallpaperSource source) {
    switch (source) {
      case WallpaperSource.bookmarks:
        return 'From Bookmarks';
      case WallpaperSource.category:
        return 'From Category';
      case WallpaperSource.pack:
        return 'From Pack';
      case WallpaperSource.all:
        return 'All Wallpapers';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
