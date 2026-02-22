import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:ui';
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
  bool _showPreview = false;

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Wallpaper PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.wallpapers.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final wallpaper = widget.wallpapers[index];
              final isInitial = index == widget.initialIndex;

              return GestureDetector(
                onTap: () {
                  if (_showPreview) {
                    setState(() => _showPreview = false);
                  } else {
                    setState(() => _showControls = !_showControls);
                  }
                },
                child: isInitial
                    ? Hero(
                        tag: 'wallpaper_${wallpaper.id}',
                        child: _buildWallpaperImage(wallpaper),
                      )
                    : _buildWallpaperImage(wallpaper),
              );
            },
          ),

          // Mock Home Screen Overlay (Preview Mode)
          if (_showPreview) _buildPreviewOverlay(),

          // Top Gradient (Subtle Shadow for readability)
          if (!_showPreview)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPadding + 100,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: AppDurations.fast,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Page Indicator
          if (widget.wallpapers.length > 1)
            Positioned(
              top: topPadding + 64,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls && !_showPreview ? 1.0 : 0.0,
                duration: AppDurations.fast,
                child: _buildPageIndicator(),
              ),
            ),

          // Top Bar
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _showControls && !_showPreview ? 1.0 : 0.0,
              duration: AppDurations.fast,
              child: IgnorePointer(
                ignoring: !_showControls || _showPreview,
                child: _buildTopBar(),
              ),
            ),
          ),

          // Bottom Content (Floating Glass Island)
          Positioned(
            bottom: bottomPadding + 20,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showControls && !_showPreview ? 1.0 : 0.0,
              duration: AppDurations.fast,
              child: IgnorePointer(
                ignoring: !_showControls || _showPreview,
                child: _buildBottomContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top Shadow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Clock & Date
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '09:41',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  'Thursday, December 25',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // App Icons Row
          Positioned(
            bottom: 160,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => _buildMockIcon()),
            ),
          ),
          // Dock
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (index) => _buildMockIcon()),
                  ),
                ),
              ),
            ),
          ),
          // Home Indicator Mock
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 140,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
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
        if (_currentWallpaper.isPro) _buildProBadge(),
        const SizedBox(width: 8),
        _buildIconBtn(
          icon: _showPreview
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          onTap: () {
            setState(() {
              _showPreview = !_showPreview;
              if (_showPreview) _showControls = true;
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(width: 8),
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
        // _buildIconBtn(
        //   icon: Icons.share_rounded,
        //   onTap: () => _shareWallpaper(),
        // ),
        // const SizedBox(width: 8),
        _buildIconBtn(
          icon: Icons.more_horiz_rounded,
          onTap: () => _showOptionsSheet(),
        ),
      ],
    );
  }

  Widget _buildProBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.8),
                const Color(0xFFFFA500).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.black, size: 14),
              SizedBox(width: 4),
              Text(
                'PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!subscriptionProvider.isPro) _buildUpgradeBanner(),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      // Text(
                      //   _currentWallpaper.title,
                      //   style: GoogleFonts.outfit(
                      //     color: Colors.white,
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.bold,
                      //     letterSpacing: -0.5,
                      //   ),
                      //   textAlign: TextAlign.center,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      // const SizedBox(height: 8),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     _buildTag('HD', AppTheme.success),
                      //     if (_currentWallpaper.isWide) ...[
                      //       const SizedBox(width: 8),
                      //       _buildTag('Wide', AppTheme.accent),
                      //     ],
                      //     const SizedBox(width: 8),
                      //     _buildTag(_currentWallpaper.category, Colors.white70),
                      //   ],
                      // ),
                      // const SizedBox(height: 10),
                      Row(
                        children: [
                          // _buildActionBtn(
                          //   icon: Icons.info_outline_rounded,
                          //   onTap: () => _showInfoSheet(),
                          // ),
                          // const SizedBox(width: 16),
                          _buildActionBtn(
                            icon: Icons.share_rounded,
                            onTap: () => _shareWallpaper(),
                          ),
                          // const SizedBox(width: 8),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPrimaryBtn(
                              label: 'Download',
                              icon: Icons.download_rounded,
                              onTap: () =>
                                  _handleDownload(subscriptionProvider),
                            ),
                          ),
                          if (!_currentWallpaper.isWide) ...[
                            const SizedBox(width: 16),
                            _buildActionBtn(
                              icon: Icons.wallpaper_rounded,
                              onTap: () => _handleApply(subscriptionProvider),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialogs and Sheets updated for Light Theme Text visibility

  void _showProPurchasePopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
              Text(
                'Premium Wallpaper',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.color, // Fixed text color
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock this wallpaper and thousands more with Pro subscription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildProFeature(Icons.image_rounded, 'All premium wallpapers'),
              _buildProFeature(Icons.block_rounded, 'Ad-free experience'),
              // _buildProFeature(Icons.hd_rounded, '4K downloads'),
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
                        color: AppTheme.primary.withValues(alpha: 0.3),
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
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13), // Fixed
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.gold, Color(0xFFFFB700)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Premium',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Remove ads & unlock 4K',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1),
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
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 70),
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
            Text('Wallpaper Info',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
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
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    );
  }

  void _showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Set Wallpaper',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose where to apply this wallpaper',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildApplyOption(
                      icon: Icons.home_rounded,
                      label: 'Home\nScreen',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyWallpaper(0);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildApplyOption(
                      icon: Icons.lock_rounded,
                      label: 'Lock\nScreen',
                      color: const Color(0xFFFF6584),
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyWallpaper(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildApplyOption(
                      icon: Icons.smartphone_rounded,
                      label: 'Both\nScreens',
                      color: const Color(0xFF00BFA5),
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyWallpaper(2);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
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
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      onTap: onTap,
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
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

  /*
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  */

  Widget _buildActionBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Colors.white],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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

      const platform = MethodChannel('com.awg.wallpaper/wallpaper');
      final result =
          await platform.invokeMethod('saveToGallery', {'path': file.path});

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        if (result == true) {
          _showSuccessMsg('Downloaded to Gallery successfully');
        } else {
          _showMsg('Download failed');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMsg('Download failed: ${e.toString()}');
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Downloading...',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saving to your gallery',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Applying Wallpaper...',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Making your screen awesome',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showManualSetDialog(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_display_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Manual Setup Required',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We saved the wallpaper to your gallery. Please set it manually from your device settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Got it',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.black,
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
        ),
      ),
    );
  }

  void _showSuccessMsg(String msg) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Success Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.success,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Success!',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPrimaryBtn(
                    label: 'Done',
                    icon: Icons.done_rounded,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
