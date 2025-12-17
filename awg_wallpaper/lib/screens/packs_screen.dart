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

                // Removed Free Packs Section per user request

                // All Packs List (Full Width)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

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
    );
  }

  // Removed _buildSectionHeader and _buildHorizontalList helper methods as they are no longer used

  Widget _buildAllPacksList(BuildContext context, List packs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final pack = packs[index];
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
          childCount: packs.length,
        ),
      ),
    );
  }
}
