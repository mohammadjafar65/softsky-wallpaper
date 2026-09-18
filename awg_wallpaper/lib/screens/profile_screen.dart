import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/bookmark_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';

import 'subscription_screen.dart';
import 'manage_subscription_screen.dart';
import 'app_settings_screen.dart';

import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/creator_helper.dart';
import 'community/upload_wallpaper_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

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
                final isCreator = CreatorHelper.isCreator(context);

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
                            isCreator,
                          ),

                          if (!isCreator) ...[
                            const SizedBox(height: 18),
                            _buildBecomeCreatorBanner(context, isDark),
                          ],

                          if (isCreator) ...[
                            const SizedBox(height: 18),
                            _buildCreatorStudioCard(context, isDark),
                          ],

                          const SizedBox(height: 24),

                          // Stats Cards
                          _buildStatsCards(
                              context,
                              bookmarkProvider, subscriptionProvider, isDark),

                          const SizedBox(height: 24),

                          // Pro Banner
                          if (!subscriptionProvider.isPro)
                            _buildProButton(context),

                          const SizedBox(height: 24),

                          // CREATOR STUDIO section (for creators)
                          if (isCreator) ...[
                            _buildSettingsGroup(
                              title: 'Creator Studio',
                              isDark: isDark,
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.person_pin_circle_outlined,
                                  title: 'Creator Profile',
                                  subtitle: 'View portfolio, followers & posts',
                                  iconColor: const Color(0xFFE94057),
                                  isDark: isDark,
                                  trailingBadge: 'CREATOR',
                                  onTap: () =>
                                      CreatorHelper.openCreatorProfile(context),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.add_photo_alternate_outlined,
                                  title: 'Upload Wallpaper',
                                  subtitle: 'Share artwork with the community',
                                  iconColor: AppTheme.primary,
                                  isDark: isDark,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const UploadWallpaperScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // PREFERENCES section
                          _buildSettingsGroup(
                            title: 'Preferences',
                            isDark: isDark,
                            children: [
                              _buildSettingsTile(
                                icon: Icons.settings_outlined,
                                title: 'App Settings',
                                subtitle: 'Theme, notifications, cache & legal',
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AppSettingsScreen()),
                                ),
                              ),
                              if (subscriptionProvider.isPro)
                                _buildSettingsTile(
                                  icon: Icons.card_membership_rounded,
                                  title: 'Manage Subscription',
                                  subtitle: () {
                                    final plan = subscriptionProvider.getPlanName(subscriptionProvider.currentPlan);
                                    final expiry = subscriptionProvider.expiryDate;
                                    final isLifetime = subscriptionProvider.currentPlan == SubscriptionPlan.lifetime;
                                    if (isLifetime) return '$plan · Lifetime access';
                                    if (expiry != null) {
                                      return '$plan · Renews ${expiry.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][expiry.month - 1]}';
                                    }
                                    return plan;
                                  }(),
                                  iconColor: AppTheme.gold,
                                  isDark: isDark,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ManageSubscriptionScreen())),
                                )
                              else
                                _buildSettingsTile(
                                  icon: Icons.workspace_premium_rounded,
                                  title: 'Upgrade to Pro',
                                  subtitle: 'Unlock 1000+ wallpapers & features',
                                  iconColor: AppTheme.gold,
                                  isDark: isDark,
                                  trailingBadge: 'PRO',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SubscriptionScreen())),
                                ),
                              if (!isCreator)
                                _buildSettingsTile(
                                  icon: Icons.palette_outlined,
                                  title: 'Become a Creator',
                                  subtitle: 'Publish wallpapers & showcase your art',
                                  iconColor: AppTheme.primary,
                                  isDark: isDark,
                                  trailingBadge: 'JOIN',
                                  onTap: () =>
                                      CreatorHelper.showBecomeCreatorSheet(context),
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ACCOUNT section — logout
                          if (isLoggedIn)
                            _buildSettingsGroup(
                              title: 'Account',
                              isDark: isDark,
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.logout_rounded,
                                  title: 'Logout',
                                  subtitle: 'Sign out of your account',
                                  iconColor: Colors.redAccent,
                                  isDark: isDark,
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppTheme.getSurface(isDark),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: Text(
                                          'Logout',
                                          style: TextStyle(
                                            color: AppTheme.getTextPrimary(isDark),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        content: Text(
                                          'Are you sure you want to sign out?',
                                          style: TextStyle(
                                            color: AppTheme.getTextSecondary(isDark),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: AppTheme.getTextMuted(isDark),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Logout',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                                              content: Text('Logged out successfully')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),

                          const SizedBox(height: 32),

                          Text(
                            'Version 3.0.28',
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
            )
          else
            const SizedBox(width: 40),
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
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ),
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
                Icons.settings_outlined,
                color: AppTheme.getTextPrimary(isDark),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, SubscriptionProvider provider,
      bool isDark, bool isLoggedIn, bool isCreator) {
    final user = AuthService().currentUser;
    final displayName = isLoggedIn ? (user?.displayName ?? 'User') : 'Guest User';
    final subtitle = isLoggedIn
        ? (user?.email ?? 'Signed in account')
        : 'Sign in to sync your likes and premium access';
    final photoUrl = user?.photoURL;

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
              child: ClipOval(
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          provider.isPro
                              ? Icons.workspace_premium_rounded
                              : Icons.person_rounded,
                          size: 34,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      )
                    : Icon(
                        provider.isPro
                            ? Icons.workspace_premium_rounded
                            : Icons.person_rounded,
                        size: 34,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => provider.isPro
                                ? const ManageSubscriptionScreen()
                                : const SubscriptionScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (provider.isPro
                                    ? AppTheme.gold
                                    : AppTheme.primary)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: (provider.isPro
                                      ? AppTheme.gold
                                      : AppTheme.primary)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.isPro ? 'PRO MEMBER' : 'FREE PLAN',
                                style: TextStyle(
                                  color: provider.isPro
                                      ? AppTheme.gold
                                      : AppTheme.primary,
                                  fontSize: 10,
                                  letterSpacing: 0.7,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                provider.isPro
                                    ? Icons.manage_accounts_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: provider.isPro
                                    ? AppTheme.gold
                                    : AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isCreator)
                        GestureDetector(
                          onTap: () => CreatorHelper.openCreatorProfile(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE94057)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'CREATOR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    letterSpacing: 0.7,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

  Widget _buildBecomeCreatorBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1C2C),
              Color(0xFF928DAB),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.palette_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 12, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                'CREATOR COLLECTIVE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Become a Creator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Publish wallpapers to our community, get featured, and build your follower base.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            CreatorHelper.showBecomeCreatorSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.brush_rounded,
                                size: 18, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Join as Creator',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorStudioCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1654),
              Color(0xFF4A154B),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'CREATOR STUDIO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => CreatorHelper.openCreatorProfile(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Creator Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your wallpaper portfolio, upload new art, and check your audience stats.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            CreatorHelper.openCreatorProfile(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.person_outline_rounded,
                            size: 18, color: Colors.black),
                        label: const Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadWallpaperScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Colors.white54, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_rounded,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'Upload Art',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, BookmarkProvider bookmarkProvider,
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
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => subscriptionProvider.isPro
                      ? const ManageSubscriptionScreen()
                      : const SubscriptionScreen(),
                ),
              ),
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
              colors: [AppTheme.primary, AppTheme.primaryVariant],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Upgrade to PRO',
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    String? trailingBadge,
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
          (trailingBadge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.gold, Color(0xFFFFB700)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.black,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trailingBadge,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.getTextMuted(isDark).withValues(alpha: 0.5),
                size: 20,
              )),
      ),
    );
  }

  void _openSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }
}
