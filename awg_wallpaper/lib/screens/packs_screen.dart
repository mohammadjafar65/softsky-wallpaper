import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../config/theme.dart';
import '../providers/pack_provider.dart';
import '../widgets/pack_card.dart';
import 'pack_detail_screen.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackProvider>().fetchPacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PackProvider>(
        builder: (context, provider, child) {
          // Use pro packs as featured for now, or mix
          final featuredPacks = provider.proPacks.take(5).toList();

          return RefreshIndicator(
            onRefresh: () => provider.fetchPacks(refresh: true),
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            child: CustomScrollView(
              slivers: [
                // Custom Header Matching Home Screen
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 75, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Collections',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontSize: 28,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Curated sets for you',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured Carousel
                // if (featuredPacks.isNotEmpty) ...[
                //   SliverToBoxAdapter(
                //     child: Padding(
                //       padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                //       child: Text(
                //         'Featured',
                //         style: Theme.of(context).textTheme.titleLarge?.copyWith(
                //               fontWeight: FontWeight.bold,
                //             ),
                //       ),
                //     ),
                //   ),
                //   SliverToBoxAdapter(
                //     child: Column(
                //       children: [
                //         CarouselSlider.builder(
                //           itemCount: featuredPacks.length,
                //           itemBuilder: (context, index, realIndex) {
                //             final pack = featuredPacks[index];
                //             return PackCard(
                //               pack: pack,
                //               isLarge: true,
                //               onTap: () {
                //                 Navigator.push(
                //                   context,
                //                   MaterialPageRoute(
                //                     builder: (_) => PackDetailScreen(
                //                         packId: pack.id, packName: pack.name),
                //                   ),
                //                 );
                //               },
                //             );
                //           },
                //           options: CarouselOptions(
                //             height: 220,
                //             viewportFraction: 0.85,
                //             enlargeCenterPage: true,
                //             enlargeFactor: 0.2,
                //             autoPlay: true,
                //             autoPlayInterval: const Duration(seconds: 5),
                //             onPageChanged: (index, reason) {
                //               setState(() {
                //                 _currentCarouselIndex = index;
                //               });
                //             },
                //           ),
                //         ),
                //         const SizedBox(height: 16),
                //         AnimatedSmoothIndicator(
                //           activeIndex: _currentCarouselIndex,
                //           count: featuredPacks.length,
                //           effect: ExpandingDotsEffect(
                //             activeDotColor: AppTheme.primary,
                //             dotColor: AppTheme.primary.withOpacity(0.2),
                //             dotHeight: 6,
                //             dotWidth: 6,
                //             expansionFactor: 3,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ],

                // Free Packs Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    'Free Collections',
                    Icons.folder_special_rounded,
                    AppTheme.success,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildHorizontalList(context, provider.freePacks),
                ),

                // All Packs Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'All Collections',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildAllPacksGrid(context, provider.packs),

                // Bottom padding for nav bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List packs) {
    return SizedBox(
      height: 200, // Reduced height slightly as card is optimized
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final pack = packs[index];
          return Container(
            margin: const EdgeInsets.only(
                right: 16), // Margin handled here or in card
            // We need to ensure PackCard doesn't double margin if isLarge is false
            // The current PackCard implementation adds right margin 16 if !isLarge.
            // So we don't need extra margin here if we rely on that.
            // Let's rely on PackCard's internal margin for now to keep it consistent.
            child: PackCard(
              pack: pack,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PackDetailScreen(packId: pack.id, packName: pack.name),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllPacksGrid(BuildContext context, List packs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75, // Taller aspect ratio for better look
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final pack = packs[index];
            return PackCard(
              pack: pack,
              isLarge: true, // Use large styling, but grid constrains width
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PackDetailScreen(packId: pack.id, packName: pack.name),
                  ),
                );
              },
            );
          },
          childCount: packs.length,
        ),
      ),
    );
  }
}
