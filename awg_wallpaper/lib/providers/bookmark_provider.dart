import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wallpaper.dart';

class BookmarkProvider extends ChangeNotifier {
  final List<Wallpaper> _bookmarks = [];
  late Box _box;
  bool _isInitialized = false;
  
  List<Wallpaper> get bookmarks => _bookmarks;
  int get bookmarkCount => _bookmarks.length;
  
  BookmarkProvider() {
    _initBox();
  }
  
  Future<void> _initBox() async {
    _box = Hive.box('bookmarks');
    _loadBookmarks();
    _isInitialized = true;
  }
  
  void _loadBookmarks() {
    final List<dynamic>? storedBookmarks = _box.get('bookmarks');
    if (storedBookmarks != null) {
      _bookmarks.clear();
      for (var item in storedBookmarks) {
        try {
          final map = jsonDecode(item as String) as Map<String, dynamic>;
          _bookmarks.add(Wallpaper.fromJson(map));
        } catch (e) {
          debugPrint('Error loading bookmark: $e');
        }
      }
      notifyListeners();
    }
  }
  
  Future<void> _saveBookmarks() async {
    final List<String> serialized = _bookmarks
        .map((w) => jsonEncode(w.toJson()))
        .toList();
    await _box.put('bookmarks', serialized);
  }
  
  bool isBookmarked(String wallpaperId) {
    return _bookmarks.any((w) => w.id == wallpaperId);
  }
  
  Future<void> toggleBookmark(Wallpaper wallpaper) async {
    if (isBookmarked(wallpaper.id)) {
      await removeBookmark(wallpaper.id);
    } else {
      await addBookmark(wallpaper);
    }
  }
  
  Future<void> addBookmark(Wallpaper wallpaper) async {
    if (!isBookmarked(wallpaper.id)) {
      _bookmarks.insert(0, wallpaper);
      await _saveBookmarks();
      notifyListeners();
    }
  }
  
  Future<void> removeBookmark(String wallpaperId) async {
    _bookmarks.removeWhere((w) => w.id == wallpaperId);
    await _saveBookmarks();
    notifyListeners();
  }
  
  Future<void> clearAllBookmarks() async {
    _bookmarks.clear();
    await _saveBookmarks();
    notifyListeners();
  }
}
