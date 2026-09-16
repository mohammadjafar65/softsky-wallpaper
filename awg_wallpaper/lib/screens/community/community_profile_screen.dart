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
  const CommunityProfileScreen({super.key, required this.userId});

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
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<CommunityProvider>();
    final [user, posts] = await Future.wait([
      provider.getCommunityUser(widget.userId),
      provider.getUserPosts(widget.userId),
    ]);

    if (mounted) {
      setState(() {
        _user = user as CommunityUser?;
        _posts = posts as List<CommunityPost>;
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
    final isOwnProfile = AuthService().backendUserId != null &&
        AuthService().backendUserId == widget.userId;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackground(isDark),
        title: Text(_user?.displayName ?? 'Profile'),
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

                            // Stats row
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

                            // Follow button (hide for own profile)
                            if (!isOwnProfile)
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
                                      : Text(
                                          _user!.isFollowing
                                              ? 'Following'
                                              : 'Follow',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
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
                                              post: _posts[i]),
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
