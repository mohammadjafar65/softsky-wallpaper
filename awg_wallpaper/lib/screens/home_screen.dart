import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/shimmer_loading.dart';
import 'wallpaper_detail_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

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

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${now.day} ${months[now.month - 1]}';
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
                'TODAY',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              if (Provider.of<WallpaperProvider>(context).totalWallpapers > 0)
                Text(
                  '${_getFormattedDate()} • ${Provider.of<WallpaperProvider>(context).totalWallpapers} Wallpapers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          ),
          Row(
            children: [
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
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                    Icons.person_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildTrendingCarousel(
  //     BuildContext context, WallpaperProvider provider) {
  //   if (provider.wallpapers.isEmpty) return const SizedBox.shrink();

  //   // Take first 5 items as "Trending" for demo
  //   final trending = provider.wallpapers.take(5).toList();

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Padding(
  //         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //         child: Text(
  //           'Trending Today',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: AppTheme.textPrimary,
  //           ),
  //         ),
  //       ),
  //       TrendingSlider(wallpapers: trending),
  //     ],
  //   );
  // }

  Widget _buildSectionTitle(WallpaperProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent',
            style: TextStyle(
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
    // Use the provider's wallpapers getter which already filters for non-wide, non-pack wallpapers
    final wallpapers = provider.wallpapers;

    if (wallpapers.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.wallpaper_outlined,
                  size: 64,
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No wallpapers available',
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
          childAspectRatio: 0.65, // Consistent height for all cards
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            final wallpaper = wallpapers[index];

            return WallpaperCard(
              wallpaper: wallpaper,
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
      ),
    );
  }
}
