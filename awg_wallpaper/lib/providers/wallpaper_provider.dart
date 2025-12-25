import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/wallpaper.dart';
import '../models/wallpaper_pack.dart';
import '../models/category.dart';

import '../services/api_service.dart';
import '../services/pack_service.dart';

class WallpaperProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final PackService _packService = PackService();

  List<Wallpaper> _wallpapers = [];
  List<Wallpaper> _wideWallpapers = [];
  List<WallpaperPack> _packs = [];
  List<Category> _categories = [];
  String _selectedCategory = 'all';
  int _totalWallpapers = 0;
  int _totalProWallpapers = 0;
  bool _isLoading = true; // Start with loading state
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Use API mode (set to false to use sample data)
  // bool _useApi = true;

  List<Wallpaper> get wallpapers => _selectedCategory == 'all'
      ? _wallpapers
          .where((w) =>
              !w.isPro && !w.isWide && (w.packId == null || w.packId!.isEmpty))
          .toList()
      : _wallpapers
          .where((w) =>
              w.category == _selectedCategory &&
              !w.isPro &&
              !w.isWide &&
              (w.packId == null || w.packId!.isEmpty))
          .toList();

  List<Wallpaper> get allWallpapers => _wallpapers;
  List<Wallpaper> get wideWallpapers => _wideWallpapers;
  List<WallpaperPack> get packs => _packs;
  List<WallpaperPack> get freePacks => _packs.where((p) => !p.isPro).toList();
  List<WallpaperPack> get proPacks => _packs.where((p) => p.isPro).toList();
  List<Category> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  int get totalWallpapers => _totalWallpapers;
  int get totalProWallpapers => _totalProWallpapers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  WallpaperProvider() {
    _initializeData();
  }

  Box? get _cacheBox {
    if (Hive.isBoxOpen('cache')) {
      return Hive.box('cache');
    }
    return null;
  }

  Future<void> _initializeData() async {
    // 1. Try to load from cache first for instant display
    _loadFromCache();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadFromApi();
    } catch (e) {
      // debugPrint('API initialization failed: $e');
      if (_wallpapers.isEmpty) {
        _error = 'Failed to connect to server.';
      } else {
        debugPrint('API failed but we have cached data');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromApi() async {
    try {
      // Load data sequentially to prevent server overload/500 errors

      // 1. Categories
      final fetchedCategories = await _apiService.getCategories();
      if (!fetchedCategories.any((c) => c.id == 'all')) {
        fetchedCategories.insert(
            0, const Category(id: 'all', name: 'All', icon: '✨'));
      }
      _categories = fetchedCategories;

      // 2. Wallpapers
      final wallpapersResponse =
          await _apiService.getWallpapers(page: 1, limit: 30, isWide: false);
      _wallpapers = wallpapersResponse.wallpapers;
      _currentPage = wallpapersResponse.page;
      _totalPages = wallpapersResponse.pages;
      _hasMore = _currentPage < _totalPages;

      // 3. Wide Wallpapers
      final wideWallpapersResponse =
          await _apiService.getWallpapers(page: 1, limit: 20, isWide: true);
      _wideWallpapers = wideWallpapersResponse.wallpapers
          .map((w) => w.copyWith(isPro: true))
          .toList();

      // 4. Packs
      _packs = await _packService.getPacks(page: 1, limit: 50);
      debugPrint('WallpaperProvider: Loaded ${_packs.length} packs');

      // 5. Pro Wallpapers Count
      final proWallpapersResponse =
          await _apiService.getWallpapers(page: 1, limit: 1, isPro: true);
      _totalProWallpapers = proWallpapersResponse.total;

      // Calculate total wallpapers
      _totalWallpapers =
          wallpapersResponse.total + wideWallpapersResponse.total;

      // Save to cache
      _saveToCache();
    } catch (e) {
      debugPrint('Failed to load data from API: $e');
      rethrow;
    }
  }

  void _loadFromCache() {
    final box = _cacheBox;
    if (box == null) return;

    if (box.containsKey('categories')) {
      try {
        final List<dynamic> catJson = json.decode(box.get('categories'));
        _categories = catJson.map((c) => Category.fromJson(c)).toList();
      } catch (e) {
        debugPrint('Error loading categories from cache: $e');
      }
    } else {
      // Default categories if cache empty
      // _categories =
      //     AppConstants.categories.map((c) => Category.fromMap(c)).toList();
    }

    if (box.containsKey('wallpapers')) {
      try {
        final List<dynamic> wallJson = json.decode(box.get('wallpapers'));
        _wallpapers = wallJson.map((w) => Wallpaper.fromJson(w)).toList();
      } catch (e) {
        debugPrint('Error loading wallpapers from cache: $e');
      }
    }

    if (box.containsKey('wide_wallpapers')) {
      try {
        final List<dynamic> wideJson = json.decode(box.get('wide_wallpapers'));
        _wideWallpapers = wideJson.map((w) => Wallpaper.fromJson(w)).toList();
      } catch (e) {
        debugPrint('Error loading wide wallpapers from cache: $e');
      }
    }

    // Load packs from cache
    if (box.containsKey('packs')) {
      try {
        final List<dynamic> packsJson = json.decode(box.get('packs'));
        _packs = packsJson.map((p) => WallpaperPack.fromJson(p)).toList();
        debugPrint(
            'WallpaperProvider: Loaded ${_packs.length} packs from cache');
      } catch (e) {
        debugPrint('Error loading packs from cache: $e');
      }
    }

    notifyListeners();
  }

  void _saveToCache() {
    final box = _cacheBox;
    if (box == null) return;

    try {
      box.put('categories',
          json.encode(_categories.map((c) => c.toJson()).toList()));
      box.put('wallpapers',
          json.encode(_wallpapers.map((w) => w.toJson()).toList()));
      box.put('wide_wallpapers',
          json.encode(_wideWallpapers.map((w) => w.toJson()).toList()));
      // Save packs to cache
      box.put('packs', json.encode(_packs.map((p) => p.toJson()).toList()));
      debugPrint('WallpaperProvider: Saved ${_packs.length} packs to cache');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<void> loadMoreWallpapers() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getWallpapers(
        page: _currentPage + 1,
        limit: 20,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        isWide: false, // Explicitly exclude wide wallpapers
      );
      _wallpapers.addAll(response.wallpapers);
      _currentPage = response.page;
      _totalPages = response.pages;
      _hasMore = _currentPage < _totalPages;
    } catch (e) {
      debugPrint('Failed to load more wallpapers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    // Reload wallpapers for selected category from API
    if (category != 'all') {
      _loadCategoryWallpapers(category);
    }
  }

  Future<void> _loadCategoryWallpapers(String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getWallpapers(
        page: 1,
        limit: 30,
        category: category,
        isWide: false, // Explicitly exclude wide wallpapers
      );
      // Merge with existing wallpapers or filter
      final newWallpapers = response.wallpapers;
      for (final w in newWallpapers) {
        if (!_wallpapers.any((existing) => existing.id == w.id)) {
          _wallpapers.add(w);
        }
      }

      _currentPage = response.page;
      _totalPages = response.pages;
      _hasMore = _currentPage < _totalPages;
    } catch (e) {
      debugPrint('Failed to load category wallpapers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Wallpaper? getWallpaperById(String id) {
    try {
      return _wallpapers.firstWhere((w) => w.id == id);
    } catch (_) {
      try {
        return _wideWallpapers.firstWhere((w) => w.id == id);
      } catch (_) {
        for (var pack in _packs) {
          try {
            return pack.wallpapers.firstWhere((w) => w.id == id);
          } catch (_) {
            continue;
          }
        }
        return null;
      }
    }
  }

  WallpaperPack? getPackById(String id) {
    try {
      return _packs.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> trackDownload(String wallpaperId) async {
    try {
      await _apiService.trackDownload(wallpaperId);
    } catch (e) {
      debugPrint('Failed to track download: $e');
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _wallpapers = [];
    _wideWallpapers = [];
    await _initializeData();
  }
}
