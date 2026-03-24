import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/wallpaper_provider.dart';
import '../widgets/wide_wallpaper_card.dart';
import 'wallpaper_detail_screen.dart';
import '../utils/date_formatter.dart';
import '../utils/ad_helper.dart';
import '../providers/subscription_provider.dart';
import 'profile_screen.dart';

class WideWallpapersScreen extends StatelessWidget {
  const WideWallpapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<WallpaperProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              color: AppTheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),

                  // Info card
                  // SliverToBoxAdapter(
                  //   child: _buildInfoCard(),
                  // ),

                  // Section title
                  // SliverToBoxAdapter(
                  //   child: _buildSectionTitle(provider),
                  // ),

                  // Wide wallpapers list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final wideWallpapers = provider.wideWallpapers;
                          final wallpaper = wideWallpapers[index];
                          return WideWallpaperCard(
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
                                          wallpapers: wideWallpapers,
                                          initialIndex: index,
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
                                      wallpapers: wideWallpapers,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                        childCount: provider.wideWallpapers.length,
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
              Text(
                'SCAPES',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textWhite,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              if (Provider.of<WallpaperProvider>(context)
                  .wideWallpapers
                  .isNotEmpty)
                Text(
                  '${DateFormatter.format()} • ${Provider.of<WallpaperProvider>(context).wideWallpapers.length} WideWallpapers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
    );
  }

  // Widget _buildInfoCard() {
  //   return Container(
  //     margin: const EdgeInsets.all(20),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           AppTheme.accent.withValues(alpha: 0.15),
  //           AppTheme.primary.withValues(alpha: 0.15),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(AppRadius.lg),
  //       border: Border.all(
  //         color: AppTheme.accent.withValues(alpha: 0.3),
  //         width: 1,
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: AppTheme.accent.withValues(alpha: 0.2),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: const Icon(
  //             Icons.desktop_windows_rounded,
  //             color: AppTheme.accent,
  //             size: 24,
  //           ),
  //         ),
  //         const SizedBox(width: 16),
  //         const Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Landscape Format',
  //                 style: TextStyle(
  //                   color: AppTheme.textPrimary,
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               SizedBox(height: 4),
  //               Text(
  //                 'Perfect for your desktop, laptop, or tablet screens',
  //                 style: TextStyle(
  //                   color: AppTheme.textSecondary,
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSectionTitle(WallpaperProvider provider) {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         const Text(
  //           'All Wide Wallpapers',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: AppTheme.textPrimary,
  //           ),
  //         ),
  //         Text(
  //           '${provider.wideWallpapers.length} wallpapers',
  //           style: const TextStyle(
  //             fontSize: 13,
  //             color: AppTheme.textSecondary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

