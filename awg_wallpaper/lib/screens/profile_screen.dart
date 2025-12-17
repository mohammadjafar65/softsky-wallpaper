import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/bookmark_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/ad_banner.dart';
import '../widgets/rating_dialog.dart';
import 'subscription_screen.dart';
import 'contact_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'manage_subscription_screen.dart';

import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          return SafeArea(
            bottom: false,
            child: Consumer3<BookmarkProvider, SubscriptionProvider,
                ThemeProvider>(
              builder: (context, bookmarkProvider, subscriptionProvider,
                  themeProvider, child) {
                final isDark = themeProvider.isDarkMode;
                final isLoggedIn = snapshot.hasData && snapshot.data != null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context, isDark),

                      const SizedBox(height: 20),

                      // Avatar & Info
                      _buildUserInfo(context, subscriptionProvider, isDark),

                      const SizedBox(height: 30),

                      // Stats
                      _buildStats(
                          bookmarkProvider, subscriptionProvider, isDark),

                      const SizedBox(height: 30),

                      // Pro Banner
                      if (!subscriptionProvider.isPro) _buildProButton(context),

                      const SizedBox(height: 20),

                      // Settings Groups
                      _buildSettingsGroup(
                        title: 'PREFERENCES',
                        isDark: isDark,
                        children: [
                          // Dark Mode Toggle
                          _buildSettingsTile(
                            icon: Icons.dark_mode_rounded,
                            title: 'Dark Mode',
                            subtitle: subscriptionProvider.isPro
                                ? null
                                : 'PRO Feature',
                            iconColor: subscriptionProvider.isPro
                                ? (isDark ? Colors.purple : Colors.deepPurple)
                                : AppTheme.textMuted,
                            isDark: isDark,
                            trailing: subscriptionProvider.isPro
                                ? Switch(
                                    value: isDark,
                                    onChanged: (val) {
                                      themeProvider.setDarkMode(val,
                                          isPro: true);
                                    },
                                    activeColor: AppTheme.primary,
                                  )
                                : GestureDetector(
                                    onTap: () =>
                                        _showProRequiredDialog(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.gold,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock,
                                              size: 12, color: Colors.black),
                                          SizedBox(width: 4),
                                          Text('PRO',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black)),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          if (subscriptionProvider.isPro)
                            _buildSettingsTile(
                              icon: Icons.card_membership_rounded,
                              title: 'Manage Subscription',
                              subtitle: 'Active',
                              iconColor: AppTheme.gold,
                              isDark: isDark,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageSubscriptionScreen())),
                            ),
                          _buildSettingsTile(
                            icon: Icons.delete_outline_rounded,
                            title: 'Clear Cache',
                            isDark: isDark,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cache cleared!')),
                              );
                            },
                          ),

                          // Logout Button
                          if (isLoggedIn)
                            _buildSettingsTile(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              iconColor: Colors.redAccent,
                              isDark: isDark,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text(
                                        'Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await authService.signOut();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Logged out successfully')),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSettingsGroup(
                        title: 'SUPPORT',
                        children: [
                          _buildSettingsTile(
                            icon: Icons.star_border_rounded,
                            title: 'Rate App',
                            onTap: () => showDialog(
                                context: context,
                                builder: (_) => const RatingDialog()),
                          ),
                          _buildSettingsTile(
                            icon: Icons.mail_outline_rounded,
                            title: 'Contact Us',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ContactUsScreen())),
                          ),
                          _buildSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PrivacyPolicyScreen())),
                          ),
                          _buildSettingsTile(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const TermsConditionsScreen())),
                          ),
                        ],
                      ),

                      // if (!subscriptionProvider.isPro)
                      //   const Padding(
                      //     padding: EdgeInsets.all(20),
                      //     child: AdBanner(adType: AdType.native),
                      //   ),

                      const SizedBox(height: 20),

                      Text(
                        'Version 3.0.2',
                        style: TextStyle(
                          color: AppTheme.textMuted.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 70),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
                letterSpacing: 1,
              ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(
      BuildContext context, SubscriptionProvider provider, bool isDark) {
    final user = AuthService().currentUser;
    final isLoggedIn = user != null;

    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: provider.isPro
                  ? [AppTheme.gold, const Color(0xFFFFB700)]
                  : [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (provider.isPro ? AppTheme.gold : AppTheme.primary)
                    .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.darkSurface : Colors.white,
            ),
            child: isLoggedIn && user.photoURL != null
                ? ClipOval(
                    child: Image.network(user.photoURL!, fit: BoxFit.cover))
                : Icon(
                    provider.isPro
                        ? Icons.workspace_premium_rounded
                        : Icons.person_rounded,
                    size: 50,
                    color: provider.isPro ? AppTheme.gold : AppTheme.primary,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isLoggedIn ? (user.displayName ?? 'User') : 'Guest User',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if (isLoggedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: provider.isPro ? AppTheme.gold : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              provider.isPro ? 'PREMIUM MEMBER' : 'FREE ACCOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: provider.isPro ? Colors.black : AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Sign In / Register',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(BookmarkProvider bookmarkProvider,
      SubscriptionProvider subscriptionProvider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem('Saved', '${bookmarkProvider.bookmarkCount}', isDark),
        _buildDivider(isDark),
        // _buildStatItem('Downloads', '0', isDark),
        // _buildDivider(isDark),
        _buildStatItem(
            'Plan', subscriptionProvider.isPro ? 'PRO' : 'Free', isDark),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.getSurfaceVariant(isDark),
    );
  }

  Widget _buildProButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openSubscription(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.gold, Color(0xFFFFB700)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star_rounded, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'UPGRADE TO PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
      {required String title,
      required List<Widget> children,
      bool isDark = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 36, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondary(isDark),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getSurfaceVariant(isDark)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 56,
                    color: AppTheme.getSurfaceVariant(isDark),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    bool isDark = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? AppTheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.getTextPrimary(isDark),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.getTextSecondary(isDark),
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.getTextMuted(isDark),
            size: 20,
          ),
    );
  }

  void _openSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  void _showProRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.star_rounded, color: AppTheme.gold),
            SizedBox(width: 8),
            Text('Pro Feature'),
          ],
        ),
        content: const Text(
          'Dark mode is available exclusively for Pro subscribers. Upgrade now to unlock this feature!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
