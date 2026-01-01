import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/theme.dart';
import '../providers/pack_provider.dart';
import '../models/wallpaper_pack.dart';
import 'wallpaper_detail_screen.dart';
import '../widgets/wallpaper_card.dart';
import '../utils/ad_helper.dart';
import '../widgets/native_ad_widget.dart';
import '../providers/subscription_provider.dart';
import '../services/batch_download_service.dart';

class PackDetailScreen extends StatefulWidget {
  final String packId;
  final String packName;

  const PackDetailScreen(
      {super.key, required this.packId, required this.packName});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  WallpaperPack? _pack;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final pack =
        await context.read<PackProvider>().getPackDetails(widget.packId);
    if (mounted) {
      setState(() {
        _pack = pack;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pack == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: Text("Pack not found")),
      );
    }

    // Prepare interleaved items for the grid
    final isPro = context.read<SubscriptionProvider>().isPro;
    final List<dynamic> mixedItems = [];
    for (int i = 0; i < _pack!.wallpapers.length; i++) {
      mixedItems.add(_pack!.wallpapers[i]);
      if (!isPro && (i + 1) % 5 == 0) {
        mixedItems.add('native_ad');
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leadingWidth: 70,
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (isPro)
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.download_rounded, color: Colors.white),
                    onPressed: () => _startBatchDownload(context),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _pack!.coverImage,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      _pack!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   'About this collection',
                  //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //         fontWeight: FontWeight.bold,
                  //         color: AppTheme.primary,
                  //       ),
                  // ),
                  // const SizedBox(height: 12),
                  // Text(
                  //   _pack!.description,
                  //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //         height: 1.6,
                  //         color: AppTheme.textSecondary,
                  //       ),
                  // ),
                  // const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.wallpaper_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wallpapers',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_pack!.wallpapers.length} items',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: mixedItems.length,
              itemBuilder: (context, index) {
                final item = mixedItems[index];

                if (item == 'native_ad') {
                  return const NativeAdWidget(height: 150);
                }

                final wallpaper = item;
                final wallpaperIndex = _pack!.wallpapers.indexOf(wallpaper);

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
                              builder: (context) => WallpaperDetailScreen(
                                wallpapers: _pack!.wallpapers,
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
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _startBatchDownload(BuildContext context) {
    if (_pack == null || _pack!.wallpapers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Pack'),
        content: Text(
            'Download all ${_pack!.wallpapers.length} wallpapers from this pack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performDownload(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _performDownload(BuildContext context) {
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
                          content: Text(progress?.error ??
                              'Pack downloaded successfully!')),
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
                        '0/${_pack!.wallpapers.length}'),
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
    service.downloadWallpapers(_pack!.wallpapers);
  }
}
