import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/community_user.dart';
import '../providers/community_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/community/community_profile_screen.dart';
import '../screens/community/upload_wallpaper_screen.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';

/// Helper utility for handling Creator vs Normal User profile state and navigation.
class CreatorHelper {
  /// Checks whether the user is a creator.
  /// A user is considered a creator if:
  /// 1. 'is_creator' is set to true in Hive settings box, OR
  /// 2. User has published community posts (in CommunityProvider.myPosts), OR
  /// 3. Backend user object marks them as creator or role == 'creator'.
  static bool isCreator(BuildContext context) {
    if (!AuthService().isLoggedIn) return false;

    // 1. Check local persistent setting
    try {
      final box = Hive.box('settings');
      if (box.get('is_creator', defaultValue: false) == true) {
        return true;
      }
    } catch (_) {}

    // 2. Check backend user record
    final backendUser = AuthService().backendUser;
    if (backendUser != null) {
      if (backendUser['is_creator'] == true ||
          backendUser['role'] == 'creator' ||
          (backendUser['postsCount'] is int && backendUser['postsCount'] > 0)) {
        return true;
      }
    }

    // 3. Check community posts published by user
    try {
      final cp = context.read<CommunityProvider>();
      if (cp.myPosts.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Sets creator status locally in Hive settings.
  static Future<void> setCreatorStatus(bool status) async {
    try {
      final box = Hive.box('settings');
      await box.put('is_creator', status);
    } catch (e) {
      debugPrint('Error updating is_creator: ');
    }
  }

  /// Opens the correct profile screen based on creator status:
  /// - If user is a creator -> opens Creator Profile (CommunityProfileScreen)
  /// - If user is not a creator -> opens Normal Profile (ProfileScreen)
  static void openProfile(BuildContext context) {
    if (isCreator(context)) {
      openCreatorProfile(context);
    } else {
      openNormalProfile(context);
    }
  }

  /// Opens the normal user profile screen (ProfileScreen)
  static void openNormalProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  /// Opens the creator profile screen (CommunityProfileScreen) for the current user
  static void openCreatorProfile(BuildContext context) {
    final authUser = AuthService().currentUser;
    final communityProvider = context.read<CommunityProvider>();
    CommunityUser? myUser;

    for (final p in [
      ...communityProvider.myPosts,
      ...communityProvider.trendingPosts,
      ...communityProvider.feedPosts
    ]) {
      if (authUser != null &&
          (p.author?.displayName == authUser.displayName ||
              p.author?.photoUrl == authUser.photoURL)) {
        myUser = p.author;
        break;
      }
    }

    myUser ??= communityProvider.myPosts.isNotEmpty
        ? communityProvider.myPosts.first.author
        : null;

    final int targetUserId = myUser?.id ?? AuthService().backendUserId ?? 1;
    final initialUser = myUser ??
        CommunityUser(
          id: targetUserId,
          displayName: authUser?.displayName ?? 'Creator Profile',
          photoUrl: authUser?.photoURL,
          bio: 'Wallpaper Creator',
          followersCount: 0,
          followingCount: 0,
          postsCount: communityProvider.myPosts.length,
          totalDownloads: 0,
          isFollowing: false,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityProfileScreen(
          userId: targetUserId,
          initialUser: initialUser,
          isCurrentUser: true,
        ),
      ),
    );
  }

  /// Shows the 'Become a Creator' bottom sheet modal
  static void showBecomeCreatorSheet(
    BuildContext context, {
    VoidCallback? onBecameCreator,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) =>
          BecomeCreatorBottomSheet(onBecameCreator: onBecameCreator),
    );
  }
}

/// The interactive modal bottom sheet allowing users to become a creator.
class BecomeCreatorBottomSheet extends StatelessWidget {
  final VoidCallback? onBecameCreator;

  const BecomeCreatorBottomSheet({super.key, this.onBecameCreator});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLoggedIn = AuthService().isLoggedIn;

    final cardBg = isDark ? const Color(0xFF18181D) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF4B5563);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding + bottomInset),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header with glowing icon and Close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Become a Creator',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CREATOR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Join the collective, share your wallpaper art & build your audience',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Benefits Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222228)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _buildBenefitItem(
                      icon: Icons.cloud_upload_rounded,
                      title: 'Publish Wallpapers to Millions',
                      subtitle:
                          'Share your 4K & Ultra HD art directly in the Collective feed.',
                      isDark: isDark,
                      iconColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Icons.groups_rounded,
                      title: 'Build Following & Brand',
                      subtitle:
                          'Wallpaper lovers can follow your profile and save your work.',
                      isDark: isDark,
                      iconColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Track Real-Time Downloads',
                      subtitle:
                          'Monitor likes, views, and downloads on every wallpaper you publish.',
                      isDark: isDark,
                      iconColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Get Featured on Trending',
                      subtitle:
                          'High-quality original wallpapers get spotlighted for all users.',
                      isDark: isDark,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Primary CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isLoggedIn) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      return;
                    }

                    // User is logged in: activate creator status and launch upload screen
                    await CreatorHelper.setCreatorStatus(true);
                    onBecameCreator?.call();

                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UploadWallpaperScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLoggedIn
                            ? Icons.add_photo_alternate_rounded
                            : Icons.login_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLoggedIn
                            ? 'Upload Wallpaper & Start Creating'
                            : 'Sign In to Become a Creator',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary action
              if (isLoggedIn) ...[
                TextButton(
                  onPressed: () async {
                    await CreatorHelper.setCreatorStatus(true);
                    onBecameCreator?.call();
                    if (context.mounted) {
                      Navigator.pop(context);
                      CreatorHelper.openCreatorProfile(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Activate Creator Profile Directly',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.65)
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
