import 'package:flutter/foundation.dart';
import '../models/wallpaper_pack.dart';
import '../services/pack_service.dart';

class PackProvider with ChangeNotifier {
  final PackService _packService = PackService();

  List<WallpaperPack> _packs = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<WallpaperPack> get packs => _packs;
  List<WallpaperPack> get freePacks => _packs.where((p) => !p.isPro).toList();
  List<WallpaperPack> get proPacks => _packs.where((p) => p.isPro).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Set packs from WallpaperProvider (avoids duplicate API calls)
  void setPacksFromProvider(List<WallpaperPack> packs) {
    if (packs.isNotEmpty) {
      _packs = packs;
      _isInitialized = true;
      _error = null;
      notifyListeners();
      debugPrint(
          'PackProvider: Received ${_packs.length} packs from WallpaperProvider');
    }
  }

  Future<void> fetchPacks({bool refresh = false}) async {
    if (_isLoading) return;

    // If already initialized and not refreshing, skip
    if (_isInitialized && _packs.isNotEmpty && !refresh) {
      return;
    }

    if (refresh) {
      _packs = [];
      _isInitialized = false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _packs = await _packService.getPacks(page: 1, limit: 50);
      _isInitialized = true;
      debugPrint('PackProvider: Fetched ${_packs.length} packs from API');
    } catch (e) {
      _error = e.toString();
      debugPrint('PackProvider: Error fetching packs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WallpaperPack?> getPackDetails(String id) async {
    try {
      return await _packService.getPackDetails(id);
    } catch (e) {
      debugPrint('PackProvider: Error fetching pack details: $e');
      return null;
    }
  }
}
