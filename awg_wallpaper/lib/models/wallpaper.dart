class Wallpaper {
  final String id;
  final String title;
  final String imageUrl;
  final String thumbnailUrl;
  final String category;
  final bool isWide;
  final bool isPro;
  final String? packId;
  final DateTime? createdAt;

  Wallpaper({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.category,
    this.isWide = false,
    this.isPro = false,
    this.packId,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'isWide': isWide,
      'isPro': isPro,
      'packId': packId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    // Helper to ensure URLs use HTTPS (Android blocks cleartext HTTP)
    String ensureHttps(String? url) {
      if (url == null) return '';
      if (url.startsWith('http://')) {
        return url.replaceFirst('http://', 'https://');
      }
      return url;
    }

    // Handle category which can be an Object (MySQL) or String (Legacy/Mongo)
    String parseCategory(dynamic categoryData) {
      if (categoryData is Map<String, dynamic>) {
        // Try id, _id, name, slug
        if (categoryData['id'] != null) return categoryData['id'].toString();
        if (categoryData['_id'] != null) return categoryData['_id'].toString();
        return categoryData['name']?.toString() ??
            categoryData['slug']?.toString() ??
            '';
      }
      return categoryData?.toString() ?? '';
    }

    return Wallpaper(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      imageUrl: ensureHttps(json['imageUrl']?.toString()),
      thumbnailUrl: ensureHttps(json['thumbnailUrl']?.toString()),
      category: parseCategory(json['category']),
      isWide: json['isWide'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
      packId: json['packId']?.toString(), // Use toString() for safety
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Wallpaper copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? thumbnailUrl,
    String? category,
    bool? isWide,
    bool? isPro,
    String? packId,
    DateTime? createdAt,
  }) {
    return Wallpaper(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      isWide: isWide ?? this.isWide,
      isPro: isPro ?? this.isPro,
      packId: packId ?? this.packId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallpaper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
