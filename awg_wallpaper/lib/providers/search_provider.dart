import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wallpaper.dart';
import '../services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _query = '';
  List<Wallpaper> _results = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  String? _error;
  late Box _box;

  // Debounce timer
  Timer? _debounceTimer;
  int _requestId = 0;
  bool _disposed = false;
  static const _debounceDuration = Duration(milliseconds: 500);

  // Use API mode (set to false to use local search)
  bool _useApi = true;

  String get query => _query;
  List<Wallpaper> get results => _results;
  List<String> get searchHistory => _searchHistory;
  bool get isSearching => _isSearching;
  bool get hasResults => _results.isNotEmpty;
  String? get error => _error;

  SearchProvider() {
    _initBox();
  }

  Future<void> _initBox() async {
    _box = Hive.box('settings');
    _loadSearchHistory();
  }

  void _loadSearchHistory() {
    final List<dynamic>? history = _box.get('searchHistory');
    if (history != null) {
      _searchHistory = history.cast<String>();
      notifyListeners();
    }
  }

  Future<void> _saveSearchHistory() async {
    await _box.put('searchHistory', _searchHistory);
  }

  void setQuery(String query) {
    ++_requestId;
    _query = query.trim();
    _error = null;
    _results = [];
    _isSearching = _query.isNotEmpty;
    notifyListeners();

    // Debounce search
    _debounceTimer?.cancel();
    if (_query.isNotEmpty) {
      _debounceTimer = Timer(_debounceDuration, () {
        _performSearch();
      });
    } else {
      _results = [];
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Search using API or local data
  void search(List<Wallpaper> allWallpapers) {
    _debounceTimer?.cancel();
    if (_query.isEmpty) {
      _results = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    if (_useApi) {
      _performSearch();
    } else {
      _searchLocally(allWallpapers);
    }
  }

  /// Perform search using API
  Future<void> _performSearch() async {
    final requestId = ++_requestId;
    final query = _query;
    if (_query.isEmpty) {
      _results = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.searchWallpapers(query);
      if (_disposed || requestId != _requestId) return;
      _results = response.wallpapers;
      _error = null;
    } catch (e) {
      if (_disposed || requestId != _requestId) return;
      debugPrint('API search failed: $e');
      _error = 'Search failed. Please try again.';
      _results = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Search locally from provided wallpapers list
  void _searchLocally(List<Wallpaper> allWallpapers) {
    _isSearching = true;
    notifyListeners();

    final queryLower = _query.toLowerCase();
    _results = allWallpapers.where((wallpaper) {
      return wallpaper.title.toLowerCase().contains(queryLower) ||
          wallpaper.category.toLowerCase().contains(queryLower);
    }).toList();

    _isSearching = false;
    notifyListeners();
  }

  /// Search with custom query (instant, for history tap)
  Future<void> searchWithQuery(String query) async {
    _debounceTimer?.cancel();
    _query = query.trim();
    notifyListeners();
    await _performSearch();
    if (!_disposed && _query == query.trim()) await addToHistory(_query);
  }

  Future<void> addToHistory(String query) async {
    if (query.isEmpty) return;

    // Remove existing entry if present
    _searchHistory.remove(query);
    // Add to beginning
    _searchHistory.insert(0, query);
    // Keep only last 10
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.take(10).toList();
    }
    await _saveSearchHistory();
    notifyListeners();
  }

  Future<void> removeFromHistory(String query) async {
    _searchHistory.remove(query);
    await _saveSearchHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
    notifyListeners();
  }

  void clearSearch() {
    ++_requestId;
    _debounceTimer?.cancel();
    _query = '';
    _results = [];
    _isSearching = false;
    _error = null;
    notifyListeners();
  }

  void setUseApi(bool useApi) {
    _useApi = useApi;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_requestId;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
