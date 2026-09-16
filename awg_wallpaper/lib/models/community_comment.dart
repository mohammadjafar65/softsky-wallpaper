import 'community_user.dart';

class CommunityComment {
  final int id;
  final String content;
  final CommunityUser author;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as int,
      content: json['content'] as String,
      author: CommunityUser.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
