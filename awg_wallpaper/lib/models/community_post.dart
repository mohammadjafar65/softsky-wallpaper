import 'community_user.dart';

class CommunityPost {
  final int id;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final int? width;
  final int? height;
  int likesCount;
  int commentsCount;
  int savesCount;
  bool isLiked;
  bool isSaved;
  final CommunityUser? author;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.width,
    this.height,
    required this.likesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.isLiked,
    required this.isSaved,
    this.author,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as int,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      savesCount: json['savesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      author: json['author'] != null
          ? CommunityUser.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
