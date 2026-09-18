import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/shimmer_loading.dart';
import 'wallpaper_detail_screen.dart';
import 'search_screen.dart';
import 'subscription_screen.dart';
import '../utils/date_formatter.dart';
import '../widgets/top_bar_profile_avatar.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: SafeArea(
        bottom: false,
        child: Consumer<WallpaperProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadProWallpapers(refresh: true, force: true);
              },
              color: AppTheme.primary,
              backgroundColor: AppTheme.getSurface(isDark),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),

                  // Upgrade Banner (free users only)
                  SliverToBoxAdapter(
                    child: _buildUpgradeBanner(context),
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

  Widget _buildUpgradeBanner(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryVariant],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Pro Wallpapers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Get unlimited access to 1000+ exclusive wallpapers',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Upgrade →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  'PRO',
                  style: TextStyle(
                    color: AppTheme.getTextPrimary(isDark),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.star_rounded,
                  size: 28,
                  color: Colors.amberAccent,
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                Provider.of<WallpaperProvider>(context).totalProWallpapers > 0
                    ? '${DateFormatter.format()} • ${Provider.of<WallpaperProvider>(context).totalProWallpapers} Pro Wallpapers'
                    : DateFormatter.format(),
                style: const TextStyle(
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const TopBarProfileAvatar(),
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
