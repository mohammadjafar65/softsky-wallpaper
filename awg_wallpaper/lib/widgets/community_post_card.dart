import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/community_post.dart';
import '../screens/community/community_profile_screen.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final bool showLikes;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showLikes = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: post.thumbnailUrl ?? post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey.withValues(alpha: 0.15),
              ),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image_rounded, color: Colors.grey),
            ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Author + likes row
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      if (post.author != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityProfileScreen(
                                userId: post.author!.id),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: post.author?.photoUrl != null
                          ? CachedNetworkImageProvider(
                              post.author!.photoUrl!)
                          : null,
                      child: post.author?.photoUrl == null
                          ? Text(
                              (post.author?.displayName ?? 'A')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.author?.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.download_rounded,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 2),
                  Text(
                    '${post.downloadsCount}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.favorite_rounded,
                      size: 12, color: Colors.white70),
                  const SizedBox(width: 2),
                  Text(
                    '${post.likesCount}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
