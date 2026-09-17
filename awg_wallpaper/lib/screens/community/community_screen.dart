import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/date_formatter.dart';
import '../profile_screen.dart';
import '../auth/login_screen.dart';
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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

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
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Bar with Date & Wallpaper Counter
                _buildHeader(context),

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

          // Floating filter tab bar above bottom nav (exact same UI as HomeScreen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 142,
            child: Center(
              child: _buildFilterTabBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabBar() {
    final labels = ['Following', 'Trending'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(labels.length, (i) {
              final isSelected = _tabController.index == i;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tabController.animateTo(i);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 86,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
              );
            }),
          ),
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
                'COMMUNITY',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Consumer<CommunityProvider>(
                builder: (context, provider, _) {
                  final count = provider.totalPosts > 0
                      ? provider.totalPosts
                      : (provider.feedPosts.length + provider.trendingPosts.length > 0
                          ? (provider.feedPosts.length > provider.trendingPosts.length
                              ? provider.feedPosts.length
                              : provider.trendingPosts.length)
                          : 0);
                  return Text(
                    count > 0
                        ? '${DateFormatter.format()} • $count Community Wallpapers'
                        : DateFormatter.format(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              // Upload Button
              GestureDetector(
                onTap: () => _openUpload(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile Button
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
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
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
        ],
      ),
    );
  }

  void _openUpload(BuildContext context) async {
    if (!AuthService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload wallpapers')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 210),
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
                          onTap: () => _openDetail(context, provider.feedPosts, i));
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

  void _openDetail(BuildContext context, List<CommunityPost> posts, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(posts: posts, initialIndex: initialIndex),
      ),
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 210),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      return _PostCard(
                          post: provider.trendingPosts[i],
                          showLikes: true,
                          onTap: () =>
                              _openDetail(context, provider.trendingPosts, i));
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

  void _openDetail(BuildContext context, List<CommunityPost> posts, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(posts: posts, initialIndex: initialIndex),
      ),
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
                  const SizedBox(width: 4),
                  const Icon(Icons.download_rounded,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 2),
                  Text(
                    '${post.downloadsCount}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.favorite_rounded,
                      size: 12, color: Colors.white70),
                  const SizedBox(width: 2),
                  Text(
                    '${post.likesCount}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
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
