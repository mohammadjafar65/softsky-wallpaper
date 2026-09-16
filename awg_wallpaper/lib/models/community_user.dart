class CommunityUser {
  final int id;
  final String displayName;
  final String? photoUrl;
  final String? username;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;

  const CommunityUser({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.username,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isFollowing,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: json['id'] as int,
      displayName: json['displayName'] as String? ?? 'Anonymous',
      photoUrl: json['photoUrl'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  CommunityUser copyWith({bool? isFollowing, int? followersCount}) {
    return CommunityUser(
      id: id,
      displayName: displayName,
      photoUrl: photoUrl,
      username: username,
      bio: bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
