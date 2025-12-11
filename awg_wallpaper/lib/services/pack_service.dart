import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/wallpaper_pack.dart';
import '../models/wallpaper.dart';

class PackService {
  Future<List<WallpaperPack>> getPacks({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/packs?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> packsJson = data['packs'];
        return packsJson.map((json) => WallpaperPack.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load packs');
      }
    } catch (e) {
      throw Exception('Error fetching packs: $e');
    }
  }

  Future<WallpaperPack> getPackDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/packs/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final packData = data['pack'];
        final List<dynamic> wallpapersJson = data['wallpapers'];

        // Create full pack object with wallpapers
        // final pack = WallpaperPack.fromJson(packData);
        // Since WallpaperPack model has final list, we might need to recreate it or ensure fromJson handles it if the list is passed separately
        // Our backend returns { pack: ..., wallpapers: ... }
        // Looking at WallpaperPack.fromJson, it expects wallpapers inside the json map.
        // So we need to merge them.

        final Map<String, dynamic> mergedJson = Map.from(packData);
        mergedJson['wallpapers'] = wallpapersJson;

        return WallpaperPack.fromJson(mergedJson);
      } else {
        throw Exception('Failed to load pack details');
      }
    } catch (e) {
      throw Exception('Error fetching pack details: $e');
    }
  }
}
