import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'subscription_screen.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  bool _isRestoring = false;
  bool _isRefreshing = false;

  Future<void> _openPlayStoreSubscriptions() async {
    final Uri playStoreUri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=com.webinessdesign.softskywallpaper',
    );
    try {
      final launched = await launchUrl(
        playStoreUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          Uri.parse('https://play.google.com/store/account/subscriptions'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not open Google Play Store. Please open Google Play > Subscriptions manually.'),
            backgroundColor: AppTheme.getSurface(
                context.read<ThemeProvider>().isDarkMode),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases(SubscriptionProvider provider) async {
    setState(() => _isRestoring = true);
    final isDark = context.read<ThemeProvider>().isDarkMode;

    try {
      await provider.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.isPro
                        ? 'Purchases restored successfully! Pro is active.'
                        : 'No active Pro subscription found for this account.',
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.getSurface(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: AppTheme.getSurface(isDark),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _refreshStatus(SubscriptionProvider provider) async {
    setState(() => _isRefreshing = true);
    final isDark = context.read<ThemeProvider>().isDarkMode;

    try {
      await provider.checkBackendSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 18),
                SizedBox(width: 10),
                Text('Subscription status synced with server'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.getSurface(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showCancelDialog(
      BuildContext context, bool isDark, String? renewalDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancel Subscription',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Managed via Google Play',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getTextMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Subscriptions are safely managed by Google Play Store. If you cancel, your Pro benefits will remain active until the end of your current billing period ($renewalDate).',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.getTextSecondary(isDark),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppTheme.getSurfaceVariant(isDark),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Keep Plan',
                      style: TextStyle(
                        color: AppTheme.getTextPrimary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openPlayStoreSubscriptions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(
                      'Open Play Store',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isPro = provider.isPro;
    final plan = provider.currentPlan;
    final expiresDate = provider.expiryDate;
    final isLifetime = plan == SubscriptionPlan.lifetime;
    final currentUser = AuthService().currentUser;

    String dateStr = 'Never';
    if (expiresDate != null) {
      dateStr =
          '${expiresDate.day.toString().padLeft(2, '0')}/${expiresDate.month.toString().padLeft(2, '0')}/${expiresDate.year}';
    }

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark).withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.getTextPrimary(isDark),
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Manage Subscription',
          style: TextStyle(
            color: AppTheme.getTextPrimary(isDark),
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sync Status',
            onPressed: _isRefreshing ? null : () => _refreshStatus(provider),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : Icon(
                    Icons.sync_rounded,
                    color: AppTheme.getTextSecondary(isDark),
                    size: 22,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Status Card
            _buildHeroCard(context, isDark, isPro, isLifetime, plan, dateStr),

            const SizedBox(height: 24),

            // Pro Privileges Card
            _buildPrivilegesSection(isDark, isPro),

            const SizedBox(height: 24),

            // Subscription Details Card
            _buildDetailsCard(
              context,
              isDark,
              provider,
              isPro,
              isLifetime,
              plan,
              dateStr,
              currentUser?.email,
            ),

            const SizedBox(height: 28),

            // Actions Block
            if (isPro) ...[
              // Manage on Google Play Button
              ElevatedButton.icon(
                onPressed: _openPlayStoreSubscriptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Manage on Google Play Store',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Subscription Option (Only for recurring subscriptions)
              if (!isLifetime)
                OutlinedButton(
                  onPressed: () => _showCancelDialog(context, isDark, dateStr),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(
                      color: AppTheme.error.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text(
                    'Cancel Subscription',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
            ] else ...[
              // Free User Upgrade CTA
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.diamond_rounded, size: 20),
                  label: const Text(
                    'Upgrade to SoftSky Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Restore Purchases Text Button
            Center(
              child: TextButton.icon(
                onPressed: _isRestoring
                    ? null
                    : () => _restorePurchases(provider),
                icon: _isRestoring
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.restore_rounded,
                        size: 18,
                        color: AppTheme.getTextSecondary(isDark),
                      ),
                label: Text(
                  _isRestoring ? 'Restoring Purchases...' : 'Restore Purchases',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextSecondary(isDark),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Google Play policy disclaimer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Subscriptions renew automatically unless cancelled via Google Play at least 24 hours prior to renewal. Manage payment methods or cancel anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    bool isPro,
    bool isLifetime,
    SubscriptionPlan plan,
    String dateStr,
  ) {
    if (isPro) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF9F1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB700).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          size: 16, color: Colors.black),
                      SizedBox(width: 5),
                      Text(
                        'VIP MEMBER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.success,
                        ),
                        child: SizedBox(
                          width: 6,
                          height: 6,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.diamond_rounded,
                size: 40,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isLifetime ? 'LIFETIME ACCESS' : 'SOFTSKY PRO',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLifetime
                  ? 'Permanent VIP privileges • Never expires'
                  : 'Auto-renews on $dateStr via Google Play',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    // Free User Hero
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceVariant(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'CURRENT PLAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppTheme.getTextMuted(isDark),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'FREE TIER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextMuted(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SoftSky Standard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ad-supported with standard resolution downloads',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getTextMuted(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegesSection(bool isDark, bool isPro) {
    final perks = [
      {
        'icon': Icons.hd_rounded,
        'title': 'Ultra HD & 4K',
        'subtitle': 'Full original master quality',
        'active': isPro,
      },
      {
        'icon': Icons.block_rounded,
        'title': '100% Ad-Free',
        'subtitle': 'Clean uninterrupted experience',
        'active': isPro,
      },
      {
        'icon': Icons.auto_awesome_motion_rounded,
        'title': 'Auto Changer',
        'subtitle': 'Dynamic home & lock rotation',
        'active': isPro,
      },
      {
        'icon': Icons.nights_stay_rounded,
        'title': 'Day & Night Mode',
        'subtitle': 'Time-synchronized wallpapers',
        'active': isPro,
      },
      {
        'icon': Icons.bolt_rounded,
        'title': 'VIP Cloud Speed',
        'subtitle': 'Priority high-speed servers',
        'active': isPro,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Exclusive Creator Drops',
        'subtitle': 'Immediate access to VIP items',
        'active': isPro,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isPro ? 'Your Active Privileges' : 'Unlock With Pro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            Text(
              isPro ? 'All Unlocked' : '6 VIP Perks',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isPro ? AppTheme.success : AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: perks.asMap().entries.map((entry) {
              final idx = entry.key;
              final perk = entry.value;
              final isLast = idx == perks.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPro
                                ? AppTheme.gold.withValues(alpha: 0.15)
                                : AppTheme.getSurfaceVariant(isDark),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            perk['icon'] as IconData,
                            size: 18,
                            color: isPro
                                ? AppTheme.gold
                                : AppTheme.getTextMuted(isDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perk['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.getTextPrimary(isDark),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                perk['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getTextMuted(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isPro
                              ? Icons.check_circle_rounded
                              : Icons.lock_outline_rounded,
                          size: 19,
                          color: isPro
                              ? AppTheme.success
                              : AppTheme.getTextMuted(isDark),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppTheme.getSurfaceVariant(isDark)
                          .withValues(alpha: 0.4),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    bool isDark,
    SubscriptionProvider provider,
    bool isPro,
    bool isLifetime,
    SubscriptionPlan plan,
    String dateStr,
    String? accountEmail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppTheme.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                isDark,
                'Current Plan',
                isPro ? provider.getPlanName(plan) : 'Free Tier',
                icon: Icons.card_membership_rounded,
              ),
              _buildRowDivider(isDark),
              _buildDetailRow(
                isDark,
                'Status',
                isPro ? 'Active' : 'Inactive',
                valueColor: isPro ? AppTheme.success : AppTheme.getTextMuted(isDark),
                icon: Icons.shield_rounded,
              ),
              if (isPro && !isLifetime) ...[
                _buildRowDivider(isDark),
                _buildDetailRow(
                  isDark,
                  'Renewal Date',
                  dateStr,
                  icon: Icons.event_repeat_rounded,
                ),
              ],
              _buildRowDivider(isDark),
              _buildDetailRow(
                isDark,
                'Billing Provider',
                'Google Play Store',
                icon: Icons.shop_two_outlined,
              ),
              if (accountEmail != null && accountEmail.isNotEmpty) ...[
                _buildRowDivider(isDark),
                _buildDetailRow(
                  isDark,
                  'Account',
                  accountEmail,
                  icon: Icons.alternate_email_rounded,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    bool isDark,
    String title,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: AppTheme.getTextMuted(isDark),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? AppTheme.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.4),
      ),
    );
  }
}
