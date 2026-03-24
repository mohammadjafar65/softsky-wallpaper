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
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: wallpaper.thumbnailUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF232323),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF232323),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                    ),
                  ),
                ),

                // Minimal bottom gradient overlay
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color.fromARGB(120, 0, 0, 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // PRO badge (only if pro)
                if (wallpaper.isPro)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFD700)),
                          SizedBox(width: 3),
                          Text('PRO', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),

                // Floating modern bookmark button
                Positioned(
                  top: 14,
                  right: 14,
                  child: Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final isBookmarked = bookmarkProvider.isBookmarked(wallpaper.id);
                      return GestureDetector(
                        onTap: () {
                          bookmarkProvider.toggleBookmark(wallpaper);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isBookmarked ? const Color(0xFFFF4081).withOpacity(0.18) : Colors.black.withOpacity(0.28),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isBookmarked ? const Color(0xFFFF4081).withOpacity(0.5) : Colors.white.withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isBookmarked ? const Color(0xFFFF4081) : Colors.white,
                            size: 20,
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

