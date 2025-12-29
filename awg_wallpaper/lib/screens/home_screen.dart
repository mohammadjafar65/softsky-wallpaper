import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/shimmer_loading.dart';
import 'wallpaper_detail_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'pack_detail_screen.dart';
import '../providers/pack_provider.dart';
import '../widgets/pack_card.dart';
import '../models/wallpaper.dart';
import '../models/wallpaper_pack.dart';
import '../widgets/native_ad_widget.dart';
import '../utils/ad_helper.dart';
import '../providers/subscription_provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Provider automatically loads data on initialization
    // Only refresh if there's an actual error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WallpaperProvider>();

      // Only refresh if there's an error and no data
      if (provider.error != null && provider.allWallpapers.isEmpty) {
        provider.refresh();
      }

      // Load packs for Pro Collections section (from existing provider data)
      final packProvider = context.read<PackProvider>();
      if (provider.packs.isNotEmpty) {
        packProvider.setPacksFromProvider(provider.packs);
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
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        bottom: false,
        child: Consumer<WallpaperProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.refresh,
              color: AppTheme.primary,
              backgroundColor: AppTheme.darkSurface,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),

                  // Mixed Content Grid (Wallpapers + Collections)
                  if (provider.isLoading && provider.allWallpapers.isEmpty)
                    const SliverToBoxAdapter(
                      child: ShimmerLoading(),
                    )
                  else
                    _buildMixedContentGrid(context, provider),

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
                      color: AppTheme.textWhite,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              if (Provider.of<WallpaperProvider>(context).totalFreeWallpapers >
                  0)
                Text(
                  '${_getFormattedDate()} • ${Provider.of<WallpaperProvider>(context).totalFreeWallpapers} Free Wallpapers',
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
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

  // Widget _buildSectionTitle(WallpaperProvider provider) {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         const Text(
  //           'Free Wallpapers',
  //           style: TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //             color: AppTheme.textPrimary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMixedContentGrid(
      BuildContext context, WallpaperProvider provider) {
    // 1. Get all wallpapers (Free + Pro, but not wide)
    final wallpapers = provider.allWallpapers.where((w) => !w.isWide).toList();

    // 2. Get Pro Packs
    final packs = context.watch<PackProvider>().proPacks;

    // 3. Create a mixed list
    // Algorithm: Interleave packs into wallpapers every N items
    final List<dynamic> mixedItems = [];
    int packIndex = 0;

    final isPro = context.read<SubscriptionProvider>().isPro;

    for (int i = 0; i < wallpapers.length; i++) {
      mixedItems.add(wallpapers[i]);

      // Every 5 items, insert a native ad (ONLY FOR NON-PRO)
      if (!isPro && (i + 1) % 5 == 0) {
        mixedItems.add('native_ad');
      }

      // Every 7 wallpapers, insert a pack if available
      if ((i + 1) % 7 == 0 && packIndex < packs.length) {
        mixedItems.add(packs[packIndex]);
        packIndex++;
      }
    }

    // If there are remaining packs, add them to the end (or skip if we want it balanced)
    // while (packIndex < packs.length) {
    //   mixedItems.add(packs[packIndex]);
    //   packIndex++;
    // }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (ctx, index) {
          final item = mixedItems[index];

          if (item is Wallpaper) {
            return AspectRatio(
              aspectRatio: 0.65,
              child: WallpaperCard(
                wallpaper: item,
                onTap: () {
                  // Find the index in the original wallpaper list for consistent browsing
                  final wallpaperIndex = wallpapers.indexOf(item);

                  // Show Interstitial Ad before navigation
                  AdHelper.showInterstitialAd(
                    onAdClosed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WallpaperDetailScreen(
                            wallpapers: wallpapers,
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
          } else if (item is WallpaperPack) {
            return AspectRatio(
              aspectRatio: 0.65,
              child: PackCard(
                pack: item,
                isLarge: false,
                margin: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackDetailScreen(
                        packId: item.id,
                        packName: item.name,
                      ),
                    ),
                  );
                },
              ),
            );
          } else if (item == 'native_ad') {
            return AspectRatio(
              aspectRatio: 0.65,
              child: NativeAdWidget(height: double.infinity),
            );
          }
          return const SizedBox.shrink();
        },
        childCount: mixedItems.length,
      ),
    );
  }

  // Removed _buildProCollections and _buildWallpaperGrid as they are replaced by _buildMixedContentGrid
}
