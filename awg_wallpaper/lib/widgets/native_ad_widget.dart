import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/ad_helper.dart';

class NativeAdWidget extends StatefulWidget {
  final double height;

  const NativeAdWidget({
    super.key,
    this.height = 300,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  bool _adLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    // If the user just became Pro, immediately tear down any loaded/loading ad.
    if (subscriptionProvider.isPro) {
      _disposeAd();
      return;
    }

    // Only start loading once to avoid re-creating the ad on every rebuild.
    if (!_adLoadStarted) {
      _adLoadStarted = true;
      _loadAd();
    }
  }

  void _loadAd() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        // Use Google's built-in medium template (no native code required)
        templateType: TemplateType.medium,
        mainBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        cornerRadius: 15.0, // Match wallpaper card corner radius
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF2B5CE6),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : const Color(0xFF1E293B),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white70 : const Color(0xFF64748B),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white60 : const Color(0xFF94A3B8),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('$NativeAd loaded successfully.');
          if (!mounted) return;
          // Final Pro check: if the user became Pro while the ad was loading,
          // dispose it immediately instead of showing it.
          final isPro = Provider.of<SubscriptionProvider>(context, listen: false).isPro;
          if (isPro) {
            ad.dispose();
            _nativeAd = null;
            return;
          }
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('$NativeAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAdIsLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  void _disposeAd() {
    if (_nativeAd != null || _nativeAdIsLoaded) {
      _nativeAd?.dispose();
      _nativeAd = null;
      _adLoadStarted = false;
      if (mounted) {
        setState(() {
          _nativeAdIsLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // listen: true so we react when isPro changes (e.g. subscription loads async).
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    if (subscriptionProvider.isPro) {
      // Ensure we clean up any ad that may have already loaded.
      if (_nativeAd != null || _nativeAdIsLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _disposeAd());
      }
      return const SizedBox.shrink();
    }

    if (_nativeAdIsLoaded && _nativeAd != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return const SizedBox.shrink();
  }
}

