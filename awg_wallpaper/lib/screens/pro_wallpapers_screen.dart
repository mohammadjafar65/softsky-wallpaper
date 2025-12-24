import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/shimmer_loading.dart';
import 'wallpaper_detail_screen.dart';
import 'search_screen.dart';

class ProWallpapersScreen extends StatelessWidget {
  const ProWallpapersScreen({super.key});

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
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
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
                    _buildWallpaperGrid(context, provider),

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
          Row(
            children: [
              Text(
                'PRO',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '👑',
                  style: TextStyle(fontSize: 16),
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

  Widget _buildCategories(BuildContext context, WallpaperProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final isSelected = provider.selectedCategory == category.id;

          return CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => provider.setSelectedCategory(category.id),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(WallpaperProvider provider) {
    final categoryName = provider.selectedCategory == 'all'
        ? 'All Pro Wallpapers'
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
        ],
      ),
    );
  }

  Widget _buildWallpaperGrid(BuildContext context, WallpaperProvider provider) {
    // Filter to show only PRO wallpapers (not wide, not in a pack)
    final proWallpapers = provider.allWallpapers
        .where((w) =>
            w.isPro && !w.isWide && (w.packId == null || w.packId!.isEmpty))
        .where((w) =>
            provider.selectedCategory == 'all' ||
            w.category == provider.selectedCategory)
        .toList();

    if (proWallpapers.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 64,
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pro wallpapers in this category',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final wallpaper = proWallpapers[index];

            return WallpaperCard(
              wallpaper: wallpaper,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WallpaperDetailScreen(
                      wallpapers: proWallpapers,
                      initialIndex: index,
                    ),
                  ),
                );
              },
            );
          },
          childCount: proWallpapers.length,
        ),
      ),
    );
  }
}
