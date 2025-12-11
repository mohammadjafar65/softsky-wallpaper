import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

enum AdType { banner, interstitial, native }

class AdBanner extends StatelessWidget {
  final AdType adType;
  final VoidCallback? onClose;
  
  const AdBanner({
    super.key,
    this.adType = AdType.banner,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    switch (adType) {
      case AdType.banner:
        return _buildBannerAd();
      case AdType.interstitial:
        return _buildInterstitialAd();
      case AdType.native:
        return _buildNativeAd();
    }
  }
  
  Widget _buildBannerAd() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceVariant.withOpacity(0.9),
            AppTheme.surface.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.3),
                      AppTheme.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remove Ads with Pro',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Upgrade to enjoy ad-free experience',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInterstitialAd() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.accent.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.gold, Color(0xFFFFB700)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.black,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Go Pro Today!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Unlock all wallpapers, remove ads, and get new content first!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNativeAd() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceVariant, // Fixed: was surfaceLight
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.3),
                      AppTheme.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sponsored',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Premium Wallpapers',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Discover thousands of stunning wallpapers. Upgrade to Pro for the best experience!',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryVariant],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Learn More',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simulated ad loading widget
class AdLoadingPlaceholder extends StatefulWidget {
  const AdLoadingPlaceholder({super.key});

  @override
  State<AdLoadingPlaceholder> createState() => _AdLoadingPlaceholderState();
}

class _AdLoadingPlaceholderState extends State<AdLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(_controller.value * 3, 0),
              colors: [
                AppTheme.surfaceVariant,
                Colors.white, // Fixed: was surfaceLight
                AppTheme.surfaceVariant,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
