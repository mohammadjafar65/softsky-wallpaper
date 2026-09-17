import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/pack_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/pack_card.dart';
import 'pack_detail_screen.dart';
import '../utils/date_formatter.dart';
import '../widgets/top_bar_profile_avatar.dart';
import '../widgets/native_ad_widget.dart';
import '../providers/subscription_provider.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  // int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallpaperProvider = context.read<WallpaperProvider>();
      final packProvider = context.read<PackProvider>();

      // If WallpaperProvider already has packs (cached or loaded), give them to PackProvider
      if (wallpaperProvider.packs.isNotEmpty) {
        packProvider.setPacksFromProvider(wallpaperProvider.packs);
      } else {
        // Otherwise fetch normally
        packProvider.fetchPacks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<PackProvider>(
          builder: (context, provider, child) {
            // Use pro packs as featured for now, or mix
            // final featuredPacks = provider.proPacks.take(5).toList();

            return RefreshIndicator(
              onRefresh: () => provider.fetchPacks(refresh: true),
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              child: CustomScrollView(
                slivers: [
                  // Custom Header Matching Home Screen
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BUNDLES',
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormatter.format()} • ${provider.packs.length} Packs',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          const TopBarProfileAvatar(),
                        ],
                      ),
                    ),
                  ),

                  if (provider.isLoading && provider.packs.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if (provider.error != null && provider.packs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load packs',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.error ?? 'Unknown error',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () =>
                                    provider.fetchPacks(refresh: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _buildAllPacksList(context, provider.packs),

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

  // Removed _buildSectionHeader and _buildHorizontalList helper methods as they are no longer used

  Widget _buildAllPacksList(BuildContext context, List packs) {
    // Mix native ads into packs list (ONLY FOR NON-PRO)
    final List<dynamic> mixedPacks = [];
    final isPro = context.read<SubscriptionProvider>().isPro;

    for (int i = 0; i < packs.length; i++) {
      mixedPacks.add(packs[i]);
      if (!isPro && (i + 1) % 3 == 0) {
        mixedPacks.add('native_ad');
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = mixedPacks[index];

            if (item == 'native_ad') {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: NativeAdWidget(height: 150),
              );
            }

            final pack = item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: PackCard(
                pack: pack,
                isLarge: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackDetailScreen(
                          packId: pack.id, packName: pack.name),
                    ),
                  );
                },
              ),
            );
          },
          childCount: mixedPacks.length,
        ),
      ),
    );
  }
}
