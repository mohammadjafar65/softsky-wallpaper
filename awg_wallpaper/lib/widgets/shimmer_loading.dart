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
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: Colors.white,
      child: isWide
          ? _buildWideGrid()
          : _buildStaggeredGrid(),
    );
  }
  
  Widget _buildStaggeredGrid() {
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
      },
    );
  }
  
  Widget _buildWideGrid() {
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
            color: AppTheme.surface,
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
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: Colors.white,
      child: Container(
        width: 160,
        height: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}
