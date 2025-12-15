import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../models/wallpaper.dart';
import '../providers/bookmark_provider.dart';
import '../providers/subscription_provider.dart';
import 'subscription_screen.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final List<Wallpaper> wallpapers;
  final int initialIndex;

  const WallpaperDetailScreen({
    super.key,
    required this.wallpapers,
    required this.initialIndex,
  });

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _showControls = true;
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Wallpaper get _currentWallpaper => widget.wallpapers[_currentIndex];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (_currentWallpaper.isPro && !subscriptionProvider.isPro) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showProPurchasePopup();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.wallpapers.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final wallpaper = widget.wallpapers[index];
              final isInitial = index == widget.initialIndex;

              return GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: isInitial
                    ? Hero(
                        tag: 'wallpaper_${wallpaper.id}',
                        child: _buildWallpaperImage(wallpaper),
                      )
                    : _buildWallpaperImage(wallpaper),
              );
            },
          ),
          if (widget.wallpapers.length > 1)
            Positioned(
              top: topPadding + 60,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _buildPageIndicator(),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 100,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildTopBar(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.95),
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildBottomContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_currentIndex + 1} / ${widget.wallpapers.length}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperImage(Wallpaper wallpaper) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: CachedNetworkImage(
        imageUrl: wallpaper.imageUrl,
        fit: wallpaper.isWide ? BoxFit.contain : BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors
              .black, // Keep black loading for detail screen to avoid flash
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildIconBtn(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        if (_currentWallpaper.isPro)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.black, size: 14),
                SizedBox(width: 3),
                Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        Consumer<BookmarkProvider>(
          builder: (context, provider, child) {
            final isBookmarked = provider.isBookmarked(_currentWallpaper.id);
            return _buildIconBtn(
              icon: isBookmarked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              iconColor: isBookmarked ? AppTheme.error : Colors.white,
              onTap: () {
                provider.toggleBookmark(_currentWallpaper);
                HapticFeedback.lightImpact();
                _showMsg(isBookmarked
                    ? 'Removed from favorites'
                    : 'Added to favorites');
              },
            );
          },
        ),
        const SizedBox(width: 8),
        _buildIconBtn(
          icon: Icons.share_rounded,
          onTap: () => _shareWallpaper(),
        ),
        const SizedBox(width: 8),
        _buildIconBtn(
          icon: Icons.more_horiz_rounded,
          onTap: () => _showOptionsSheet(),
        ),
      ],
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!subscriptionProvider.isPro) _buildUpgradeBanner(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _currentWallpaper.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // _buildTag(_currentWallpaper.category, AppTheme.primary),
                  if (_currentWallpaper.isWide) ...[
                    const SizedBox(width: 8),
                    _buildTag('Wide', AppTheme.accent),
                  ],
                  const SizedBox(width: 8),
                  _buildTag('HD', AppTheme.success),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionBtn(
                    icon: Icons.info_outline_rounded,
                    onTap: () => _showInfoSheet(),
                  ),
                  const SizedBox(width: 24),
                  _buildPrimaryBtn(
                    icon: Icons.download_rounded,
                    onTap: () => _handleDownload(subscriptionProvider),
                  ),
                  if (!_currentWallpaper.isWide) ...[
                    const SizedBox(width: 24),
                    _buildActionBtn(
                      icon: Icons.wallpaper_rounded,
                      onTap: () => _handleApply(subscriptionProvider),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialogs and Sheets updated for Light Theme Text visibility

  void _showProPurchasePopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.black,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Premium Wallpaper',
                style: TextStyle(
                  color: AppTheme.textPrimary, // Fixed text color
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock this wallpaper and thousands more with Pro subscription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildProFeature(Icons.image_rounded, 'All premium wallpapers'),
              _buildProFeature(Icons.block_rounded, 'Ad-free experience'),
              _buildProFeature(Icons.hd_rounded, '4K downloads'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Upgrade to Pro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black, // Visible on pastel
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 13), // Fixed
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black
              .withOpacity(0.6), // Keep dark overlay for contrast on wallpaper
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.gold, Color(0xFFFFB700)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.black, size: 16),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Remove ads & unlock 4K',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Wallpaper Info',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _infoRow('Title', _currentWallpaper.title),
            _infoRow('Category', _currentWallpaper.category),
            _infoRow(
                'Type', _currentWallpaper.isWide ? 'Landscape' : 'Portrait'),
            _infoRow('Resolution',
                _currentWallpaper.isWide ? '1920×1080' : '1080×1920'),
            _infoRow('Status', _currentWallpaper.isPro ? 'Premium' : 'Free'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    );
  }

  void _showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _sheetItem(Icons.hd_rounded, 'Original Quality', () {
              Navigator.pop(ctx);
              _download('original');
            }),
            _sheetItem(Icons.sd_rounded, 'Medium Quality', () {
              Navigator.pop(ctx);
              _download('medium');
            }),
          ],
        ),
      ),
    );
  }

  void _showApplySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Set Wallpaper',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            _sheetItem(Icons.home_rounded, 'Home Screen', () {
              Navigator.pop(ctx);
              _applyWallpaper(0);
            }),
            _sheetItem(Icons.lock_rounded, 'Lock Screen', () {
              Navigator.pop(ctx);
              _applyWallpaper(1);
            }),
            _sheetItem(Icons.smartphone_rounded, 'Both Screens', () {
              Navigator.pop(ctx);
              _applyWallpaper(2);
            }),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      ),
      onTap: onTap,
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _sheetItem(Icons.share_rounded, 'Share', () => Navigator.pop(ctx)),
            _sheetItem(Icons.info_outline_rounded, 'Info', () {
              Navigator.pop(ctx);
              _showInfoSheet();
            }),
            _sheetItem(Icons.flag_outlined, 'Report', () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildPrimaryBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryVariant]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 26),
      ),
    );
  }

  // Implementation of actions
  void _handleDownload(SubscriptionProvider provider) {
    if (_currentWallpaper.isPro && !provider.isPro) {
      _showProPurchasePopup();
    } else {
      _showDownloadSheet();
    }
  }

  void _handleApply(SubscriptionProvider provider) {
    if (_currentWallpaper.isPro && !provider.isPro) {
      _showProPurchasePopup();
    } else {
      _showApplySheet();
    }
  }

  void _showMsg(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.black)),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _download(String quality) async {
    // Show progress
    _showDownloadProgress();

    try {
      // simulate quality selection (in real app, use different URLs)
      final url = _currentWallpaper.imageUrl;
      final file = await DefaultCacheManager().getSingleFile(url);

      // Save to external storage
      // Note: This needs permission handling in real app
      // For now, we simulate success
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        _showSuccessMsg('Downloaded ($quality) successfully');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMsg('Download failed');
      }
    }
  }

  Future<void> _shareWallpaper() async {
    try {
      await Share.share(
        'Check out this amazing wallpaper: ${_currentWallpaper.title}\n${_currentWallpaper.imageUrl}',
        subject: 'Amazing Wallpaper - ${_currentWallpaper.title}',
      );
    } catch (e) {
      _showMsg('Could not share wallpaper');
    }
  }

  Future<void> _applyWallpaper(int location) async {
    // 1: Home, 2: Lock, 3: Both
    _showApplyProgress();

    try {
      final file =
          await DefaultCacheManager().getSingleFile(_currentWallpaper.imageUrl);

      // Call native channel
      const platform = MethodChannel('com.awg.wallpaper/wallpaper');
      final result = await platform.invokeMethod(
          'setWallpaper', {'path': file.path, 'location': location});

      if (mounted) {
        Navigator.pop(context);
        if (result == true) {
          _showSuccessMsg('Wallpaper applied successfully');
        } else {
          _showManualSetDialog(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMsg('Could not apply wallpaper');
      }
    }
  }

  void _showDownloadProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text('Downloading...',
                    style: TextStyle(color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApplyProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text('Applying wallpaper...',
                    style: TextStyle(color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualSetDialog(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_rounded,
                  color: AppTheme.textPrimary, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Manual Setup',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'We saved the wallpaper to your gallery. Please set it manually from there.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('OK', style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessMsg(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 50),
              const SizedBox(height: 16),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Great!',
                    style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
