import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List _subs = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _subs = [];
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '/subscriptions',
        params: {'page': '$_page', 'limit': '$_limit'},
      );
      if (!mounted) return;
      setState(() {
        _subs = data['subscriptions'] ?? data['data'] ?? [];
        _total = data['pagination']?['total'] ?? data['total'] ?? 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return AppTheme.success;
      case 'expired':
        return AppTheme.error;
      case 'cancelled':
        return AppTheme.textSecondary;
      default:
        return AppTheme.warning;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(title: 'Subscriptions', subtitle: '$_total total subscriptions'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _subs.isEmpty
                    ? const EmptyState(
                        icon: Icons.card_membership_rounded,
                        title: 'No subscriptions found',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subs.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final sub = _subs[i];
                            final status = sub['status']?.toString() ?? 'unknown';
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.card_membership_rounded,
                                        color: _statusColor(status),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub['user']?['email'] ??
                                                sub['userId']?.toString() ??
                                                'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sub['plan'] ?? sub['productId'] ?? 'Unknown plan',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _statusColor(status),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (sub['expiresAt'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(sub['expiresAt'].toString()),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
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
