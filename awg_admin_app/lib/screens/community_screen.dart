import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List _posts = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  final int _limit = 20;
  String _filter = 'unapproved';
  String _search = '';
  final _searchController = TextEditingController();

  Map<String, dynamic> _stats = {
    'totalPosts': 0,
    'reportedPosts': 0,
    'unapprovedPosts': 0,
    'totalReports': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService.get('/community/admin/stats');
      if (mounted && res is Map<String, dynamic>) {
        setState(() => _stats = res);
      }
    } catch (_) {}
  }

  Future<void> _loadPosts({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _posts = [];
    }
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'page': '$_page',
        'limit': '$_limit',
        'filter': _filter,
        if (_search.isNotEmpty) 'search': _search,
      };
      final res = await ApiService.get('/community/admin/posts', params: params);
      if (!mounted) return;
      if (res is Map<String, dynamic>) {
        setState(() {
          _posts = res['posts'] as List? ?? [];
          _totalPages = res['totalPages'] as int? ?? 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approvePost(int id) async {
    try {
      await ApiService.patch('/community/admin/posts/$id/approve');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallpaper approved & live on app!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadStats();
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _rejectPost(int id) async {
    try {
      await ApiService.patch('/community/admin/posts/$id/reject');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallpaper hidden from live app'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadStats();
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deletePost(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Creator Wallpaper',
      message: 'Are you sure you want to delete this wallpaper permanently? This cannot be undone.',
    );
    if (!confirmed) return;
    try {
      await ApiService.delete('/community/admin/posts/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper deleted permanently')),
      );
      _loadStats();
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showPreviewDialog(Map<String, dynamic> post) {
    final bool isApproved = post['isApproved'] == true;
    final int id = post['id'] as int;
    final author = post['author'] as Map<String, dynamic>?;
    final authorName = author?['displayName'] ?? author?['username'] ?? 'Creator';
    final imageUrl = post['imageUrl'] as String;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: author?['photoUrl'] != null
                          ? CachedNetworkImageProvider(author!['photoUrl'])
                          : null,
                      child: author?['photoUrl'] == null
                          ? Text(
                              authorName.isNotEmpty ? authorName[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            post['title'] != null && (post['title'] as String).isNotEmpty
                                ? post['title']
                                : '@${author?['username'] ?? 'creator'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (post['width'] != null && post['height'] != null)
                          Text(
                            '${post['width']} × ${post['height']} px',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const SizedBox(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isApproved ? 'LIVE' : 'PENDING REVIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isApproved ? Colors.green : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (!isApproved)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _approvePost(id);
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: const Text('Approve & Publish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _rejectPost(id);
                              },
                              icon: const Icon(Icons.visibility_off_rounded, size: 18),
                              label: const Text('Hide from Live'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade800,
                                side: BorderSide(color: Colors.orange.shade800),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deletePost(id);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          tooltip: 'Delete',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(
            title: 'Creator Wallpapers',
            subtitle: 'Moderate user uploads before they appear on the live app',
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _loadStats();
                _loadPosts(reset: true);
              },
              tooltip: 'Refresh',
            ),
          ),
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search title or creator...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _loadPosts(reset: true);
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() => _search = val.trim());
                    _loadPosts(reset: true);
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'unapproved',
                        'Pending Review (${_stats['unapprovedPosts'] ?? 0})',
                        Icons.pending_actions_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'approved',
                        'Live / Approved',
                        Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'reported',
                        'Reported (${_stats['reportedPosts'] ?? 0})',
                        Icons.flag_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'all',
                        'All (${_stats['totalPosts'] ?? 0})',
                        Icons.apps_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? const EmptyState(
                        icon: Icons.photo_library_outlined,
                        title: 'No Wallpapers Found',
                        subtitle: 'No creator wallpapers match the selected filter.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadStats();
                          await _loadPosts(reset: true);
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index] as Map<String, dynamic>;
                            return _buildPostCard(post);
                          },
                        ),
                      ),
          ),
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _loadPosts();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous'),
                  ),
                  Text(
                    'Page $_page of $_totalPages',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: _page < _totalPages
                        ? () {
                            setState(() => _page++);
                            _loadPosts();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () {
        if (_filter != key) {
          setState(() {
            _filter = key;
            _page = 1;
          });
          _loadPosts(reset: true);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final bool isApproved = post['isApproved'] == true;
    final bool isReported = post['isReported'] == true;
    final int id = post['id'] as int;
    final author = post['author'] as Map<String, dynamic>?;
    final authorName = author?['displayName'] ?? author?['username'] ?? 'Creator';

    return GestureDetector(
      onTap: () => _showPreviewDialog(post),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReported
                ? Colors.red.shade300
                : !isApproved
                    ? Colors.orange.shade300
                    : AppTheme.border,
            width: (isReported || !isApproved) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: post['thumbnailUrl'] ?? post['imageUrl'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green : Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isApproved ? 'LIVE' : 'PENDING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  if (isReported)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'FLAGGED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post['title'] != null && (post['title'] as String).isNotEmpty)
                    Text(
                      post['title'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!isApproved)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approvePost(id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectPost(id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                              side: BorderSide(color: Colors.orange.shade800),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Hide',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _deletePost(id),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                      ),
                    ],
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
