import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/trending_slider.dart';
import 'wallpaper_detail_screen.dart';
import 'search_screen.dart';
import 'packs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<WallpaperProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.refresh,
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              child: CustomScrollView(
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),

                  // Today Trending Carousel
                  SliverToBoxAdapter(
                    child: _buildTrendingCarousel(context, provider),
                  ),

                  // Categories
                  SliverToBoxAdapter(
                    child: _buildCategories(context, provider),
                  ),

                  // Section Title
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(provider),
                  ),

                  // Wallpaper Grid
                  if (provider.isLoading)
                    const SliverToBoxAdapter(
                      child: ShimmerLoading(),
                    )
                  else
                    _buildWallpaperGrid(provider),

                  // Bottom padding for nav bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily inspiration for you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceVariant),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCarousel(
      BuildContext context, WallpaperProvider provider) {
    if (provider.wallpapers.isEmpty) return const SizedBox.shrink();

    // Take first 5 items as "Trending" for demo
    final trending = provider.wallpapers.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Trending Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        TrendingSlider(wallpapers: trending),
      ],
    );
  }

  Widget _buildCategories(BuildContext context, WallpaperProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final isSelected = provider.selectedCategory == category.id;

          return GestureDetector(
            onTap: () => provider.setSelectedCategory(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(WallpaperProvider provider) {
    final categoryName = provider.selectedCategory == 'all'
        ? 'Recent Uploads'
        : provider.categories
            .firstWhere((c) => c.id == provider.selectedCategory)
            .name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            categoryName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          /*// Optional: minimalist count or icon
          Text(
            '${provider.wallpapers.length}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _buildWallpaperGrid(WallpaperProvider provider) {
    final wallpapers = provider.wallpapers;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (context, index) {
          final wallpaper = wallpapers[index];
          // Alternate heights
          final height =
              index % 3 == 0 ? 260.0 : (index % 3 == 1 ? 200.0 : 240.0);

          return WallpaperCard(
            wallpaper: wallpaper,
            height: height,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WallpaperDetailScreen(
                    wallpapers: wallpapers,
                    initialIndex: index,
                  ),
                ),
              );
            },
          );
        },
        childCount: wallpapers.length,
      ),
    );
  }
}
