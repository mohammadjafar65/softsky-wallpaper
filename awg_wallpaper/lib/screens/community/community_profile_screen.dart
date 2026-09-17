import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import 'post_detail_screen.dart';

class CommunityProfileScreen extends StatefulWidget {
  final int userId;
  final CommunityUser? initialUser;
  final bool isCurrentUser;
  const CommunityProfileScreen({
    super.key,
    required this.userId,
    this.initialUser,
    this.isCurrentUser = false,
  });

  @override
  State<CommunityProfileScreen> createState() =>
      _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  CommunityUser? _user;
  List<CommunityPost> _posts = [];
  bool _loading = true;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    if (_user != null) {
      _loading = false;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<CommunityProvider>();
    CommunityUser? user = _user ?? widget.initialUser;
    final List<CommunityPost> localPosts = [];

    // Find any matching posts and author in locally loaded community posts
    for (final p in [...provider.trendingPosts, ...provider.feedPosts]) {
      if (p.author != null && p.author!.id == widget.userId) {
        user ??= p.author;
        if (!localPosts.any((existing) => existing.id == p.id)) {
          localPosts.add(p);
        }
      }
    }

    if (mounted && (user != null || localPosts.isNotEmpty)) {
      setState(() {
        if (user != null) _user = user;
        if (localPosts.isNotEmpty && _posts.isEmpty) _posts = localPosts;
        _loading = false;
      });
    }

    try {
      final results = await Future.wait([
        provider.getCommunityUser(widget.userId),
        provider.getUserPosts(widget.userId),
      ]);
      if (results[0] != null) user = results[0] as CommunityUser;
      final serverPosts = results[1] as List<CommunityPost>;
      if (serverPosts.isNotEmpty) {
        localPosts.clear();
        localPosts.addAll(serverPosts);
      }
    } catch (e) {
      debugPrint('getCommunityUser error (using fallback): $e');
    }

    if (mounted) {
      setState(() {
        _user = user ?? _user ?? widget.initialUser;
        if (localPosts.isNotEmpty) _posts = localPosts;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (!AuthService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to follow users')),
      );
      return;
    }
    if (_user == null) return;

    setState(() => _followLoading = true);
    final provider = context.read<CommunityProvider>();
    final newFollowing = await provider.toggleFollow(_user!);

    if (mounted) {
      setState(() {
        _user = _user!.copyWith(
          isFollowing: newFollowing,
          followersCount:
              _user!.followersCount + (newFollowing ? 1 : -1),
        );
        _followLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnProfile = widget.isCurrentUser ||
        (AuthService().backendUserId != null &&
            AuthService().backendUserId == widget.userId);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackground(isDark),
        title: Text(_user?.displayName ?? 'Profile'),
        actions: [
          if (_user != null && !isOwnProfile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: GestureDetector(
                  onTap: _followLoading ? null : _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _user!.isFollowing ? Colors.white12 : AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _user!.isFollowing ? Colors.white24 : AppTheme.primary,
                      ),
                    ),
                    child: _followLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _user!.isFollowing ? Icons.check : Icons.add,
                                size: 14,
                                color: _user!.isFollowing ? Colors.white : Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _user!.isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color: _user!.isFollowing ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _user == null
              ? const Center(child: Text('User not found'))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppTheme.primary,
                              backgroundImage: _user?.photoUrl != null
                                  ? CachedNetworkImageProvider(
                                      _user!.photoUrl!)
                                  : null,
                              child: _user?.photoUrl == null
                                  ? Text(
                                      _user!.displayName
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    )
                                  : null,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              _user!.displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(isDark),
                              ),
                            ),

                            if (_user?.username != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@${_user!.username}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextMuted(isDark)),
                              ),
                            ],

                            if (_user?.bio != null &&
                                _user!.bio!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _user!.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.getTextSecondary(isDark),
                                  height: 1.5,
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Stats row: Posts | Downloads | Followers | Following
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatColumn(
                                    count: _user!.postsCount,
                                    label: 'Posts'),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.grey
                                        .withValues(alpha: 0.3)),
                                _StatColumn(
                                    count: _user!.totalDownloads,
                                    label: 'Downloads'),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.grey
                                        .withValues(alpha: 0.3)),
                                _StatColumn(
                                    count: _user!.followersCount,
                                    label: 'Followers'),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.grey
                                        .withValues(alpha: 0.3)),
                                _StatColumn(
                                    count: _user!.followingCount,
                                    label: 'Following'),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Follow button (or Your Profile chip)
                            if (isOwnProfile)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_rounded, size: 18, color: AppTheme.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Your Profile',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _followLoading
                                      ? null
                                      : _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _user!.isFollowing
                                        ? Colors.grey.withValues(alpha: 0.2)
                                        : AppTheme.primary,
                                    foregroundColor: _user!.isFollowing
                                        ? AppTheme
                                            .getTextPrimary(isDark)
                                        : Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: _followLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _user!.isFollowing
                                                  ? Icons.check_rounded
                                                  : Icons.person_add_rounded,
                                              size: 18,
                                              color: _user!.isFollowing
                                                  ? AppTheme.getTextPrimary(isDark)
                                                  : Colors.black,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _user!.isFollowing
                                                  ? 'Following'
                                                  : 'Follow',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Posts grid
                    _posts.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'No posts yet',
                                  style: TextStyle(
                                      color:
                                          Colors.grey.withValues(alpha: 0.5)),
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 0, 12, 120),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PostDetailScreen(
                                              posts: _posts,
                                              initialIndex: i),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: _posts[i].thumbnailUrl ??
                                          _posts[i].imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                childCount: _posts.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio: 9 / 16,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final int count;
  final String label;
  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count >= 1000
              ? '${(count / 1000).toStringAsFixed(1)}K'
              : '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.withValues(alpha: 0.6))),
      ],
    );
  }
}
