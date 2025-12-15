import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/wallpaper.dart';
import '../models/wallpaper_pack.dart';
import '../models/category.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class WallpaperProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Wallpaper> _wallpapers = [];
  List<Wallpaper> _wideWallpapers = [];
  List<WallpaperPack> _packs = [];
  List<Category> _categories = [];
  String _selectedCategory = 'all';
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Use API mode (set to false to use sample data)
  bool _useApi = true;

  List<Wallpaper> get wallpapers => _selectedCategory == 'all'
      ? _wallpapers.where((w) => !w.isWide).toList()
      : _wallpapers
          .where((w) => w.category == _selectedCategory && !w.isWide)
          .toList();

  List<Wallpaper> get allWallpapers => _wallpapers;
  List<Wallpaper> get wideWallpapers => _wideWallpapers;
  List<WallpaperPack> get packs => _packs;
  List<WallpaperPack> get freePacks => _packs.where((p) => !p.isPro).toList();
  List<WallpaperPack> get proPacks => _packs.where((p) => p.isPro).toList();
  List<Category> get categories => _categories;
  String get selectedCategory => _selectedCategory;
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
    if (_useApi) {
      _loadFromCache();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_useApi) {
        await _loadFromApi();
      } else {
        _loadSampleData();
      }
    } catch (e) {
      // debugPrint('API initialization failed, falling back to sample data: $e');
      // Only fallback to sample data if cache was empty
      if (_wallpapers.isEmpty) {
        _error = 'Failed to connect to server. Using offline data.';
        _loadSampleData();
      } else {
        debugPrint('API failed but we have cached data');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromApi() async {
    try {
      // Run requests in parallel to speed up loading
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getWallpapers(page: 1, limit: 30, isWide: false),
        _apiService.getWallpapers(page: 1, limit: 20, isWide: true),
      ]);

      // 1. Categories
      final fetchedCategories = results[0] as List<Category>;
      if (!fetchedCategories.any((c) => c.id == 'all')) {
        fetchedCategories.insert(
            0, const Category(id: 'all', name: 'All', icon: '✨'));
      }
      _categories = fetchedCategories;

      // 2. Wallpapers
      final wallpapersResponse = results[1] as WallpapersResponse;
      _wallpapers = wallpapersResponse.wallpapers;
      _currentPage = wallpapersResponse.page;
      _totalPages = wallpapersResponse.pages;
      _hasMore = _currentPage < _totalPages;

      // 3. Wide Wallpapers
      final wideWallpapersResponse = results[2] as WallpapersResponse;
      _wideWallpapers = wideWallpapersResponse.wallpapers;

      // Save to cache
      _saveToCache();
    } catch (e) {
      debugPrint('Failed to load data from API: $e');
      rethrow;
    }

    // For now, packs are sample data (can be extended for API later)
    _generateSamplePacks();
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
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  void _loadSampleData() {
    // _categories =
    //     AppConstants.categories.map((c) => Category.fromMap(c)).toList();
    _generateSampleWallpapers();
    _generateSampleWideWallpapers();
    _generateSamplePacks();
  }

  Future<void> loadMoreWallpapers() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (_useApi) {
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
      }
    } catch (e) {
      debugPrint('Failed to load more wallpapers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _generateSampleWallpapers() {
    final categoryIds = [
      'abstract',
      'amoled',
      'animal',
      'aesthetic',
      'nature',
      'space',
      'minimal',
      'gradient',
      'dark'
    ];
    final titles = [
      'Cosmic Dreams',
      'Midnight Waves',
      'Aurora Borealis',
      'Neon City',
      'Mystic Forest',
      'Ocean Depths',
      'Mountain Peak',
      'Desert Sunset',
      'Crystal Cave',
      'Starlight',
      'Velvet Night',
      'Golden Hour',
      'Electric Storm',
      'Zen Garden',
      'Fire & Ice',
      'Moonlight',
    ];

    _wallpapers = List.generate(50, (index) {
      final id = index + 1;
      final category = categoryIds[index % categoryIds.length];
      final titleIndex = index % titles.length;

      return Wallpaper(
        id: 'wall_$id',
        title: '${titles[titleIndex]} $id',
        imageUrl: 'https://picsum.photos/seed/wall$id/1080/1920',
        thumbnailUrl: 'https://picsum.photos/seed/wall$id/540/960',
        category: category,
        isPro: index % 7 == 0,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      );
    });
    _hasMore = false;
  }

  void _generateSampleWideWallpapers() {
    final titles = [
      'Desktop Dreams',
      'Wide Horizon',
      'Panoramic View',
      'Ultra Screen',
      'Landscape Beauty',
      'Wide World',
      'Extended Vision',
      'Full Screen',
    ];

    _wideWallpapers = List.generate(20, (index) {
      final id = index + 100;
      final titleIndex = index % titles.length;

      return Wallpaper(
        id: 'wide_$id',
        title: '${titles[titleIndex]} $id',
        imageUrl: 'https://picsum.photos/seed/wide$id/1920/1080',
        thumbnailUrl: 'https://picsum.photos/seed/wide$id/480/270',
        category: 'wide',
        isWide: true,
        isPro: index % 5 == 0,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }

  void _generateSamplePacks() {
    final packData = [
      {
        'name': 'Neon Dreams',
        'desc': 'Vibrant neon aesthetics',
        'isPro': false
      },
      {
        'name': 'Dark Elegance',
        'desc': 'Premium dark wallpapers',
        'isPro': false
      },
      {
        'name': 'Nature\'s Beauty',
        'desc': 'Natural landscapes',
        'isPro': false
      },
      {
        'name': 'Abstract Art',
        'desc': 'Modern abstract designs',
        'isPro': false
      },
      {'name': 'Space Explorer', 'desc': 'Cosmic wallpapers', 'isPro': true},
      {'name': 'Minimal Pro', 'desc': 'Clean minimal designs', 'isPro': true},
      {
        'name': 'Gradient Masters',
        'desc': 'Beautiful gradients',
        'isPro': true
      },
      {'name': 'AMOLED Black', 'desc': 'True black wallpapers', 'isPro': false},
      {'name': 'Luxury Collection', 'desc': 'Premium exclusive', 'isPro': true},
      {'name': 'Aesthetic Vibes', 'desc': 'Trendy aesthetics', 'isPro': false},
    ];

    _packs = packData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final packId = 'pack_${index + 1}';

      final packWallpapers = List.generate(8, (wIndex) {
        final wId = (index * 10) + wIndex + 200;
        return Wallpaper(
          id: 'pack_wall_$wId',
          title: '${data['name']} #${wIndex + 1}',
          imageUrl: 'https://picsum.photos/seed/pack$wId/1080/1920',
          thumbnailUrl: 'https://picsum.photos/seed/pack$wId/540/960',
          category: 'pack',
          isPro: data['isPro'] as bool,
          packId: packId,
        );
      });

      return WallpaperPack(
        id: packId,
        name: data['name'] as String,
        description: data['desc'] as String,
        coverImage: 'https://picsum.photos/seed/pack${index}cover/800/1200',
        wallpapers: packWallpapers,
        isPro: data['isPro'] as bool,
        author: 'AWG Studio',
      );
    }).toList();
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    // Reload wallpapers for selected category from API
    if (_useApi && category != 'all') {
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

  // Toggle between API and sample data (useful for testing)
  void setUseApi(bool useApi) {
    if (_useApi == useApi) return;
    _useApi = useApi;
    refresh();
  }
}
