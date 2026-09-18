import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/category.dart';
import '../widgets/glass_container.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 50,
        blur: isSelected ? 0 : 10,
        opacity: isSelected ? 1.0 : (isDark ? 0.1 : 0.85),
        color: isSelected
            ? AppTheme.primary
            : (isDark ? AppTheme.darkSurfaceVariant : AppTheme.surfaceVariant),
        border: isSelected
            ? Border.all(color: Colors.transparent, width: 0)
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.name,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.getTextSecondary(isDark),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.icon,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
