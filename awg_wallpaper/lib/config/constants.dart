class AppConstants {
  // App Info
  static const String appName = 'SoftSky Wallpaper App';
  static const String appVersion = '1.0.0';
  
  // Categories
  static const List<Map<String, dynamic>> categories = [
    {'id': 'all', 'name': 'All', 'icon': '✨'},
    {'id': 'abstract', 'name': 'Abstract', 'icon': '🎨'},
    {'id': 'amoled', 'name': 'AMOLED', 'icon': '🖤'},
    {'id': 'animal', 'name': 'Animal', 'icon': '🦁'},
    {'id': 'aesthetic', 'name': 'Aesthetic', 'icon': '🌸'},
    {'id': 'nature', 'name': 'Nature', 'icon': '🌿'},
    {'id': 'space', 'name': 'Space', 'icon': '🌌'},
    {'id': 'minimal', 'name': 'Minimal', 'icon': '◻️'},
    {'id': 'gradient', 'name': 'Gradient', 'icon': '🌈'},
    {'id': 'dark', 'name': 'Dark', 'icon': '🌙'},
  ];
  
  // Sample Wallpaper URLs (using Picsum for demo)
  static List<String> getSampleWallpaperUrls(int count, {int startId = 1}) {
    return List.generate(count, (index) {
      final id = startId + index;
      return 'https://picsum.photos/seed/$id/1080/1920';
    });
  }
  
  static List<String> getSampleWideWallpaperUrls(int count, {int startId = 100}) {
    return List.generate(count, (index) {
      final id = startId + index;
      return 'https://picsum.photos/seed/$id/1920/1080';
    });
  }
  
  static String getThumbnailUrl(String fullUrl) {
    return fullUrl.replaceAll('/1080/1920', '/540/960')
                  .replaceAll('/1920/1080', '/480/270');
  }
}
