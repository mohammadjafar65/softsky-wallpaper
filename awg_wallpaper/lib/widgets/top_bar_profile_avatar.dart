import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../providers/community_provider.dart';
import '../models/community_user.dart';
import '../screens/community/community_profile_screen.dart';
import '../screens/auth/login_screen.dart';

class TopBarProfileAvatar extends StatelessWidget {
  final double radius;

  const TopBarProfileAvatar({
    super.key,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = AuthService().isLoggedIn;
        final photoUrl = AuthService().currentUser?.photoURL;
        final size = radius * 2;

        // When user is NOT logged in:
        // Show account icon styled identically to other topbar circular buttons
        if (!isLoggedIn) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          );
        }

        // When user IS logged in:
        // Show user profile photo and navigate to user collective profile
        return GestureDetector(
          onTap: () {
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
                : (communityProvider.trendingPosts.isNotEmpty
                    ? communityProvider.trendingPosts.first.author
                    : null);

            final int targetUserId =
                myUser?.id ?? AuthService().backendUserId ?? 1;
            final initialUser = myUser ??
                CommunityUser(
                  id: targetUserId,
                  displayName: authUser?.displayName ?? 'My Profile',
                  photoUrl: authUser?.photoURL,
                  bio: 'Wallpaper Creator',
                  followersCount: 0,
                  followingCount: 0,
                  postsCount: 0,
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
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
