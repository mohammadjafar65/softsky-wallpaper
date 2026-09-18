import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/wallpaper_card.dart';
import 'wallpaper_detail_screen.dart';
import '../utils/date_formatter.dart';
import '../utils/ad_helper.dart';
import '../providers/subscription_provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<BookmarkProvider, SubscriptionProvider>(
      builder: (context, provider, subscriptionProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.getBackground(isDark),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context, provider),
                ),

                // Empty state or grid
                if (provider.bookmarks.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context),
                  )
                else ...[
                  // Section title
                  // SliverToBoxAdapter(
                  //   child: _buildSectionTitle(provider),
                  // ),

                  // Bookmarks grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: Builder(
                      builder: (context) {
                        final bookmarks = provider.bookmarks;
                        return SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          itemBuilder: (context, index) {
                            final wallpaper = bookmarks[index];
                            final height = index % 3 == 0
                                ? 280.0
                                : (index % 3 == 1 ? 220.0 : 250.0);

                            return WallpaperCard(
                              wallpaper: wallpaper,
                              height: height,
                              onTap: () {
                                final isPro = context.read<SubscriptionProvider>().isPro;
                                if (!isPro) {
                                  AdHelper.showInterstitialAd(
                                    onAdClosed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WallpaperDetailScreen(
                                            wallpapers: bookmarks,
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
                                        wallpapers: bookmarks,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                          childCount: bookmarks.length,
                        );
                      },
                    ),
                  ),
                ],

                // Bottom padding for nav bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BookmarkProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAVORITES',
                style: TextStyle(
                  color: AppTheme.getTextPrimary(isDark),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormatter.format()} • ${provider.bookmarkCount} Saved',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (provider.bookmarks.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearConfirmation(context, provider),
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
                    Icons.delete_outline_rounded,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Wallpapers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the heart icon on any wallpaper to save it to your collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, BookmarkProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Clear All?',
          style: TextStyle(color: AppTheme.getTextPrimary(isDark)),
        ),
        content: Text(
          'This will remove all saved wallpapers from your collection.',
          style: TextStyle(color: AppTheme.getTextSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getTextSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllBookmarks();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
