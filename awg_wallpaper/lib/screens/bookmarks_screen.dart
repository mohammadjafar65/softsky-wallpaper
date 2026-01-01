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
import '../services/batch_download_service.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookmarkProvider, SubscriptionProvider>(
      builder: (context, provider, subscriptionProvider, child) {
        return Scaffold(
          floatingActionButton:
              (subscriptionProvider.isPro && provider.bookmarks.isNotEmpty)
                  ? FloatingActionButton.extended(
                      onPressed: () => _startBatchDownload(context, provider),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download All'),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    )
                  : null,
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
                    child: _buildEmptyState(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAVORITES',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textWhite,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormatter.format()} • ${provider.bookmarkCount} Saved',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget _buildSectionTitle(BookmarkProvider provider) {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         const Text(
  //           'Your Collection',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: AppTheme.textPrimary,
  //           ),
  //         ),
  //         Text(
  //           '${provider.bookmarkCount} saved',
  //           style: const TextStyle(
  //             fontSize: 13,
  //             color: AppTheme.textSecondary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: AppTheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Saved Wallpapers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the heart icon on any wallpaper to save it to your collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, BookmarkProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text(
          'Clear All?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will remove all saved wallpapers from your collection.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
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

  void _startBatchDownload(
      BuildContext context, BookmarkProvider bookmarkProvider) {
    // Check if dialog is potentially already open (simple debounce/check)
    // For now, we just create the service
    final service = BatchDownloadService();

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return StreamBuilder<BatchDownloadProgress>(
            stream: service.progressStream,
            builder: (context, snapshot) {
              final progress = snapshot.data;

              if (progress?.isComplete == true) {
                // Close dialog after a short delay
                Future.delayed(const Duration(seconds: 1), () {
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              progress?.error ?? 'All wallpapers downloaded!')),
                    );
                  }
                });
              }

              return AlertDialog(
                title: const Text('Downloading...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress?.progress ?? 0),
                    const SizedBox(height: 16),
                    Text(progress?.currentWallpaper != null
                        ? 'Downloading: ${progress!.currentWallpaper}'
                        : 'Preparing...'),
                    const SizedBox(height: 8),
                    Text(progress?.progressText ??
                        '0/${bookmarkProvider.bookmarks.length}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      service.cancelDownload();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      ),
    ).then((_) {
      service.dispose(); // Cleanup
    });

    // Start download
    service.downloadWallpapers(bookmarkProvider.bookmarks);
  }
}
