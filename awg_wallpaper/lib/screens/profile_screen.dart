import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/bookmark_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/glass_container.dart';

import 'subscription_screen.dart';
import 'contact_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'manage_subscription_screen.dart';
import 'auto_wallpaper_settings_screen.dart';

import '../services/auth_service.dart';
import '../providers/auto_wallpaper_provider.dart';
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
            child: Consumer4<BookmarkProvider, SubscriptionProvider,
                ThemeProvider, AutoWallpaperProvider>(
              builder: (context, bookmarkProvider, subscriptionProvider,
                  themeProvider, autoWallpaperProvider, child) {
                final isDark = themeProvider.isDarkMode;
                final isLoggedIn = snapshot.hasData && snapshot.data != null;

                return Stack(
                  children: [
                    // Animated background gradient orbs
                    Positioned(
                      top: -100,
                      right: -50,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100,
                      left: -80,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.purple.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main content
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          // Header
                          _buildHeader(context, isDark),

                          const SizedBox(height: 32),

                          // Avatar & Info
                          _buildUserInfo(context, subscriptionProvider, isDark),

                          const SizedBox(height: 32),

                          // Stats Cards
                          _buildStatsCards(
                              bookmarkProvider, subscriptionProvider, isDark),

                          const SizedBox(height: 24),

                          // Pro Banner
                          if (!subscriptionProvider.isPro)
                            _buildProButton(context),

                          const SizedBox(height: 24),

                          // PRO FEATURES section
                          _buildSettingsGroup(
                            title: 'PRO FEATURES',
                            isDark: isDark,
                            children: [
                              _buildProFeatureTile(
                                icon: Icons.auto_awesome_rounded,
                                title: 'Auto Wallpaper',
                                subtitle: subscriptionProvider.isPro
                                    ? (autoWallpaperProvider.isEnabled
                                        ? 'Active • ${autoWallpaperProvider.getIntervalName(autoWallpaperProvider.interval)}'
                                        : 'Schedule automatic changes')
                                    : 'PRO Feature - Upgrade to unlock',
                                iconColor: Colors.purple,
                                gradientColors: [
                                  Colors.purple.withValues(alpha: 0.2),
                                  Colors.deepPurple.withValues(alpha: 0.1),
                                ],
                                isDark: isDark,
                                showLock: !subscriptionProvider.isPro,
                                onTap: () {
                                  if (subscriptionProvider.isPro) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AutoWallpaperSettingsScreen(),
                                      ),
                                    );
                                  } else {
                                    _showProRequiredDialog(context);
                                  }
                                },
                              ),
                              _buildProFeatureTile(
                                icon: Icons.brightness_6_rounded,
                                title: 'Day/Night Mode',
                                subtitle: subscriptionProvider.isPro
                                    ? (autoWallpaperProvider.isDayNightEnabled
                                        ? 'Active • Smart switching'
                                        : 'Auto switch based on time')
                                    : 'PRO Feature - Upgrade to unlock',
                                iconColor: Colors.orange,
                                gradientColors: [
                                  Colors.orange.withValues(alpha: 0.2),
                                  Colors.amber.withValues(alpha: 0.1),
                                ],
                                isDark: isDark,
                                showLock: !subscriptionProvider.isPro,
                                onTap: () {
                                  if (subscriptionProvider.isPro) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AutoWallpaperSettingsScreen(),
                                      ),
                                    );
                                  } else {
                                    _showProRequiredDialog(context);
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // PREFERENCES section
                          _buildSettingsGroup(
                            title: 'PREFERENCES',
                            isDark: isDark,
                            children: [
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
                                subtitle: 'Free up storage space',
                                isDark: isDark,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Cache cleared!')),
                                  );
                                },
                              ),

                              // Logout Button
                              if (isLoggedIn)
                                _buildSettingsTile(
                                  icon: Icons.logout_rounded,
                                  title: 'Logout',
                                  subtitle: 'Sign out of your account',
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
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await authService.signOut();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Logged out successfully')),
                                        );
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // SUPPORT section
                          _buildSettingsGroup(
                            title: 'SUPPORT',
                            isDark: isDark,
                            children: [
                              _buildSettingsTile(
                                icon: Icons.star_border_rounded,
                                title: 'Rate App',
                                subtitle: 'Share your feedback',
                                onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => const RatingDialog()),
                              ),
                              _buildSettingsTile(
                                icon: Icons.mail_outline_rounded,
                                title: 'Contact Us',
                                subtitle: 'Get help and support',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ContactUsScreen())),
                              ),
                              _buildSettingsTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Privacy Policy',
                                subtitle: 'View privacy policy',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen())),
                              ),
                              _buildSettingsTile(
                                icon: Icons.description_outlined,
                                title: 'Terms of Service',
                                subtitle: 'View terms and conditions',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsConditionsScreen())),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'Version 3.0.15',
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 70),
                        ],
                      ),
                    ),
                  ],
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
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (Navigator.canPop(context))
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(isDark).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.getSurfaceVariant(isDark)),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppTheme.getTextPrimary(isDark),
                    size: 20,
                  ),
                ),
              ),
            ),
          Center(
            child: Text(
              'PROFILE',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(isDark),
                    letterSpacing: 2,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
      BuildContext context, SubscriptionProvider provider, bool isDark) {
    final user = AuthService().currentUser;
    final isLoggedIn = user != null;

    return Column(
      children: [
        // Avatar with glow effect
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (provider.isPro ? AppTheme.gold : AppTheme.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Avatar
            Container(
              width: 110,
              height: 110,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: provider.isPro
                      ? [AppTheme.gold, const Color(0xFFFFB700)]
                      : [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkSurface,
                ),
                child: isLoggedIn && user.photoURL != null
                    ? ClipOval(
                        child: Image.network(user.photoURL!, fit: BoxFit.cover))
                    : Icon(
                        provider.isPro
                            ? Icons.workspace_premium_rounded
                            : Icons.person_rounded,
                        size: 55,
                        color:
                            provider.isPro ? AppTheme.gold : AppTheme.primary,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          isLoggedIn ? (user.displayName ?? 'User') : 'Guest User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoggedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: provider.isPro
                  ? const LinearGradient(
                      colors: [AppTheme.gold, Color(0xFFFFB700)],
                    )
                  : null,
              color: provider.isPro ? null : AppTheme.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(20),
              boxShadow: provider.isPro
                  ? [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isPro)
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.black,
                    size: 14,
                  ),
                if (provider.isPro) const SizedBox(width: 4),
                Text(
                  provider.isPro ? 'PREMIUM MEMBER' : 'FREE ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        provider.isPro ? Colors.black : AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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

  Widget _buildStatsCards(BookmarkProvider bookmarkProvider,
      SubscriptionProvider subscriptionProvider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Saved',
              '${bookmarkProvider.bookmarkCount}',
              Icons.favorite_rounded,
              [
                AppTheme.primary.withValues(alpha: 0.2),
                AppTheme.primary.withValues(alpha: 0.05),
              ],
              AppTheme.primary,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Plan',
              subscriptionProvider.isPro ? 'PRO' : 'Free',
              subscriptionProvider.isPro
                  ? Icons.workspace_premium_rounded
                  : Icons.account_circle_rounded,
              subscriptionProvider.isPro
                  ? [
                      AppTheme.gold.withValues(alpha: 0.2),
                      AppTheme.gold.withValues(alpha: 0.05),
                    ]
                  : [
                      AppTheme.darkSurfaceVariant,
                      AppTheme.darkSurface,
                    ],
              subscriptionProvider.isPro ? AppTheme.gold : AppTheme.textMuted,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      List<Color> gradientColors, Color iconColor, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      blur: 20,
      opacity: 0.1,
      color: iconColor,
      border: Border.all(
        color: iconColor.withValues(alpha: 0.3),
        width: 1,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openSubscription(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.gold, Color(0xFFFFB700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.black, size: 24),
              SizedBox(width: 12),
              Text(
                'UPGRADE TO PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
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
          padding: const EdgeInsets.only(left: 32, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondary(isDark).withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            blur: 25,
            opacity: isDark ? 0.05 : 0.4,
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border.all(
              color: (isDark ? AppTheme.darkSurfaceVariant : Colors.white)
                  .withValues(alpha: 0.3),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...{
                  children[i],
                  if (i != children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 68,
                      color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.3),
                    ),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required List<Color> gradientColors,
    VoidCallback? onTap,
    bool isDark = false,
    bool showLock = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.getTextSecondary(isDark).withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ),
      trailing: showLock
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.lock_rounded,
                    color: AppTheme.gold,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? AppTheme.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  color:
                      AppTheme.getTextSecondary(isDark).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.5),
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
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.gold, Color(0xFFFFB700)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PRO Feature',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This feature is exclusive to PRO members. Upgrade now to unlock Auto Wallpaper and Day/Night Mode!',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openSubscription(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Upgrade to PRO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
