import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/theme.dart';
import '../models/wallpaper_pack.dart';
import '../widgets/glass_container.dart';

class PackCard extends StatelessWidget {
  final WallpaperPack pack;
  final VoidCallback onTap;
  final bool isLarge;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const PackCard({
    super.key,
    required this.pack,
    required this.onTap,
    this.isLarge = false,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided values or defaults based on isLarge
    final EdgeInsetsGeometry defaultMargin =
        EdgeInsets.only(right: isLarge ? 0 : 16);

    return Container(
      width: width ??
          (isLarge
              ? double.infinity
              : null), // Let grid control width if not specified
      height: height ??
          (isLarge ? 200 : null), // Let grid control height if not specified
      margin: margin ?? defaultMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image
            CachedNetworkImage(
              imageUrl: pack.coverImage,
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
                  Icons.broken_image_rounded,
                  color: AppTheme.textMuted,
                  size: 40,
                ),
              ),
            ),

            // 2. Gradient Overlay (Bottom Up)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Ripple Effect (InkWell)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: Colors.white.withValues(alpha: 0.1),
                highlightColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),

            // 4. Content (Text & Count)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: IgnorePointer(
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderRadius: 14,
                  blur: 10,
                  opacity: 0.3,
                  color: Colors.black,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pack.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pack.wallpaperCount} Wallpapers',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. PRO Badge (Top Right)
            if (pack.isPro)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: Colors.black87,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
