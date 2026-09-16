import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../models/community_post.dart';
import '../../models/community_comment.dart';
import '../../providers/community_provider.dart';
import '../../services/auth_service.dart';
import 'community_profile_screen.dart';
import 'report_bottom_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  List<CommunityComment> _comments = [];
  bool _commentsLoading = true;
  bool _submittingComment = false;

  late CommunityPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    final provider = context.read<CommunityProvider>();
    _comments = await provider.loadComments(_post.id);
    if (mounted) setState(() => _commentsLoading = false);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (!AuthService().isLoggedIn) {
      _showLoginRequired();
      return;
    }

    setState(() => _submittingComment = true);
    final provider = context.read<CommunityProvider>();
    final comment = await provider.addComment(_post.id, text);
    if (comment != null && mounted) {
      _commentController.clear();
      setState(() {
        _comments.insert(0, comment);
        _submittingComment = false;
      });
    } else {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  void _toggleLike() {
    if (!AuthService().isLoggedIn) {
      _showLoginRequired();
      return;
    }
    final before = _post.isLiked;
    setState(() {
      _post.isLiked = !_post.isLiked;
      _post.likesCount += _post.isLiked ? 1 : -1;
    });
    context.read<CommunityProvider>().toggleLike(_post.id).catchError((_) {
      setState(() {
        _post.isLiked = before;
        _post.likesCount += before ? 1 : -1;
      });
    });
  }

  void _toggleSave() {
    if (!AuthService().isLoggedIn) {
      _showLoginRequired();
      return;
    }
    final before = _post.isSaved;
    setState(() {
      _post.isSaved = !_post.isSaved;
      _post.savesCount += _post.isSaved ? 1 : -1;
    });
    context.read<CommunityProvider>().toggleSave(_post.id).catchError((_) {
      setState(() {
        _post.isSaved = before;
        _post.savesCount += before ? 1 : -1;
      });
    });
  }

  void _share() {
    Share.share(_post.imageUrl, subject: _post.title ?? 'Check out this wallpaper!');
  }

  void _report() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ReportBottomSheet(postId: _post.id),
    );
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in to interact with posts'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Full image header
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.55,
            pinned: true,
            backgroundColor: AppTheme.getBackground(isDark),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: _post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  if (_post.author != null)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityProfileScreen(
                              userId: _post.author!.id),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primary,
                            backgroundImage:
                                _post.author?.photoUrl != null
                                    ? CachedNetworkImageProvider(
                                        _post.author!.photoUrl!)
                                    : null,
                            child: _post.author?.photoUrl == null
                                ? Text(
                                    (_post.author?.displayName ?? 'A')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post.author!.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.getTextPrimary(isDark),
                                ),
                              ),
                              if (_post.author?.username != null)
                                Text(
                                  '@${_post.author!.username}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getTextMuted(isDark)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Title
                  if (_post.title != null && _post.title!.isNotEmpty)
                    Text(
                      _post.title!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(isDark),
                      ),
                    ),

                  if (_post.description != null &&
                      _post.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _post.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextSecondary(isDark),
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action row
                  Row(
                    children: [
                      _ActionBtn(
                        icon: _post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '${_post.likesCount}',
                        color: _post.isLiked ? Colors.red : null,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.comment_outlined,
                        label: '${_post.commentsCount}',
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: _post.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: '${_post.savesCount}',
                        color: _post.isSaved ? AppTheme.primary : null,
                        onTap: _toggleSave,
                      ),
                      const Spacer(),
                      _ActionBtn(
                        icon: Icons.share_outlined,
                        label: '',
                        onTap: _share,
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.flag_outlined,
                        label: '',
                        onTap: _report,
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Comments section
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Add comment
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(isDark),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(
                                  color:
                                      Colors.grey.withValues(alpha: 0.5),
                                  fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _submittingComment ? null : _submitComment,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _submittingComment
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.black, size: 18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Comments list
                  if (_commentsLoading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                  else if (_comments.isEmpty)
                    Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.5)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _CommentTile(
                          comment: _comments[i], isDark: isDark),
                    ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              size: 24, color: color ?? Colors.grey.withValues(alpha: 0.7)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final bool isDark;
  const _CommentTile({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primary,
          backgroundImage: comment.author.photoUrl != null
              ? CachedNetworkImageProvider(comment.author.photoUrl!)
              : null,
          child: comment.author.photoUrl == null
              ? Text(
                  comment.author.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.author.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getTextSecondary(isDark),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
