import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import 'post_detail_screen.dart';
import 'upload_wallpaper_screen.dart';
import 'community_profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.loadFeed(refresh: true);
      provider.loadTrending(refresh: true);
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Community',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                  ),
                  const Spacer(),
                  // Upload button
                  if (AuthService().isLoggedIn)
                    GestureDetector(
                      onTap: () => _openUpload(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.primary, size: 22),
                      ),
                    ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.getTextMuted(isDark),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Following'),
                  Tab(text: 'Trending'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FeedGrid(scrollController: _feedScrollController),
                  _TrendingGrid(
                      scrollController: _trendingScrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUpload(BuildContext context) async {
    final provider = context.read<CommunityProvider>();
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadWallpaperScreen()),
    );
    if (newPost is CommunityPost) {
      provider.addPostToFeed(newPost);
    }
  }
}

// ─── Feed Grid ───────────────────────────────────────────────────────────────

class _FeedGrid extends StatelessWidget {
  final ScrollController scrollController;
  const _FeedGrid({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.feedLoading && provider.feedPosts.isEmpty) {
          return _buildShimmer();
        }

        if (provider.feedPosts.isEmpty) {
          return _EmptyFeed(
            message: 'Your feed is empty.\nFollow creators to see their wallpapers here.',
            icon: Icons.people_outline_rounded,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => provider.loadFeed(refresh: true),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
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
                          onTap: () => _openDetail(context, provider.feedPosts[i]));
                    },
                    childCount: provider.feedPosts.length +
                        (provider.feedHasMore ? 1 : 0),
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 9 / 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
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
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (provider.trendingPosts.isEmpty) {
          return _EmptyFeed(
            message: 'No trending wallpapers yet.\nBe the first to upload!',
            icon: Icons.trending_up_rounded,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => provider.loadTrending(refresh: true),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      return _PostCard(
                          post: provider.trendingPosts[i],
                          showLikes: true,
                          onTap: () =>
                              _openDetail(context, provider.trendingPosts[i]));
                    },
                    childCount: provider.trendingPosts.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 9 / 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }
}

// ─── Post Card ───────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final bool showLikes;

  const _PostCard({
    required this.post,
    required this.onTap,
    this.showLikes = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: post.thumbnailUrl ?? post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  color: Colors.grey.withValues(alpha: 0.15)),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image_rounded, color: Colors.grey),
            ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Author + likes row
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      if (post.author != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityProfileScreen(
                                userId: post.author!.id),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: post.author?.photoUrl != null
                          ? CachedNetworkImageProvider(
                              post.author!.photoUrl!)
                          : null,
                      child: post.author?.photoUrl == null
                          ? Text(
                              (post.author?.displayName ?? 'A')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
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
                  if (showLikes) ...[
                    const Icon(Icons.favorite_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyFeed({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
