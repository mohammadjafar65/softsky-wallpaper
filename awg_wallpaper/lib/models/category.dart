class Category {
  final String id;
  final String name;
  final String icon;
  final String? slug;
  final String? description;
  final int wallpaperCount;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.slug,
    this.description,
    this.wallpaperCount = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      slug: map['slug'] as String?,
      description: map['description'] as String?,
      wallpaperCount: map['wallpaperCount'] as int? ?? 0,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎨',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      wallpaperCount: json['wallpaperCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'slug': slug,
      'description': description,
      'wallpaperCount': wallpaperCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
