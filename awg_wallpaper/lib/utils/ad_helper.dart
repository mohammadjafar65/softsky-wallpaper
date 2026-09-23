import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // Production AdMob unit IDs for publisher ca-app-pub-4871390051047157
  // In debug mode, Google's official test IDs are used to avoid invalid traffic.
  static String get nativeAdUnitId {
    if (kDebugMode) {
      // Google's official test native ad ID
      return 'ca-app-pub-3940256099942544/2247696110';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4871390051047157/3158766287';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4871390051047157/3158766287';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      // Google's official test interstitial ad ID
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4871390051047157/6613977324';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4871390051047157/6613977324';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  /// Pre-loads an interstitial ad for later display.
  /// Pass [isPro] = true to skip loading entirely (Pro users never see ads).
  static void loadInterstitialAd({bool isPro = false}) {
    if (isPro) return; // Never pre-load for Pro users
    if (_isInterstitialAdLoading || _interstitialAd != null) return;

    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd loaded.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows an interstitial ad then calls [onAdClosed] when dismissed.
  /// If [isPro] is true, [onAdClosed] is called immediately without any ad —
  /// ensuring Pro subscribers always skip ads seamlessly regardless of call site.
  static Future<void> showInterstitialAd({
    required VoidCallback onAdClosed,
    bool isPro = false,
  }) async {
    // Pro users: proceed immediately without ever showing an ad.
    if (isPro) {
      onAdClosed();
      return;
    }

    if (_interstitialAd == null) {
      onAdClosed();
      loadInterstitialAd(); // Pre-load for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        onAdClosed();
        loadInterstitialAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onAdClosed();
        loadInterstitialAd(); // Try again for next time
      },
    );

    await _interstitialAd!.show();
  }
}
