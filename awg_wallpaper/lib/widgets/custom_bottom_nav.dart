import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const double _barWidth = 256.0;
  static const double _barHeight = 58.0;
  static const double _itemWidth = _barWidth / 4.0; // 64.0
  static const double _circleSize = 48.0;

  static const List<IconData> _icons = [
    Icons.groups_outlined,
    Icons.photo_library_outlined,
    Icons.bookmark_outline_rounded,
    Icons.folder_outlined,
  ];

  static const List<IconData> _activeIcons = [
    Icons.groups_rounded,
    Icons.photo_library_rounded,
    Icons.bookmark_rounded,
    Icons.folder_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    // Keep within bounds of 4 tabs
    final safeIndex = currentIndex.clamp(0, 3);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: _barWidth,
              height: _barHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF202024).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(29),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Animated sliding blue circular indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: safeIndex * _itemWidth + (_itemWidth - _circleSize) / 2.0,
                    top: (_barHeight - _circleSize) / 2.0,
                    width: _circleSize,
                    height: _circleSize,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2B5CE6),
                            Color(0xFF1E45C8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B5CE6).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: Offset.zero,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4 Equally Spaced Interactive Slots
                  Row(
                    children: List.generate(4, (index) {
                      final isSelected = safeIndex == index;
                      return SizedBox(
                        width: _itemWidth,
                        height: _barHeight,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onTap(index);
                            },
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Center(
                              child: AnimatedScale(
                                scale: isSelected ? 1.05 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  isSelected ? _activeIcons[index] : _icons[index],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.88),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

