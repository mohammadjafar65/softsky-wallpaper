import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper.dart';

/// Progress info for batch download
class BatchDownloadProgress {
  final int completed;
  final int total;
  final String? currentWallpaper;
  final String? error;
  final bool isComplete;

  BatchDownloadProgress({
    required this.completed,
    required this.total,
    this.currentWallpaper,
    this.error,
    this.isComplete = false,
  });

  double get progress => total > 0 ? completed / total : 0;
  String get progressText => '$completed / $total';
}

/// Service for batch downloading wallpapers
class BatchDownloadService {
  static const _wallpaperChannel = MethodChannel('com.awg.wallpaper/wallpaper');

  bool _isCancelled = false;
  final StreamController<BatchDownloadProgress> _progressController =
      StreamController<BatchDownloadProgress>.broadcast();

  Stream<BatchDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Download multiple wallpapers to gallery
  Future<BatchDownloadProgress> downloadWallpapers(
      List<Wallpaper> wallpapers) async {
    _isCancelled = false;
    int completed = 0;
    final total = wallpapers.length;
    List<String> errors = [];

    // Emit initial progress
    _progressController.add(BatchDownloadProgress(
      completed: 0,
      total: total,
      currentWallpaper: wallpapers.isNotEmpty ? wallpapers.first.title : null,
    ));

    for (int i = 0; i < wallpapers.length; i++) {
      if (_isCancelled) {
        _progressController.add(BatchDownloadProgress(
          completed: completed,
          total: total,
          error: 'Download cancelled',
          isComplete: true,
        ));
        return BatchDownloadProgress(
          completed: completed,
          total: total,
          error: 'Download cancelled',
          isComplete: true,
        );
      }

      final wallpaper = wallpapers[i];

      try {
        // Emit progress with current wallpaper
        _progressController.add(BatchDownloadProgress(
          completed: completed,
          total: total,
          currentWallpaper: wallpaper.title,
        ));

        // Download the image
        await _downloadAndSave(wallpaper);
        completed++;

        // Emit updated progress
        _progressController.add(BatchDownloadProgress(
          completed: completed,
          total: total,
          currentWallpaper:
              i < wallpapers.length - 1 ? wallpapers[i + 1].title : null,
        ));
      } catch (e) {
        errors.add('${wallpaper.title}: $e');
        debugPrint('Failed to download ${wallpaper.title}: $e');
      }
    }

    final result = BatchDownloadProgress(
      completed: completed,
      total: total,
      error: errors.isNotEmpty ? '${errors.length} failed' : null,
      isComplete: true,
    );

    _progressController.add(result);
    return result;
  }

  /// Download and save a single wallpaper to gallery
  Future<void> _downloadAndSave(Wallpaper wallpaper) async {
    try {
      // Download using cache manager
      final file =
          await DefaultCacheManager().getSingleFile(wallpaper.imageUrl);

      // Copy to a temp location with proper name
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'softsky_${wallpaper.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await file.copy(tempFile.path);

      // Save to gallery using native method
      await _wallpaperChannel.invokeMethod('saveToGallery', {
        'path': tempFile.path,
      });

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('Error downloading ${wallpaper.title}: $e');
      rethrow;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    _isCancelled = true;
  }

  /// Check if download is in progress
  bool get isDownloading => !_isCancelled;

  /// Dispose the service
  void dispose() {
    _progressController.close();
  }
}
