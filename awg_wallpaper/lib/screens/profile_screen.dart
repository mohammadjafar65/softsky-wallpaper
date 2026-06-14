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
import 'auth/register_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loginPopupShown = false;
  @override
  void initState() {
    super.initState();
    // Delay popup for 8 seconds after screen opens
    Future.delayed(const Duration(seconds: 8), _maybeShowLoginPopup);
  }

  void _maybeShowLoginPopup() {
    if (!mounted || _loginPopupShown) return;
    final isLoggedIn = AuthService().isLoggedIn;
    if (!isLoggedIn) {
      _loginPopupShown = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline_rounded, size: 38, color: Colors.white),
                const SizedBox(height: 14),
                Text('Sign in or Create Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Sync favorites, access premium features, and more.',
                    style: TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
                        },
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

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
                    // ...existing code...
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
                              Colors.blueGrey.withValues(alpha: 0.18),
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

                          const SizedBox(height: 16),

                          // Profile hero
                          _buildProfileHero(
                            context,
                            subscriptionProvider,
                            isDark,
                            isLoggedIn,
                          ),

                          const SizedBox(height: 24),

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
                            title: 'Pro Features',
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
                                iconColor: AppTheme.primary,
                                gradientColors: [
                                  AppTheme.primary.withValues(alpha: 0.2),
                                  AppTheme.primary.withValues(alpha: 0.08),
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
                                  Colors.amber.withValues(alpha: 0.08),
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
                            title: 'Preferences',
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
                            title: 'Support',
                            isDark: isDark,
                            children: [
                              _buildSettingsTile(
                                icon: Icons.star_border_rounded,
                                title: 'Rate App',
                                subtitle: 'Share your feedback',
                                isDark: isDark,
                                onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => const RatingDialog()),
                              ),
                              _buildSettingsTile(
                                icon: Icons.mail_outline_rounded,
                                title: 'Contact Us',
                                subtitle: 'Get help and support',
                                isDark: isDark,
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
                                isDark: isDark,
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
                                isDark: isDark,
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
                            'Version 3.0.23',
                            style: TextStyle(
                              color: AppTheme.getTextMuted(isDark)
                                  .withValues(alpha: 0.65),
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
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(isDark).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.getTextPrimary(isDark),
                  size: 20,
                ),
              ),
            ),
          const Spacer(),
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(isDark),
                  letterSpacing: 0.2,
                  fontSize: 21,
                ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, SubscriptionProvider provider,
      bool isDark, bool isLoggedIn) {
    final user = AuthService().currentUser;
    final displayName = isLoggedIn ? (user?.displayName ?? 'User') : 'Guest User';
    final subtitle = isLoggedIn
        ? (user?.email ?? 'Signed in account')
        : 'Sign in to sync your likes and premium access';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: 24,
        blur: 20,
        opacity: isDark ? 0.08 : 0.4,
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(
          color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: provider.isPro
                      ? [AppTheme.gold, const Color(0xFFFFE28A)]
                      : [
                          AppTheme.primary.withValues(alpha: 0.95),
                          AppTheme.primary.withValues(alpha: 0.7),
                        ],
                ),
              ),
              child: Icon(
                provider.isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.person_rounded,
                size: 34,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(isDark),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(isDark)
                          .withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (provider.isPro ? AppTheme.gold : AppTheme.primary)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      provider.isPro ? 'PRO MEMBER' : 'FREE PLAN',
                      style: TextStyle(
                        color: provider.isPro ? AppTheme.gold : AppTheme.primary,
                        fontSize: 10,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoggedIn)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Sign in'),
              ),
          ],
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        blur: 16,
        opacity: isDark ? 0.08 : 0.28,
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
          width: 1,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 26,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                'Upgrade to PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.4,
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
          padding: const EdgeInsets.only(left: 24, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondary(isDark).withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: 22,
            blur: 22,
            opacity: isDark ? 0.06 : 0.36,
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border.all(
              color: (isDark ? AppTheme.darkSurfaceVariant : Colors.white)
                  .withValues(alpha: 0.55),
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
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: ListTile(
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
        style: TextStyle(
          color: AppTheme.getTextPrimary(isDark),
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
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: ListTile(
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
        style: TextStyle(
          color: AppTheme.getTextPrimary(isDark),
          fontSize: 15,
          fontWeight: FontWeight.w600,
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
