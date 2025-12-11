import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/wallpaper.dart';
import '../providers/bookmark_provider.dart';

class WideWallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final VoidCallback onTap;
  
  const WideWallpaperCard({
    super.key,
    required this.wallpaper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'wallpaper_${wallpaper.id}',
        child: Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: wallpaper.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceVariant,
                    child: const Icon(
                      Icons.error_outline,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                
                // Desktop icon
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.desktop_windows_rounded,
                          color: Colors.black, // Dark icon on pastel blue
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'WIDE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Pro badge
                if (wallpaper.isPro)
                  Positioned(
                    top: 16,
                    right: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.gold, Color(0xFFFFB700)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Bookmark button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final isBookmarked = bookmarkProvider.isBookmarked(wallpaper.id);
                      return GestureDetector(
                        onTap: () {
                          bookmarkProvider.toggleBookmark(wallpaper);
                        },
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isBookmarked
                                ? AppTheme.primary
                                : Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBookmarked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Title at bottom left
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallpaper.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For Desktop & Tablets',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
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
