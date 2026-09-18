import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/page_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String? _error;
  bool _serverOnline = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.get('/wallpapers', params: {'limit': '1'}),
        ApiService.get('/categories'),
        ApiService.get('/users/stats/overview'),
        ApiService.get('/community/admin/stats'),
      ]);
      if (!mounted) return;
      final commStats = results[3] as Map<String, dynamic>? ?? {};

      setState(() {
        _stats = {
          'totalWallpapers': results[0]['pagination']?['total'] ?? 0,
          'totalCategories': (results[1]['categories'] as List?)?.length ?? 0,
          'totalUsers': results[2]['totalUsers'] ?? 0,
          'proUsers': results[2]['proUsers'] ?? 0,
          'totalDownloads': results[2]['totalWallpaperDownloads'] ?? 0,
          'newUsers': results[2]['newUsersThisMonth'] ?? 0,
          'unapprovedPosts': commStats['unapprovedPosts'] ?? 0,
          'totalReports': commStats['totalReports'] ?? 0,
        };
        _serverOnline = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _serverOnline = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'Dashboard',
                subtitle: 'Real-time overview of Softsky operations',
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                  tooltip: 'Refresh',
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _ErrorBanner(message: _error!, onRetry: _load),
                ),
              ),
            // Server Health Status Pill
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _serverOnline
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _serverOnline
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _serverOnline ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _serverOnline
                              ? 'API Server Connected • softskyapi.softsky.studio (v3.0.28)'
                              : 'API Server Disconnected or Unreachable',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _serverOnline ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Quick Actions Panel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionChip(
                            context,
                            icon: Icons.add_photo_alternate_rounded,
                            label: 'Upload Art',
                            color: AppTheme.info,
                            onTap: () => context.go('/wallpapers'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            context,
                            icon: Icons.verified_user_rounded,
                            label: 'Moderation (${_stats['unapprovedPosts'] ?? 0})',
                            color: (_stats['unapprovedPosts'] ?? 0) > 0 ? AppTheme.error : AppTheme.creator,
                            onTap: () => context.go('/community'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            context,
                            icon: Icons.notifications_active_rounded,
                            label: 'Send Push',
                            color: AppTheme.pro,
                            onTap: () => context.go('/notifications'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            context,
                            icon: Icons.settings_rounded,
                            label: 'App Settings',
                            color: AppTheme.primary,
                            onTap: () => context.go('/settings'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 115,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildNavStatCard(
                      context,
                      label: 'Total Wallpapers',
                      value: '${_stats['totalWallpapers'] ?? 0}',
                      icon: Icons.wallpaper_rounded,
                      route: '/wallpapers',
                      color: AppTheme.primary,
                    ),
                    _buildNavStatCard(
                      context,
                      label: 'Categories',
                      value: '${_stats['totalCategories'] ?? 0}',
                      icon: Icons.category_rounded,
                      route: '/categories',
                      color: const Color(0xFF10B981),
                    ),
                    _buildNavStatCard(
                      context,
                      label: 'Registered Users',
                      value: '${_stats['totalUsers'] ?? 0}',
                      icon: Icons.people_rounded,
                      route: '/users',
                      color: const Color(0xFF6366F1),
                    ),
                    _buildNavStatCard(
                      context,
                      label: 'Pro Subscribers',
                      value: '${_stats['proUsers'] ?? 0}',
                      icon: Icons.workspace_premium_rounded,
                      route: '/subscriptions',
                      color: const Color(0xFFF59E0B),
                    ),
                    _buildNavStatCard(
                      context,
                      label: 'Pending Approvals',
                      value: '${_stats['unapprovedPosts'] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      route: '/community',
                      color: const Color(0xFFEF4444),
                    ),
                    _buildNavStatCard(
                      context,
                      label: 'Total Downloads',
                      value: '${_stats['totalDownloads'] ?? 0}',
                      icon: Icons.download_rounded,
                      route: '/dashboard',
                      color: const Color(0xFF8B5CF6),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required String route,
    Color color = AppTheme.primary,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(12),
      child: StatCard(
        label: label,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
