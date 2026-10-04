import 'dart:async';
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
  String _selectedProCategory = 'all';
  int _totalWallpapers = 0;
  int _totalFreeWallpapers = 0;
  int _totalProWallpapers = 0;
  bool _isLoading = true; // Start with loading state
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Pro Pagination
  List<Wallpaper> _proWallpapersList = [];
  int _currentProPage = 1;
  // int _totalProPages = 1; // Unused
  bool _hasMorePro = true;
  bool _isProLoading = false;
  int _proRequestId = 0;
  int _freeRequestId = 0;
  int _refreshId = 0;
  bool _disposed = false;
  Future<void>? _refreshFuture;
  List<Wallpaper> _categoryWallpapers = [];
  List<Wallpaper> _allProWallpapers = [];
  bool _freeLoading = false;

  // Use API mode (set to false to use sample data)
  // bool _useApi = true;

  List<Wallpaper> get wallpapers => _selectedCategory == 'all'
      ? _wallpapers.where((w) => !w.isPro && !w.isWide).toList()
      : _categoryWallpapers.where((w) => !w.isPro && !w.isWide).toList();

  List<Wallpaper> get allWallpapers => _wallpapers;
  List<Wallpaper> get wideWallpapers => _wideWallpapers;
  List<WallpaperPack> get packs => _packs;
  List<WallpaperPack> get freePacks => _packs.where((p) => !p.isPro).toList();
  List<WallpaperPack> get proPacks => _packs.where((p) => p.isPro).toList();
  List<Category> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get selectedProCategory => _selectedProCategory;
  int get totalWallpapers => _totalWallpapers;
  int get totalFreeWallpapers => _totalFreeWallpapers;
  int get totalProWallpapers => _totalProWallpapers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Pro Getters
  List<Wallpaper> get proWallpapersList => _proWallpapersList;
  bool get hasMorePro => _hasMorePro;
  bool get isProLoading => _isProLoading;

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
    _loadFromCache();
    await refresh();
  }

  Future<void> _loadFromApi() async {
    final refreshId = ++_refreshId;
    // Publish each section when it arrives; a slow optional section must not
    // prevent the free feed from leaving its loading state.
    Future<void> loadSection(Future<void> Function() load) async {
      try {
        await load();
      } catch (e) {
        debugPrint('Wallpaper section refresh failed: $e');
      }
    }

    await Future.wait([
      _loadFreeWallpapers(replace: true),
      loadProWallpapers(refresh: true, force: true),
      loadSection(() async {
        final categories = await _apiService.getCategories();
        if (_disposed || refreshId != _refreshId) return;
        if (!categories.any((c) => c.id == 'all')) {
          categories.insert(
              0, const Category(id: 'all', name: 'All', icon: '✨'));
        }
        _categories = categories;
        notifyListeners();
      }),
      loadSection(() async {
        final response =
            await _apiService.getWallpapers(page: 1, limit: 15, isWide: true);
        if (_disposed || refreshId != _refreshId) return;
        _wideWallpapers =
            response.wallpapers.map((w) => w.copyWith(isPro: true)).toList();
        _wideTotal = response.total;
        _updateTotal();
        notifyListeners();
      }),
      loadSection(() async {
        final packs = await _packService.getPacks(page: 1, limit: 20);
        if (_disposed || refreshId != _refreshId) return;
        _packs = packs;
        notifyListeners();
      }),
    ]);
    if (!_disposed && refreshId == _refreshId) _saveToCache();
  }

  int _wideTotal = 0;

  void _updateTotal() {
    _totalWallpapers = _totalFreeWallpapers + _totalProWallpapers + _wideTotal;
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
        _sortWallpapers(_wallpapers);
      } catch (e) {
        debugPrint('Error loading wallpapers from cache: $e');
      }
    }

    if (box.containsKey('wide_wallpapers')) {
      try {
        final List<dynamic> wideJson = json.decode(box.get('wide_wallpapers'));
        _wideWallpapers = wideJson.map((w) => Wallpaper.fromJson(w)).toList();
        _sortWallpapers(_wideWallpapers);
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

    // Load pro wallpapers from cache
    if (box.containsKey('pro_wallpapers')) {
      try {
        final List<dynamic> proJson = json.decode(box.get('pro_wallpapers'));
        _proWallpapersList = proJson.map((w) => Wallpaper.fromJson(w)).toList();
        _sortWallpapers(_proWallpapersList);
        _allProWallpapers = List.of(_proWallpapersList);
      } catch (e) {
        debugPrint('Error loading pro wallpapers from cache: $e');
      }
    }

    notifyListeners();
  }

  void _sortWallpapers(List<Wallpaper> list) {
    list.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      final aId = int.tryParse(a.id) ?? 0;
      final bId = int.tryParse(b.id) ?? 0;
      return bId.compareTo(aId);
    });
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
      // Save pro wallpapers to cache
      box.put('pro_wallpapers',
          json.encode(_allProWallpapers.map((w) => w.toJson()).toList()));

      debugPrint('WallpaperProvider: Saved ${_packs.length} packs to cache');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<void> loadMoreWallpapers() async {
    if (_freeLoading || !_hasMore) return;
    await _loadFreeWallpapers(replace: false);
  }

  Future<void> _loadFreeWallpapers({required bool replace}) async {
    final requestId = ++_freeRequestId;
    final category = _selectedCategory;
    final page = replace ? 1 : _currentPage + 1;
    _freeLoading = true;
    _isLoading = replace ? wallpapers.isEmpty : true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.getWallpapers(
        page: page,
        limit: 20,
        isPro: false,
        category: category == 'all' ? null : category,
        isWide: false,
      );
      if (_disposed || requestId != _freeRequestId) return;
      final existing = category == 'all' ? _wallpapers : _categoryWallpapers;
      final items = replace ? <Wallpaper>[] : List<Wallpaper>.of(existing);
      final ids = items.map((w) => w.id).toSet();
      items.addAll(response.wallpapers.where((w) => ids.add(w.id)));
      if (category == 'all') {
        _wallpapers = items;
        _totalFreeWallpapers = response.total;
        _updateTotal();
      } else {
        _categoryWallpapers = items;
      }
      _currentPage = response.page;
      _totalPages = response.pages;
      _hasMore = _currentPage < _totalPages;
      if (category == 'all') _saveToCache();
    } catch (e) {
      if (_disposed || requestId != _freeRequestId) return;
      _error = 'Failed to load wallpapers. Please try again.';
      debugPrint('Failed to load wallpapers: $e');
    } finally {
      if (!_disposed && requestId == _freeRequestId) {
        _freeLoading = false;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _categoryWallpapers = [];
    _currentPage = 1;
    _hasMore = true;
    _loadFreeWallpapers(replace: true);
  }

  Future<void> loadProWallpapers({
    bool refresh = false,
    bool force = false,
  }) async {
    if (!refresh && !force && (_isProLoading || !_hasMorePro)) return;

    if (refresh || force) {
      _currentProPage = 1;
      _hasMorePro = true;
    }

    _isProLoading = true;
    final requestId = ++_proRequestId;
    final category = _selectedProCategory;
    final page = _currentProPage;
    notifyListeners();

    try {
      debugPrint(
          '[ProWallpapers] Loading for category: \'$_selectedProCategory\' (sent: \'${_selectedProCategory == 'all' ? null : _selectedProCategory}\')');
      final response = await _apiService.getWallpapers(
        page: page,
        limit: 20,
        isPro: true,
        isWide: false,
        category: category == 'all' ? null : category,
      );
      debugPrint(
          '[ProWallpapers] API returned count: \'${response.wallpapers.length}\'');
      if (_disposed || requestId != _proRequestId) {
        return;
      }

      if (refresh || force || page == 1) {
        _proWallpapersList = response.wallpapers;
      } else {
        for (final w in response.wallpapers) {
          if (!_proWallpapersList.any((existing) => existing.id == w.id)) {
            _proWallpapersList.add(w);
          }
        }
      }

      _currentProPage = response.page + 1;
      _hasMorePro = response.page < response.pages;

      if (category == 'all') {
        _totalProWallpapers = response.total;
        _updateTotal();
        _allProWallpapers = List.of(_proWallpapersList);
        _saveToCache();
      }
    } catch (e) {
      debugPrint('Failed to load pro wallpapers: $e');
    }

    if (requestId == _proRequestId) {
      _isProLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProWallpapers() async {
    await loadProWallpapers(refresh: false);
  }

  void setSelectedProCategory(String category, {bool reload = false}) {
    if (_selectedProCategory == category && !reload) return;
    _selectedProCategory = category;
    if (reload) {
      _proWallpapersList = category == 'all' ? List.of(_allProWallpapers) : [];
    }
    notifyListeners();

    if (reload) {
      loadProWallpapers(refresh: true, force: true);
    }
  }

  Wallpaper? getWallpaperById(String id) {
    for (final wallpaper in _categoryWallpapers) {
      if (wallpaper.id == id) return wallpaper;
    }
    try {
      return _wallpapers.firstWhere((w) => w.id == id);
    } catch (_) {
      try {
        return _wideWallpapers.firstWhere((w) => w.id == id);
      } catch (_) {
        try {
          // Check pro list
          return _proWallpapersList.firstWhere((w) => w.id == id);
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
  }

  WallpaperPack? getPackById(String id) {
    try {
      return _packs.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int?> trackDownload(String wallpaperId) async {
    try {
      final downloads = await _apiService.trackDownload(wallpaperId);
      if (downloads != null) {
        _replaceWallpaperDownloadCount(wallpaperId, downloads);
        _saveToCache();
        notifyListeners();
      }
      return downloads;
    } catch (e) {
      debugPrint('Failed to track download: $e');
      return null;
    }
  }

  void _replaceWallpaperDownloadCount(String wallpaperId, int downloads) {
    List<Wallpaper> replaceInList(List<Wallpaper> source) {
      return source
          .map((wallpaper) => wallpaper.id == wallpaperId
              ? wallpaper.copyWith(downloads: downloads)
              : wallpaper)
          .toList();
    }

    _wallpapers = replaceInList(_wallpapers);
    _categoryWallpapers = replaceInList(_categoryWallpapers);
    _wideWallpapers = replaceInList(_wideWallpapers);
    _proWallpapersList = replaceInList(_proWallpapersList);
    _allProWallpapers = replaceInList(_allProWallpapers);
    _packs = _packs
        .map(
            (pack) => pack.copyWith(wallpapers: replaceInList(pack.wallpapers)))
        .toList();
  }

  Future<void> refresh() {
    return _refreshFuture ??= _refreshData().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<void> _refreshData() async {
    _error = null;
    await _loadFromApi();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_freeRequestId;
    ++_proRequestId;
    ++_refreshId;
    super.dispose();
  }
}
