import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/cached_image_config.dart';
import '../config/theme.dart';
import '../models/community_post.dart';
import '../screens/community/community_profile_screen.dart';

class CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with cached image manager
                CachedNetworkImage(
                  imageUrl: post.thumbnailUrl ?? post.imageUrl,
                  cacheManager: CachedImageConfig.cacheManager,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  memCacheWidth: 400,
                  placeholder: (_, __) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      color: AppTheme.getSurfaceVariant(isDark),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                  errorWidget: (_, __, ___) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      color: AppTheme.getSurfaceVariant(isDark),
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AppTheme.getTextMuted(isDark),
                      ),
                    );
                  },
                ),

                // Top right: Like button (dark translucent circle with heart)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    child: Center(
                      child: Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: post.isLiked
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.9),
                        size: 17,
                      ),
                    ),
                  ),
                ),

                // Subtle gradient at bottom for text visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // User photo, profile name and downloads counter
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // User Avatar
                      GestureDetector(
                        onTap: () {
                          if (post.author != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityProfileScreen(
                                  userId: post.author!.id,
                                  initialUser: post.author,
                                ),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: AppTheme.primary,
                          backgroundImage: post.author?.photoUrl != null
                              ? CachedNetworkImageProvider(
                                  post.author!.photoUrl!)
                              : null,
                          child: post.author?.photoUrl == null
                              ? Text(
                                  (post.author?.displayName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Profile Name
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (post.author != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommunityProfileScreen(
                                    userId: post.author!.id,
                                    initialUser: post.author,
                                  ),
                                ),
                              );
                            }
                          },
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
                      ),
                      const SizedBox(width: 6),

                      // Downloads Counter
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            post.downloadsCount >= 1000
                                ? '${(post.downloadsCount / 1000).toStringAsFixed(post.downloadsCount >= 10000 ? 0 : 1)}K'
                                : '${post.downloadsCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
