import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/cached_image_config.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/pill_tab_bar.dart';
import 'post_detail_screen.dart';
import 'upload_wallpaper_screen.dart';
import 'community_profile_screen.dart';
import '../../widgets/top_bar_profile_avatar.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _feedScrollController = ScrollController();
  final _trendingScrollController = ScrollController();
  int _selectedTabIndex = 1; // Default to Trending so wallpapers show immediately

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: _selectedTabIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _tabController.animation?.addListener(() {
      final newIndex = _tabController.animation!.value.round();
      if (newIndex != _selectedTabIndex && mounted) {
        setState(() {
          _selectedTabIndex = newIndex;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.loadTrending(refresh: true);
      provider.loadFeed(refresh: true);
    });

    _feedScrollController.addListener(() {
      if (_feedScrollController.position.pixels >=
          _feedScrollController.position.maxScrollExtent - 200) {
        context.read<CommunityProvider>().loadFeed();
      }
    });

    _trendingScrollController.addListener(() {
      if (_trendingScrollController.position.pixels >=
          _trendingScrollController.position.maxScrollExtent - 200) {
        context.read<CommunityProvider>().loadTrending();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedScrollController.dispose();
    _trendingScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Bar with Collective title, date, wallpaper count, upload & profile
                _buildHeader(context),

                // Tabs content: Following & Trending
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FeedGrid(
                        scrollController: _feedScrollController,
                        onExploreTrending: () {
                          _tabController.animateTo(1);
                          setState(() => _selectedTabIndex = 1);
                        },
                      ),
                      _TrendingGrid(
                          scrollController: _trendingScrollController),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Pill Tab Bar for Following & Trending above bottom nav (decreased spacing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 88,
            child: Center(
              child: PillTabBar(
                tabs: const ['Following', 'Trending'],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  _tabController.animateTo(index);
                  setState(() => _selectedTabIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title + Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collective',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<CommunityProvider>(
                builder: (context, provider, _) {
                  final count = provider.totalPosts > 0
                      ? provider.totalPosts
                      : (provider.trendingPosts.isNotEmpty
                          ? provider.trendingPosts.length
                          : provider.feedPosts.length);
                  return Text(
                    count > 0
                        ? '${DateFormatter.format()} • $count Wallpapers'
                        : DateFormatter.format(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),

          // Action Buttons: Upload + User Avatar
          Row(
            children: [
              // Upload Button
              GestureDetector(
                onTap: () => _openUpload(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Profile Button (User photo) -> Navigate to that user's collective profile
              const TopBarProfileAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  void _openUpload(BuildContext context) async {
    if (!AuthService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to share wallpapers')),
      );
      return;
    }

    final result = await Navigator.push<CommunityPost>(
      context,
      MaterialPageRoute(builder: (_) => const UploadWallpaperScreen()),
    );

    if (!mounted) return;
    if (result != null) {
      context.read<CommunityProvider>().loadTrending(refresh: true);
    }
  }
}

// ─── Feed Grid (Following) ──────────────────────────────────────────────────

class _FeedGrid extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback? onExploreTrending;
  const _FeedGrid({
    required this.scrollController,
    this.onExploreTrending,
  });

  @override
  Widget build(BuildContext context) {
    if (!AuthService().isLoggedIn) {
      return _EmptyFeed(
        message: 'Sign in to see wallpapers from\ncreators you follow',
        icon: Icons.people_outline_rounded,
        actionLabel: 'Explore Trending',
        onAction: onExploreTrending,
      );
    }

    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.feedLoading && provider.feedPosts.isEmpty) {
          return _buildShimmer();
        }

        if (provider.feedPosts.isEmpty) {
          return _EmptyFeed(
            message:
                'No wallpapers from creators you follow yet.\nExplore trending to find creators!',
            icon: Icons.people_outline_rounded,
            actionLabel: 'Explore Trending',
            onAction: onExploreTrending,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => provider.loadFeed(refresh: true),
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == provider.feedPosts.length) {
                        return provider.feedLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primary),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return _PostCard(
                        post: provider.feedPosts[i],
                        onTap: () => _openDetail(
                            context, provider.feedPosts, i),
                      );
                    },
                    childCount: provider.feedPosts.length +
                        (provider.feedHasMore ? 1 : 0),
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(
      BuildContext context, List<CommunityPost> posts, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostDetailScreen(posts: posts, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

// ─── Trending Grid ────────────────────────────────────────────────────────────

class _TrendingGrid extends StatelessWidget {
  final ScrollController scrollController;
  const _TrendingGrid({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.trendingLoading && provider.trendingPosts.isEmpty) {
          return _buildShimmer();
        }

        if (provider.trendingPosts.isEmpty) {
          return const _EmptyFeed(
            message: 'No collective wallpapers yet.\nBe the first to upload!',
            icon: Icons.auto_awesome_rounded,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => provider.loadTrending(refresh: true),
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == provider.trendingPosts.length) {
                        return provider.trendingLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primary),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return _PostCard(
                        post: provider.trendingPosts[i],
                        onTap: () => _openDetail(
                            context, provider.trendingPosts, i),
                      );
                    },
                    childCount: provider.trendingPosts.length +
                        (provider.trendingHasMore ? 1 : 0),
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(
      BuildContext context, List<CommunityPost> posts, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostDetailScreen(posts: posts, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

// ─── Post Card ───────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onTap;

  const _PostCard({
    required this.post,
    required this.onTap,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Hero(
            tag: 'community_wallpaper_${post.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: post.thumbnailUrl ?? post.imageUrl,
                    cacheManager: CachedImageConfig.cacheManager,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    memCacheWidth: 400,
                    placeholder: (_, __) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),

                  // Top right: Like button (dark translucent circle with heart)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<CommunityProvider>().toggleLike(post.id);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        child: Center(
                          child: Icon(
                            post.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: post.isLiked
                                ? Colors.red
                                : Colors.white.withValues(alpha: 0.9),
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom subtle gradient for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom row: Creator info on left, Downloads count on right
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        // Creator Avatar
                        GestureDetector(
                          onTap: () {
                            if (post.author != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommunityProfileScreen(
                                    userId: post.author!.id,
                                    initialUser: post.author,
                                  ),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: AppTheme.primary,
                            backgroundImage: post.author?.photoUrl != null
                                ? CachedNetworkImageProvider(
                                    post.author!.photoUrl!)
                                : null,
                            child: post.author?.photoUrl == null
                                ? Text(
                                    (post.author?.displayName ?? 'U')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Creator Name
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (post.author != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityProfileScreen(
                                      userId: post.author!.id,
                                      initialUser: post.author,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              post.author?.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Downloads Counter
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              post.downloadsCount >= 1000
                                  ? '${(post.downloadsCount / 1000).toStringAsFixed(post.downloadsCount >= 10000 ? 0 : 1)}K'
                                  : '${post.downloadsCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyFeed({
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
