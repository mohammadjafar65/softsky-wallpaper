import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/shimmer_loading.dart';
import 'wallpaper_detail_screen.dart';
import 'search_screen.dart';
import '../utils/date_formatter.dart';
import 'profile_screen.dart';

class ProWallpapersScreen extends StatefulWidget {
  const ProWallpapersScreen({super.key});

  @override
  State<ProWallpapersScreen> createState() => _ProWallpapersScreenState();
}

class _ProWallpapersScreenState extends State<ProWallpapersScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded when screen first appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WallpaperProvider>();
      if (provider.allWallpapers.isEmpty && !provider.isLoading) {
        provider.refresh();
      }
    });
  }

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
                  // SliverToBoxAdapter(
                  //   child: _buildSectionTitle(provider),
                  // ),

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  'EXCLUSIVE',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                      ),
                ),
                const Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: Colors.amberAccent,
                ),
              ]),
              const SizedBox(height: 4),
              if (Provider.of<WallpaperProvider>(context).totalProWallpapers >
                  0)
                Text(
                  '${DateFormatter.format()} • ${Provider.of<WallpaperProvider>(context).totalProWallpapers} Wallpapers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          ),
          // const SizedBox(width: 43),
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
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceVariant),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textPrimary,
                    size: 22,
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
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceVariant),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context, WallpaperProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 0, 0, 25),
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

  // Widget _buildSectionTitle(WallpaperProvider provider) {
  //   final categoryName = provider.selectedCategory == 'all'
  //       ? 'All Pro Wallpapers'
  //       : provider.categories
  //           .firstWhere((c) => c.id == provider.selectedCategory)
  //           .name;

  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           categoryName,
  //           style: const TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //             color: AppTheme.textPrimary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
