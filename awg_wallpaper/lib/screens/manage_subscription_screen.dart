import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'subscription_screen.dart';
import '../widgets/subscription_plan_popup.dart';

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

              // Quick Plan Deals Button (Hidden if user already has Lifetime Plan)
              if (!isLifetime) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    SubscriptionPlanPopup.show(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: const Color(0xFFFB8500).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  icon: const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFFB8500), size: 18),
                  label: Text(
                    'Quick Plan Deals (50% Off)',
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(isDark),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
              // Limited Time 50% Off Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF2B5CE6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF93C5FD).withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B5CE6).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFFB703),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'LIMITED TIME OFFER',
                                  style: TextStyle(
                                    color: Color(0xFFFFB703),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFB8500),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '50% OFF',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Save 50% on SoftSky Pro Access',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Subscription Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181D) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.black.withValues(alpha: 0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Current Plan Row with Stylized Badge
              _buildCustomDetailRow(
                isDark: isDark,
                icon: Icons.card_membership_rounded,
                title: 'Current Plan',
                trailing: _buildPlanBadge(plan, isPro, isLifetime),
              ),
              _buildRowDivider(isDark),

              // Status Row with verified indicator
              _buildCustomDetailRow(
                isDark: isDark,
                icon: Icons.shield_rounded,
                title: 'Status',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isPro
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPro
                          ? const Color(0xFF10B981).withValues(alpha: 0.45)
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isPro ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPro ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: isPro
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildRowDivider(isDark),

              // Plan Duration / Renewal Date Row
              _buildCustomDetailRow(
                isDark: isDark,
                icon: isLifetime
                    ? Icons.all_inclusive_rounded
                    : Icons.event_repeat_rounded,
                title: isLifetime ? 'Plan Duration' : 'Renewal Date',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLifetime
                        ? const Color(0xFFFFB703).withValues(alpha: 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(8),
                    border: isLifetime
                        ? Border.all(
                            color: const Color(0xFFFFB703).withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Text(
                    isLifetime ? 'Never Expires • Lifetime' : dateStr,
                    style: TextStyle(
                      color: isLifetime
                          ? const Color(0xFFFFB703)
                          : AppTheme.getTextPrimary(isDark),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              _buildRowDivider(isDark),

              // Billing Provider Row
              _buildCustomDetailRow(
                isDark: isDark,
                icon: Icons.shop_two_outlined,
                title: 'Billing Provider',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Color(0xFF00C853), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Google Play Store',
                        style: TextStyle(
                          color: AppTheme.getTextPrimary(isDark),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (accountEmail != null && accountEmail.isNotEmpty) ...[
                _buildRowDivider(isDark),
                // Account Row
                _buildCustomDetailRow(
                  isDark: isDark,
                  icon: Icons.alternate_email_rounded,
                  title: 'Account',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      accountEmail,
                      style: TextStyle(
                        color: AppTheme.getTextSecondary(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanBadge(SubscriptionPlan plan, bool isPro, bool isLifetime) {
    if (!isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'FREE TIER',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (isLifetime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFB8500).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: Colors.black, size: 13),
            SizedBox(width: 4),
            Text(
              'LIFETIME VIP',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    if (plan == SubscriptionPlan.annual) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B5CE6), Color(0xFF1E45C8)],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B5CE6).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on_rounded, color: Colors.white, size: 13),
            SizedBox(width: 4),
            Text(
              'ANNUAL PRO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2B5CE6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2B5CE6).withValues(alpha: 0.4),
        ),
      ),
      child: const Text(
        'MONTHLY PRO',
        style: TextStyle(
          color: Color(0xFF2B5CE6),
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCustomDetailRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.getTextMuted(isDark),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondary(isDark),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          trailing,
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
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }
}
