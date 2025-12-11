import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/wallpaper.dart';
import '../providers/bookmark_provider.dart';

class WallpaperCard extends StatefulWidget {
  final Wallpaper wallpaper;
  final VoidCallback onTap;
  final bool showBookmark;
  final double? height;
  
  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.onTap,
    this.showBookmark = true,
    this.height,
  });

  @override
  State<WallpaperCard> createState() => _WallpaperCardState();
}

class _WallpaperCardState extends State<WallpaperCard> with SingleTickerProviderStateMixin {
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
    return GestureDetector(
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
        child: Hero(
          tag: 'wallpaper_${widget.wallpaper.id}',
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: widget.wallpaper.thumbnailUrl,
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
                    child: const Icon(Icons.error_outline, color: AppTheme.textMuted),
                  ),
                ),
                
                // Subtle gradient for text visibility at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Pro Badge (Minimal)
                if (widget.wallpaper.isPro)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star_rounded, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                // Bookmark Icon
                if (widget.showBookmark)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<BookmarkProvider>(
                      builder: (context, provider, child) {
                        final isBookmarked = provider.isBookmarked(widget.wallpaper.id);
                        return GestureDetector(
                          onTap: () => provider.toggleBookmark(widget.wallpaper),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 18,
                              color: isBookmarked ? AppTheme.error : Colors.white,
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
