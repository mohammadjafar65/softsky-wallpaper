import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Centralized cache manager configuration for optimal image loading performance
class CachedImageConfig {
  static const String key = 'wallpaperCacheKey';

  static CacheManager get cacheManager => CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );

  /// Memory cache configuration
  static const int maxMemoryCacheSize = 100 * 1024 * 1024; // 100 MB

  /// Disk cache configuration
  static const int maxDiskCacheSize = 500 * 1024 * 1024; // 500 MB

  /// Cache duration for thumbnails
  static const Duration thumbnailCacheDuration = Duration(days: 30);

  /// Cache duration for full images
  static const Duration fullImageCacheDuration = Duration(days: 60);
}

