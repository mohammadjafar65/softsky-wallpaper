import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 55),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isSelected: currentIndex == 0,
                color: AppTheme.textSecondary,
                onTap: () => onTap(0),
              ),
              _NavIcon(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                isSelected: currentIndex == 1,
                color: AppTheme.textSecondary,
                onTap: () => onTap(1),
              ),
              _CenterIcon(
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavIcon(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                isSelected: currentIndex == 3,
                color: AppTheme.textSecondary,
                onTap: () => onTap(3),
              ),
              _NavIcon(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                isSelected: currentIndex == 4,
                color: AppTheme.textSecondary,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  
  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 70,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppTheme.primary : (color ?? AppTheme.textSecondary),
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterIcon extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  
  const _CenterIcon({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
