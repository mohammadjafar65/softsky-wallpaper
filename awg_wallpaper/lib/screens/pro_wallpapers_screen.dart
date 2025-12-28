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
import '../widgets/native_ad_widget.dart';
import '../utils/ad_helper.dart';
import '../providers/subscription_provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ProWallpapersScreen extends StatefulWidget {
  const ProWallpapersScreen({super.key});

  @override
  State<ProWallpapersScreen> createState() => _ProWallpapersScreenState();
}

class _ProWallpapersScreenState extends State<ProWallpapersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Ensure data is loaded when screen first appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WallpaperProvider>();
      if (provider.allWallpapers.isEmpty && !provider.isLoading) {
        provider.refresh();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<WallpaperProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadMoreWallpapers();
      }
    }
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
                controller: _scrollController,
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
                  '${DateFormatter.format()} • ${Provider.of<WallpaperProvider>(context).totalProWallpapers} Pro Wallpapers',
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
    // Filter to show only PRO wallpapers (not wide)
    // Included wallpapers in packs as they are also pro wallpapers
    final proWallpapers = provider.allWallpapers
        .where((w) => w.isPro && !w.isWide)
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

    // Mix native ads into pro wallpapers list (ONLY FOR NON-PRO)
    final List<dynamic> mixedProWallpapers = [];
    final isPro = context.read<SubscriptionProvider>().isPro;

    for (int i = 0; i < proWallpapers.length; i++) {
      mixedProWallpapers.add(proWallpapers[i]);
      if (!isPro && (i + 1) % 6 == 0) {
        mixedProWallpapers.add('native_ad');
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (context, index) {
          final item = mixedProWallpapers[index];

          if (item == 'native_ad') {
            return const NativeAdWidget();
          }

          final wallpaper = item;
          final wallpaperIndex = proWallpapers.indexOf(wallpaper);

          return AspectRatio(
            aspectRatio: 0.65,
            child: WallpaperCard(
              wallpaper: wallpaper,
              onTap: () {
                AdHelper.showInterstitialAd(
                  onAdClosed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperDetailScreen(
                          wallpapers: proWallpapers,
                          initialIndex:
                              wallpaperIndex != -1 ? wallpaperIndex : 0,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        childCount: mixedProWallpapers.length,
      ),
    );
  }
}
