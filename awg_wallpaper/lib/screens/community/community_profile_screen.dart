import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';
import 'post_detail_screen.dart';
import '../app_settings_screen.dart';
import '../subscription_screen.dart';
import '../manage_subscription_screen.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/auth_modal_sheet.dart';

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
    if (_user != null) _loading = false;
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<CommunityProvider>();
    CommunityUser? user = _user ?? widget.initialUser;
    final List<CommunityPost> localPosts = [];

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
      final loggedIn = await showAuthModal(
        context,
        message: 'Sign in to follow creators and see their latest wallpapers.',
      );
      if (loggedIn != true || !AuthService().isLoggedIn) {
        return;
      }
    }
    if (!mounted) return;
    if (_user == null) return;
    setState(() => _followLoading = true);
    final provider = context.read<CommunityProvider>();
    final newFollowing = await provider.toggleFollow(_user!);
    if (mounted) {
      setState(() {
        _user = _user!.copyWith(
          isFollowing: newFollowing,
          followersCount: _user!.followersCount + (newFollowing ? 1 : -1),
        );
        _followLoading = false;
      });
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: TextStyle(
            color: AppTheme.getTextPrimary(isDark),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.getTextSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.getTextMuted(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
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
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _user == null
                ? const Center(child: Text('User not found'))
                : CustomScrollView(
                    slivers: [
                      // ── Custom Header ──────────────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildHeader(context, isDark, isOwnProfile),
                      ),

                      // ── Profile Hero Card ──────────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildProfileCard(context, isDark, isOwnProfile),
                      ),

                      // ── Stats Row ─────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildStatsRow(isDark),
                      ),

                      // ── Subscription / Follow Button ───────────────────────
                      SliverToBoxAdapter(
                        child: _buildActionButton(context, isDark, isOwnProfile),
                      ),

                      // ── Posts Section Header ───────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                          child: Row(
                            children: [
                              Text(
                                'Posts',
                                style: TextStyle(
                                  color: AppTheme.getTextPrimary(isDark),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_posts.length}',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Posts Grid ────────────────────────────────────────
                      _posts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 48,
                                      color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No posts yet',
                                      style: TextStyle(
                                        color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.6),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final post = _posts[i];
                                    return GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PostDetailScreen(
                                              posts: _posts, initialIndex: i),
                                        ),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: post.thumbnailUrl ?? post.imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (isOwnProfile)
                                            Positioned(
                                              top: 6,
                                              left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: post.isApproved
                                                      ? Colors.green.withValues(alpha: 0.85)
                                                      : Colors.amber.shade900.withValues(alpha: 0.9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      post.isApproved
                                                          ? Icons.check_circle_rounded
                                                          : Icons.schedule_rounded,
                                                      size: 10,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      post.isApproved ? 'LIVE' : 'PENDING',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 0.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
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
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark).withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.getTextPrimary(isDark),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              isOwnProfile ? 'My Profile' : (_user?.displayName ?? 'Profile'),
              style: TextStyle(
                color: AppTheme.getTextPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions
          if (!isOwnProfile && _user != null) ...[
            // Follow button in header
            GestureDetector(
              onTap: _followLoading ? null : _toggleFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _user!.isFollowing ? Colors.white.withValues(alpha: 0.1) : AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
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
                            _user!.isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
                            size: 14,
                            color: _user!.isFollowing ? Colors.white70 : Colors.black,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _user!.isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: _user!.isFollowing ? Colors.white70 : Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],

          if (isOwnProfile) ...[
            // Settings
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(isDark).withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Icon(Icons.settings_outlined,
                      color: AppTheme.getTextPrimary(isDark), size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Logout
            GestureDetector(
              onTap: () => _showLogoutDialog(context, isDark),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Profile Hero Card ────────────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, bool isDark, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        blur: 20,
        opacity: isDark ? 0.08 : 0.4,
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(
          color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            // Avatar with gradient ring
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isOwnProfile
                      ? [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.6)]
                      : [AppTheme.primary.withValues(alpha: 0.8), Colors.blueAccent.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: _user?.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _user!.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTheme.primary),
                        errorWidget: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),

            const SizedBox(width: 16),

            // Name + username + bio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(isDark),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_user?.username != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '@${_user!.username}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getTextMuted(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (_user?.bio != null && _user!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _user!.bio!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondary(isDark).withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Plan badge
                  if (isOwnProfile)
                    Consumer<SubscriptionProvider>(
                      builder: (_, sub, __) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (sub.isPro ? AppTheme.gold : AppTheme.primary)
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (sub.isPro ? AppTheme.gold : AppTheme.primary)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sub.isPro ? Icons.workspace_premium_rounded : Icons.person_rounded,
                              size: 11,
                              color: sub.isPro ? AppTheme.gold : AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sub.isPro ? 'PRO MEMBER' : 'FREE PLAN',
                              style: TextStyle(
                                color: sub.isPro ? AppTheme.gold : AppTheme.primary,
                                fontSize: 10,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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

  Widget _avatarFallback() {
    return Container(
      color: AppTheme.primary,
      child: Center(
        child: Text(
          _user!.displayName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderRadius: 20,
        blur: 16,
        opacity: isDark ? 0.06 : 0.36,
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(
          color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.4),
        ),
        child: Row(
          children: [
            _buildStat(isDark, '${_user!.postsCount}', 'Posts'),
            _buildDivider(isDark),
            _buildStat(isDark, _formatCount(_user!.totalDownloads), 'Downloads'),
            _buildDivider(isDark),
            _buildStat(isDark, _formatCount(_user!.followersCount), 'Followers'),
            _buildDivider(isDark),
            _buildStat(isDark, _formatCount(_user!.followingCount), 'Following'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(bool isDark, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextPrimary(isDark),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.getTextMuted(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  // ── Action Button (Follow / Subscription) ───────────────────────────────────
  Widget _buildActionButton(BuildContext context, bool isDark, bool isOwnProfile) {
    if (isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Consumer<SubscriptionProvider>(
          builder: (context, sub, _) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => sub.isPro
                    ? const ManageSubscriptionScreen()
                    : const SubscriptionScreen(),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: sub.isPro
                    ? const LinearGradient(
                        colors: [AppTheme.gold, Color(0xFFFFB700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: sub.isPro ? null : AppTheme.getSurface(isDark),
                borderRadius: BorderRadius.circular(16),
                border: sub.isPro
                    ? null
                    : Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.5),
                      ),
                boxShadow: sub.isPro
                    ? [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sub.isPro ? Icons.workspace_premium_rounded : Icons.star_rounded,
                    size: 18,
                    color: sub.isPro ? Colors.black : AppTheme.gold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub.isPro ? 'Manage Pro Subscription' : 'Upgrade to Pro',
                    style: TextStyle(
                      color: sub.isPro ? Colors.black : AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Follow button for other users
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: _followLoading ? null : _toggleFollow,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _user!.isFollowing
                  ? AppTheme.getSurface(isDark)
                  : AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
              border: _user!.isFollowing
                  ? Border.all(color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5))
                  : null,
              boxShadow: _user!.isFollowing
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: _followLoading
                ? const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _user!.isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
                        size: 18,
                        color: _user!.isFollowing
                            ? AppTheme.getTextPrimary(isDark)
                            : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _user!.isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: _user!.isFollowing
                              ? AppTheme.getTextPrimary(isDark)
                              : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
