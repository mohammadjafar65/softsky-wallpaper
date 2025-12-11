import 'package:flutter/foundation.dart';
import '../models/wallpaper_pack.dart';
import '../services/pack_service.dart';

class PackProvider with ChangeNotifier {
  final PackService _packService = PackService();

  List<WallpaperPack> _packs = [];
  bool _isLoading = false;
  String? _error;

  List<WallpaperPack> get packs => _packs;
  List<WallpaperPack> get freePacks => _packs.where((p) => !p.isPro).toList();
  List<WallpaperPack> get proPacks => _packs.where((p) => p.isPro).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPacks({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _packs = [];
    }

    if (_packs.isNotEmpty && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _packs = await _packService.getPacks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WallpaperPack?> getPackDetails(String id) async {
    try {
      return await _packService.getPackDetails(id);
    } catch (e) {
      print('Error fetching pack details: $e');
      return null;
    }
  }
}
