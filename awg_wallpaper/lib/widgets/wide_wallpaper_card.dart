import 'dart:ui';
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
          height: 185,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: wallpaper.thumbnailUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF1E1E1E),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF1E1E1E),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                    ),
                  ),
                ),

                // Subtle gradient overlay for text readability if needed
                // But keeping it clean for now, just a bottom touch if we had text
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Pro badge - Glassmorphic
                Positioned(
                  top: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFD700),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PRO',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bookmark button - Glassmorphic
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final isBookmarked =
                          bookmarkProvider.isBookmarked(wallpaper.id);
                      return GestureDetector(
                        onTap: () {
                          bookmarkProvider.toggleBookmark(wallpaper);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBookmarked
                                    ? const Color(0xFFFF4081).withOpacity(0.2)
                                    : Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isBookmarked
                                      ? const Color(0xFFFF4081).withOpacity(0.5)
                                      : Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                isBookmarked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isBookmarked
                                    ? const Color(0xFFFF4081)
                                    : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
