import 'dart:ui';

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
      // Always try to load pro wallpapers if list is empty
      if (provider.proWallpapersList.isEmpty && !provider.isProLoading) {
        provider.loadProWallpapers(refresh: true, force: true);
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
      if (!provider.isProLoading && provider.hasMorePro) {
        provider.loadMoreProWallpapers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        bottom: false,
        child: Consumer<WallpaperProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadProWallpapers(refresh: true, force: true);
              },
              color: AppTheme.primary,
              backgroundColor: AppTheme.darkSurface,
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

                  // Wallpaper Grid
                  if (provider.isProLoading &&
                      provider.proWallpapersList.isEmpty)
                    const SliverToBoxAdapter(
                      child: ShimmerLoading(),
                    )
                  else
                    _buildWallpaperGrid(context, provider),

                  // Bottom Loading Indicator
                  if (provider.isProLoading &&
                      provider.proWallpapersList.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),

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
              Row(children: const [
                Text(
                  'EXCLUSIVE',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily:
                        'Outfit', // Assuming font family, otherwise uses theme
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: Colors.amberAccent,
                ),
              ]),
              const SizedBox(height: 4),
              // Use total count from provider if available, or just list length
              // For Pro wallpapers, we might not have a separate total count variable updated by loadProWallpapers yet
              // But provider has totalProWallpapers from initial sync (which is just limit:1).
              // Let's use the list length or "Loading..."
              Text(
                Provider.of<WallpaperProvider>(context).totalProWallpapers > 0
                    ? '${DateFormatter.format()} • ${Provider.of<WallpaperProvider>(context).totalProWallpapers} Pro Wallpapers'
                    : DateFormatter.format(),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
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
          // Use slug as the identifier — this is what the backend filters by
          final slugKey = category.slug ?? category.id;
          final isSelected = provider.selectedProCategory == slugKey;

          return CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () {
              provider.setSelectedProCategory(slugKey, reload: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildWallpaperGrid(BuildContext context, WallpaperProvider provider) {
    // Use the dedicated Pro list
    final proWallpapers = provider.proWallpapersList;

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
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pro wallpapers found',
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

    // Mix native ads (only for non-pro users)
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
            return AspectRatio(
              aspectRatio: 0.65,
              child: NativeAdWidget(height: double.infinity),
            );
          }

          final wallpaper = item;
          final wallpaperIndex = proWallpapers.indexOf(wallpaper);

          return AspectRatio(
            aspectRatio: 0.65,
            child: WallpaperCard(
              wallpaper: wallpaper,
              onTap: () {
                final isPro = context.read<SubscriptionProvider>().isPro;
                if (!isPro) {
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
                } else {
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
                }
              },
            ),
          );
        },
        childCount: mixedProWallpapers.length,
      ),
    );
  }
}
