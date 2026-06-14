import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List _users = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  final int _limit = 20;
  String _search = '';
  String _planFilter = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _users = [];
    }
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'page': '$_page',
        'limit': '$_limit',
        if (_search.isNotEmpty) 'search': _search,
        if (_planFilter.isNotEmpty) 'plan': _planFilter,
      };
      final data = await ApiService.get('/users', params: params);
      if (!mounted) return;
      setState(() {
        _users = data['users'] as List? ?? [];
        _total = (data['pagination'] as Map<String, dynamic>?)?['total'] as int? ?? 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete User',
      message: 'This user and all their data will be removed permanently.',
    );
    if (!confirmed) return;
    try {
      await ApiService.delete('/users/$id');
      _load(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(title: 'Users', subtitle: '$_total total users'),
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _search = '';
                                  _load(reset: true);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                      ),
                      onSubmitted: (v) {
                        _search = v;
                        _load(reset: true);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _planFilter.isEmpty ? null : _planFilter,
                    hint: const Text('Plan', style: TextStyle(fontSize: 13)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    onChanged: (v) {
                      _planFilter = v ?? '';
                      _load(reset: true);
                    },
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All')),
                      DropdownMenuItem(value: 'free', child: Text('Free')),
                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_rounded,
                        title: 'No users found',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final u = _users[i] as Map<String, dynamic>;
                            final isPro = u['subscriptionPlan'] == 'pro' ||
                                u['role'] == 'admin';
                            final photoUrl = u['photoUrl'] as String?;
                            final displayName =
                                u['displayName'] as String? ??
                                    u['email'] as String? ??
                                    'U';
                            final initial = displayName.trim().isNotEmpty
                                ? displayName.trim()[0].toUpperCase()
                                : 'U';
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isPro
                                      ? AppTheme.accentBright.withValues(alpha: 0.15)
                                      : AppTheme.surfaceVariant,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Text(
                                          initial,
                                          style: TextStyle(
                                            color: isPro
                                                ? AppTheme.accentBright
                                                : AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  u['email'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPro)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentBright
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppTheme.accentBright
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          u['role'] == 'admin'
                                              ? 'ADMIN'
                                              : 'PRO',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.accentBright,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppTheme.error,
                                      ),
                                      onPressed: () =>
                                          _delete(u['id'].toString()),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _limit).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    _page--;
                    _load();
                  }
                : null,
          ),
          Text(
            '$_page / $totalPages',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    _page++;
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
