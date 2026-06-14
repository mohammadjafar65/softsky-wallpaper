import 'package:flutter/material.dart';
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
      ]);
      if (!mounted) return;
      setState(() {
        _stats = {
          'totalWallpapers': results[0]['pagination']?['total'] ?? 0,
          'totalCategories':
              (results[1]['categories'] as List?)?.length ?? 0,
          'totalUsers': results[2]['totalUsers'] ?? 0,
          'proUsers': results[2]['proUsers'] ?? 0,
          'totalDownloads': results[2]['totalWallpaperDownloads'] ?? 0,
          'newUsers': results[2]['newUsersThisMonth'] ?? 0,
        };
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
                subtitle: 'Overview of your app activity',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrorBanner(message: _error!, onRetry: _load),
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
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 110,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    StatCard(
                      label: 'Total Wallpapers',
                      value: '${_stats['totalWallpapers'] ?? 0}',
                      icon: Icons.wallpaper_rounded,
                      color: AppTheme.info,
                    ),
                    StatCard(
                      label: 'Categories',
                      value: '${_stats['totalCategories'] ?? 0}',
                      icon: Icons.category_rounded,
                      color: AppTheme.warning,
                    ),
                    StatCard(
                      label: 'Total Users',
                      value: '${_stats['totalUsers'] ?? 0}',
                      icon: Icons.people_rounded,
                      color: AppTheme.success,
                    ),
                    StatCard(
                      label: 'Pro Users',
                      value: '${_stats['proUsers'] ?? 0}',
                      icon: Icons.star_rounded,
                      color: AppTheme.accentBright,
                    ),
                    StatCard(
                      label: 'Downloads',
                      value: '${_stats['totalDownloads'] ?? 0}',
                      icon: Icons.download_rounded,
                      color: AppTheme.primary,
                    ),
                    StatCard(
                      label: 'New This Month',
                      value: '${_stats['newUsers'] ?? 0}',
                      icon: Icons.person_add_rounded,
                      color: AppTheme.error,
                    ),
                  ]),
                ),
              ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
