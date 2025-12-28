import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // Replace these with your actual AdMob IDs
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      // Test Native Ad ID
      return 'ca-app-pub-4871390051047157/3158766287';
    } else if (Platform.isIOS) {
      // Test Native Ad ID
      return 'ca-app-pub-4871390051047157/3158766287';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Test Interstitial Ad ID
      return 'ca-app-pub-4871390051047157/6613977324';
    } else if (Platform.isIOS) {
      // Test Interstitial Ad ID
      return 'ca-app-pub-4871390051047157/6613977324';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static void loadInterstitialAd() {
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

  static Future<void> showInterstitialAd(
      {required VoidCallback onAdClosed}) async {
    if (_interstitialAd == null) {
      onAdClosed();
      loadInterstitialAd(); // Load for next time
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
