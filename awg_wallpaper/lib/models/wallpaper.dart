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
    String ensureHttps(String url) {
      if (url.startsWith('http://')) {
        return url.replaceFirst('http://', 'https://');
      }
      return url;
    }

    return Wallpaper(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String,
      imageUrl: ensureHttps(json['imageUrl'] as String),
      thumbnailUrl: ensureHttps(json['thumbnailUrl'] as String),
      category: json['category'] is Map<String, dynamic>
          ? json['category']['_id'] as String
          : json['category'] as String,
      isWide: json['isWide'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
      packId: json['packId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
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
