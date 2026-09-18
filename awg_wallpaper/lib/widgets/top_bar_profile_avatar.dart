import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../utils/creator_helper.dart';

class TopBarProfileAvatar extends StatelessWidget {
  final double radius;

  const TopBarProfileAvatar({
    super.key,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = AuthService().isLoggedIn;
        final photoUrl = AuthService().currentUser?.photoURL;
        final size = radius * 2;

        return GestureDetector(
          onTap: () => CreatorHelper.openProfile(context),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: ClipOval(
              child: isLoggedIn && photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                          size: 22,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
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

