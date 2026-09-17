import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../models/community_comment.dart';
import '../../providers/community_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_modal_sheet.dart';
import 'community_profile_screen.dart';
import 'report_bottom_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final List<CommunityPost> posts;
  final int initialIndex;

  PostDetailScreen({
    super.key,
    List<CommunityPost>? posts,
    int? initialIndex,
    CommunityPost? post,
  })  : posts = posts ?? (post != null ? [post] : []),
        initialIndex = initialIndex ?? 0;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _showControls = true;
  late PageController _pageController;
  late int _currentIndex;
  bool _showPreview = false;
  final Map<int, bool> _followingOverrides = {};

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

  CommunityPost get _currentPost => widget.posts[_currentIndex];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _toggleLike() async {
    if (!AuthService().isLoggedIn) {
      _showMsg('Please sign in to like wallpapers');
      return;
    }
    HapticFeedback.lightImpact();
    final post = _currentPost;
    final target = !post.isLiked;
    final bookmarkProvider = context.read<BookmarkProvider>();

    setState(() {
      post.isLiked = target;
      post.likesCount += target ? 1 : -1;
      if (post.likesCount < 0) post.likesCount = 0;
    });

    if (target) {
      bookmarkProvider.addBookmark(post.toWallpaper());
    } else {
      bookmarkProvider.removeBookmark('community_${post.id}');
    }

    try {
      final actual = await context.read<CommunityProvider>().toggleLike(post.id, targetState: target);
      if (mounted && post.isLiked != actual) {
        setState(() {
          post.isLiked = actual;
        });
        if (actual) {
          bookmarkProvider.addBookmark(post.toWallpaper());
        } else {
          bookmarkProvider.removeBookmark('community_${post.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          post.isLiked = !target;
          post.likesCount += (!target) ? 1 : -1;
          if (post.likesCount < 0) post.likesCount = 0;
        });
        if (!target) {
          bookmarkProvider.addBookmark(post.toWallpaper());
        } else {
          bookmarkProvider.removeBookmark('community_${post.id}');
        }
        _showMsg('Failed to update like');
      }
    }
  }

  void _toggleSave() async {
    if (!AuthService().isLoggedIn) {
      _showMsg('Please sign in to save wallpapers');
      return;
    }
    HapticFeedback.lightImpact();
    final post = _currentPost;
    final target = !post.isSaved;
    final bookmarkProvider = context.read<BookmarkProvider>();

    setState(() {
      post.isSaved = target;
      post.savesCount += target ? 1 : -1;
      if (post.savesCount < 0) post.savesCount = 0;
    });

    if (target) {
      bookmarkProvider.addBookmark(post.toWallpaper());
    } else {
      bookmarkProvider.removeBookmark('community_${post.id}');
    }

    try {
      final actual = await context.read<CommunityProvider>().toggleSave(post.id, targetState: target);
      if (mounted && post.isSaved != actual) {
        setState(() {
          post.isSaved = actual;
        });
        if (actual) {
          bookmarkProvider.addBookmark(post.toWallpaper());
        } else {
          bookmarkProvider.removeBookmark('community_${post.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          post.isSaved = !target;
          post.savesCount += (!target) ? 1 : -1;
          if (post.savesCount < 0) post.savesCount = 0;
        });
        if (!target) {
          bookmarkProvider.addBookmark(post.toWallpaper());
        } else {
          bookmarkProvider.removeBookmark('community_${post.id}');
        }
        _showMsg('Failed to update bookmark');
      }
    }
  }

  Future<void> _shareWallpaper() async {
    try {
      await Share.share(
        'Check out this wallpaper by @${_currentPost.author?.username ?? "creator"}: ${_currentPost.imageUrl}',
        subject: _currentPost.title ?? 'Collective Wallpaper',
      );
    } catch (_) {
      _showMsg('Could not share wallpaper');
    }
  }

  Future<void> _download(String quality) async {
    _showDownloadProgress();
    try {
      final file = await DefaultCacheManager().getSingleFile(_currentPost.imageUrl);
      const platform = MethodChannel('com.awg.wallpaper/wallpaper');
      final result = await platform.invokeMethod('saveToGallery', {'path': file.path});

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        if (result == true) {
          final newDownloads = await context
              .read<CommunityProvider>()
              .trackDownload(_currentPost.id);
          if (mounted) {
            setState(() {
              if (newDownloads != null) {
                _currentPost.downloadsCount = newDownloads;
              } else {
                _currentPost.downloadsCount += 1;
              }
            });
          }
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

  Future<void> _applyWallpaper(int location) async {
    _showApplyProgress();
    try {
      final file = await DefaultCacheManager().getSingleFile(_currentPost.imageUrl);
      const platform = MethodChannel('com.awg.wallpaper/wallpaper');
      final result = await platform.invokeMethod('setWallpaper', {'path': file.path, 'location': location});

      if (mounted) {
        Navigator.pop(context);
        if (result == true) {
          _showSuccessMsg('Wallpaper applied successfully');
        } else {
          _showMsg('Could not apply wallpaper');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMsg('Could not apply wallpaper');
      }
    }
  }

  void _showMsg(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13, color: Colors.black)),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessMsg(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontSize: 13, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (widget.posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: Text('No wallpaper found', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Wallpaper PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.posts.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              return GestureDetector(
                onTap: () {
                  if (_showPreview) {
                    setState(() => _showPreview = false);
                  } else {
                    setState(() => _showControls = !_showControls);
                  }
                },
                child: _buildWallpaperImage(post),
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
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Page Indicator
          if (widget.posts.length > 1)
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

          // Bottom Floating Island
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

  // ─── Image ───────────────────────────────────────────────────────────────

  Widget _buildWallpaperImage(CommunityPost post) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: CachedNetworkImage(
        imageUrl: post.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildIconBtn(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        // Preview Mock Mode Toggle
        _buildIconBtn(
          icon: _showPreview ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          onTap: () {
            setState(() {
              _showPreview = !_showPreview;
              if (_showPreview) _showControls = true;
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(width: 8),
        // Like Button
        Consumer<BookmarkProvider>(
          builder: (context, bookmarkProvider, _) {
            final isLiked = _currentPost.isLiked ||
                bookmarkProvider.isBookmarked('community_${_currentPost.id}');
            return _buildIconBtn(
              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              iconColor: isLiked ? AppTheme.error : Colors.white,
              onTap: _toggleLike,
            );
          },
        ),
        const SizedBox(width: 8),
        // Options Sheet
        _buildIconBtn(
          icon: Icons.more_horiz_rounded,
          onTap: _showOptionsSheet,
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

  Widget _buildPageIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_currentIndex + 1} / ${widget.posts.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ─── Floating Bottom Island ──────────────────────────────────────────────

  Widget _buildBottomContent() {
    final post = _currentPost;
    final author = post.author;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Creator Header Row
              if (author != null) ...[
                Row(
                  children: [
                    // Profile info (Avatar + Display Name + Handle) - Navigates to profile
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommunityProfileScreen(userId: author.id),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white12,
                              backgroundImage: author.photoUrl != null
                                  ? CachedNetworkImageProvider(author.photoUrl!)
                                  : null,
                              child: author.photoUrl == null
                                  ? const Icon(Icons.person_rounded,
                                      color: Colors.white70, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    author.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@${(author.username?.isNotEmpty == true) ? author.username! : author.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '')}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Dedicated Follow Button
                    _buildFollowButton(author),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Actions Row
              Row(
                children: [
                  // Comments button with count badge
                  GestureDetector(
                    onTap: _showCommentsSheet,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                              if (post.commentsCount > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '${post.commentsCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Share button
                  _buildActionBtn(
                    icon: Icons.share_rounded,
                    onTap: _shareWallpaper,
                  ),
                  const SizedBox(width: 10),

                  // Primary Download Button
                  Expanded(
                    child: _buildPrimaryBtn(
                      label: 'Download',
                      icon: Icons.download_rounded,
                      onTap: _showDownloadSheet,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Set Wallpaper Button
                  _buildActionBtn(
                    icon: Icons.wallpaper_rounded,
                    onTap: _showApplySheet,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Preview Mode Mock Screen ─────────────────────────────────────────────

  Widget _buildPreviewOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
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
                    Colors.black.withValues(alpha: 0.45),
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
                  'Wednesday, September 16',
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (index) => _buildMockIcon()),
                  ),
                ),
              ),
            ),
          ),
          // Home Indicator
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

  // ─── Sheets ──────────────────────────────────────────────────────────────

  void _showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.download_rounded, size: 38, color: Colors.white),
              const SizedBox(height: 14),
              const Text('Download Wallpaper',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Save full-resolution image to gallery',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 24),
              _sheetItem(Icons.hd_rounded, 'Original Resolution (${_currentPost.width ?? 1080}×${_currentPost.height ?? 1920})', () {
                Navigator.pop(ctx);
                _download('original');
              }),
              const SizedBox(height: 10),
            ],
          ),
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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.wallpaper_rounded, size: 38, color: Colors.white),
              const SizedBox(height: 14),
              const Text('Set Wallpaper',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Choose where to apply this collective wallpaper',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 28),
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
                  const SizedBox(width: 10),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 18),
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
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showOptionsSheet() {
    final post = _currentPost;
    final currentUserId = AuthService().backendUserId;
    final isOwner = currentUserId != null && post.author?.id == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              if (post.author != null)
                _sheetItem(Icons.person_rounded, 'View Creator Profile (@${post.author!.username})', () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityProfileScreen(userId: post.author!.id),
                    ),
                  );
                }),
              _sheetItem(Icons.info_outline_rounded, 'Wallpaper Details', () {
                Navigator.pop(ctx);
                _showInfoSheet();
              }),
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProvider, _) {
                  final isSaved = _currentPost.isSaved ||
                      bookmarkProvider.isBookmarked('community_${_currentPost.id}');
                  return _sheetItem(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    isSaved ? 'Remove from Saved' : 'Save to Favorites',
                    () {
                      Navigator.pop(ctx);
                      _toggleSave();
                    },
                  );
                },
              ),
              _sheetItem(Icons.flag_outlined, 'Report Inappropriate', () {
                Navigator.pop(ctx);
                _showReportSheet();
              }),
              if (isOwner)
                _sheetItem(Icons.delete_outline_rounded, 'Delete Wallpaper', () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Delete Wallpaper', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure you want to delete this wallpaper from Collective?',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await context.read<CommunityProvider>().deletePost(post.id);
                    if (mounted) Navigator.pop(context);
                  }
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoSheet() {
    final post = _currentPost;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Wallpaper Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              _infoRow('Title', post.title ?? 'Collective Wallpaper'),
              _infoRow('Creator', post.author?.displayName ?? 'Collective Member'),
              _infoRow('Resolution', '${post.width ?? 1080} × ${post.height ?? 1920}'),
              _infoRow('Likes', '${post.likesCount}'),
              _infoRow('Downloads', '${post.downloadsCount}'),
              _infoRow('Comments', '${post.commentsCount}'),
              _infoRow('Uploaded', post.createdAt.toIso8601String().split('T')[0]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportBottomSheet(postId: _currentPost.id),
    );
  }

  // ─── Follow Button ────────────────────────────────────────────────────────

  Widget _buildFollowButton(CommunityUser author) {
    final myId = AuthService().backendUserId;
    if (myId != null && myId == author.id) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'You',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isFollowing = _followingOverrides[author.id] ?? author.isFollowing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (!AuthService().isLoggedIn) {
          final loggedIn = await showAuthModal(
            context,
            message: 'Sign in to follow creators and see their latest wallpapers.',
          );
          if (loggedIn != true || !AuthService().isLoggedIn) {
            // User closed the modal or didn't sign in -> do not follow
            return;
          }
        }
        if (!mounted) return;
        HapticFeedback.lightImpact();
        final before = isFollowing;
        setState(() {
          _followingOverrides[author.id] = !before;
        });

        try {
          final res = await context.read<CommunityProvider>().toggleFollow(author);
          if (mounted) {
            setState(() {
              _followingOverrides[author.id] = res;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _followingOverrides[author.id] = before;
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white12 : AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? Colors.white24 : AppTheme.primary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFollowing) ...[
              const Icon(Icons.add, size: 14, color: Colors.black),
              const SizedBox(width: 4),
            ],
            Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                color: isFollowing ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Comments Sheet ───────────────────────────────────────────────────────

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsBottomSheet(
        post: _currentPost,
        onCommentAdded: () {
          setState(() {
            _currentPost.commentsCount += 1;
          });
        },
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────

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
                  color: Colors.grey[900]!.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
                    ),
                    SizedBox(height: 18),
                    Text('Downloading wallpaper...', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                  color: Colors.grey[900]!.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
                    ),
                    SizedBox(height: 18),
                    Text('Setting wallpaper...', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Comments Bottom Sheet ───────────────────────────────────────────────────

class _CommentsBottomSheet extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onCommentAdded;

  const _CommentsBottomSheet({
    required this.post,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final _commentController = TextEditingController();
  List<CommunityComment> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final provider = context.read<CommunityProvider>();
    final list = await provider.loadComments(widget.post.id);
    if (mounted) {
      setState(() {
        _comments = list;
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (!AuthService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<CommunityProvider>();
    final newComment = await provider.addComment(widget.post.id, text);

    if (mounted) {
      if (newComment != null) {
        _commentController.clear();
        setState(() {
          _comments.insert(0, newComment);
          _submitting = false;
        });
        widget.onCommentAdded();
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_comments.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 16),

            // Comments List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet. Say something nice!',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final comment = _comments[i];
                            final author = comment.author;
                            final handle = (author.username?.isNotEmpty == true)
                                ? author.username!
                                : author.displayName
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'[^a-z0-9_]'), '');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: author.photoUrl != null
                                        ? CachedNetworkImageProvider(
                                            author.photoUrl!)
                                        : null,
                                    child: author.photoUrl == null
                                        ? const Icon(Icons.person_rounded,
                                            color: Colors.white70, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              author.displayName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '@$handle',
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          comment.content,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.black26,
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

