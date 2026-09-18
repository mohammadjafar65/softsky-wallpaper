import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';

class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final bool isWide;

  const ShimmerLoading({
    super.key,
    this.itemCount = 6,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: AppTheme.getShimmerBase(isDark),
      highlightColor: AppTheme.getShimmerHighlight(isDark),
      child: isWide ? _buildWideGrid(isDark) : _buildStaggeredGrid(isDark),
    );
  }

  Widget _buildStaggeredGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
      },
    );
  }

  Widget _buildWideGrid(bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
      },
    );
  }
}

class ShimmerPackCard extends StatelessWidget {
  const ShimmerPackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: AppTheme.getShimmerBase(isDark),
      highlightColor: AppTheme.getShimmerHighlight(isDark),
      child: Container(
        width: 160,
        height: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(isDark),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}

