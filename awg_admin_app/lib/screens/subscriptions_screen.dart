import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/stat_card.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  Map<String, dynamic> _stats = {};
  List _subscribers = [];
  bool _loading = true;
  String _planFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/subscriptions/stats'),
        ApiService.get('/subscriptions/subscribers', params: {'limit': '500'}),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>? ?? {};
        _subscribers = (results[1] as Map<String, dynamic>?)?['users'] as List? ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscriptions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List get _filteredSubscribers {
    if (_planFilter == 'all') return _subscribers;
    return _subscribers.where((s) {
      final plan = s['subscription']?['plan']?.toString().toLowerCase();
      return plan == _planFilter;
    }).toList();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Never';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  Color _planColor(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'lifetime':
        return AppTheme.creator;
      case 'annual':
        return AppTheme.pro;
      case 'monthly':
        return AppTheme.info;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _showEditSubscriptionModal(Map<String, dynamic> user) {
    final sub = user['subscription'] as Map<String, dynamic>? ?? {};
    String selectedPlan = sub['plan']?.toString() ?? 'free';
    final expiryCtrl = TextEditingController(
      text: sub['expiryDate'] != null ? _formatDate(sub['expiryDate']) : '',
    );
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage Subscription: ${user['displayName'] ?? user['email']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlan,
                    decoration: const InputDecoration(labelText: 'Subscription Plan'),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free (No Access)')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly Pro')),
                      DropdownMenuItem(value: 'annual', child: Text('Annual Pro (Discounted)')),
                      DropdownMenuItem(value: 'lifetime', child: Text('Lifetime Pro')),
                    ],
                    onChanged: (v) => setSheetState(() => selectedPlan = v ?? 'free'),
                  ),
                  const SizedBox(height: 12),
                  if (selectedPlan != 'free' && selectedPlan != 'lifetime') ...[
                    TextField(
                      controller: expiryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (YYYY-MM-DD)',
                        hintText: 'e.g. 2027-09-18',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                await ApiService.put('/users/${user['id']}', {
                                  'subscription': {
                                    'plan': selectedPlan,
                                    'expiryDate': expiryCtrl.text.trim().isNotEmpty
                                        ? expiryCtrl.text.trim()
                                        : null,
                                  },
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                _load();
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Failed to update: $e')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) setSheetState(() => saving = false);
                              }
                            },
                      child: Text(saving ? 'Saving...' : 'Update Plan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _stats['totalUsers'] as int? ?? 0;
    final proUsers = _stats['proUsers'] as int? ?? 0;
    final freeUsers = _stats['freeUsers'] as int? ?? 0;
    final newUsers = _stats['newUsersThisMonth'] as int? ?? 0;
    final downloads = _stats['totalWallpaperDownloads'] as int? ?? 0;
    final breakdown = _stats['subscriptionBreakdown'] as Map<String, dynamic>? ?? {};

    final adoptionRate = totalUsers > 0 ? ((proUsers / totalUsers) * 100).toStringAsFixed(1) : '0';
    final subscribers = _filteredSubscribers;

    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(
            title: 'Subscriptions',
            subtitle: '$proUsers active pro subscribers • $adoptionRate% adoption',
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // KPI Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 5 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                          children: [
                            StatCard(
                              label: 'Total Users',
                              value: totalUsers.toString(),
                              icon: Icons.people_rounded,
                              color: AppTheme.primary,
                            ),
                            StatCard(
                              label: 'Pro Members',
                              value: proUsers.toString(),
                              icon: Icons.workspace_premium_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            StatCard(
                              label: 'Free Users',
                              value: freeUsers.toString(),
                              icon: Icons.person_outline_rounded,
                              color: const Color(0xFF3B82F6),
                            ),
                            StatCard(
                              label: 'New (Month)',
                              value: newUsers.toString(),
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.success,
                            ),
                            StatCard(
                              label: 'Downloads',
                              value: downloads.toString(),
                              icon: Icons.download_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Plan Breakdown Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.pie_chart_rounded, size: 18, color: AppTheme.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Subscription Breakdown',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildPill('All ($proUsers)', 'all', isFilter: true),
                                    _buildPill('Annual: ${breakdown['annual'] ?? 0}', 'annual', isFilter: true),
                                    _buildPill('Monthly: ${breakdown['monthly'] ?? 0}', 'monthly', isFilter: true),
                                    _buildPill('Lifetime: ${breakdown['lifetime'] ?? 0}', 'lifetime', isFilter: true),
                                    _buildPill('Free: ${breakdown['free'] ?? 0}', 'free', isFilter: false),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subscriber Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Subscribers (${subscribers.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _planFilter == 'all' ? 'All Plans' : _planFilter.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Subscribers List
                        if (subscribers.isEmpty)
                          const EmptyState(
                            icon: Icons.card_membership_rounded,
                            title: 'No active subscribers found',
                          )
                        else
                          ...subscribers.map((u) {
                            final sub = u['subscription'] as Map<String, dynamic>? ?? {};
                            final plan = sub['plan']?.toString().toUpperCase() ?? 'FREE';
                            final expiry = sub['expiryDate'];
                            final photoUrl = u['photoUrl'] as String?;
                            final displayName = u['displayName'] as String? ?? u['email'] as String? ?? 'User';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: _planColor(plan).withValues(alpha: 0.15),
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null
                                      ? Text(
                                          displayName[0].toUpperCase(),
                                          style: TextStyle(
                                            color: _planColor(plan),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u['email']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      plan == 'LIFETIME'
                                          ? 'Lifetime Access'
                                          : 'Expires: ${_formatDate(expiry)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _planColor(plan).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _planColor(plan).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        plan,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _planColor(plan),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      color: AppTheme.textSecondary,
                                      onPressed: () => _showEditSubscriptionModal(u),
                                      tooltip: 'Manage Plan',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String plan, {required bool isFilter}) {
    final isSelected = _planFilter == plan;
    return GestureDetector(
      onTap: isFilter ? () => setState(() => _planFilter = plan) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : isFilter
                  ? const Color(0xFFF3F4F6)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
