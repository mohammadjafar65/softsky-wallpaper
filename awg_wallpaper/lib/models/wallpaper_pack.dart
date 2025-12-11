import 'wallpaper.dart';

class WallpaperPack {
  final String id;
  final String name;
  final String description;
  final String coverImage;
  final List<Wallpaper> wallpapers;
  final bool isPro;
  final int wallpaperCount;
  final String? author;
  final DateTime? createdAt;
  
  WallpaperPack({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImage,
    required this.wallpapers,
    this.isPro = false,
    int? wallpaperCount,
    this.author,
    this.createdAt,
  }) : wallpaperCount = wallpaperCount ?? wallpapers.length;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'wallpapers': wallpapers.map((w) => w.toJson()).toList(),
      'isPro': isPro,
      'wallpaperCount': wallpaperCount,
      'author': author,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  factory WallpaperPack.fromJson(Map<String, dynamic> json) {
    return WallpaperPack(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coverImage: json['coverImage'] as String,
      wallpapers: (json['wallpapers'] as List)
          .map((w) => Wallpaper.fromJson(w as Map<String, dynamic>))
          .toList(),
      isPro: json['isPro'] as bool? ?? false,
      wallpaperCount: json['wallpaperCount'] as int?,
      author: json['author'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
