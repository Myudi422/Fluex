import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() {
    return _instance;
  }

  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void loadInterstitialAd() {
    _interstitialAd?.dispose();
    _isInterstitialAdReady = false;

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-1587740600496860/2449076463',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd({
    required Function onAdDismissed,
    required Function onAdFailed,
  }) {
    if (_isInterstitialAdReady) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          onAdFailed();
        },
      );

      _interstitialAd!.show();
    }
  }

  void resetInterstitialAdStatus() {
    _isInterstitialAdReady = false;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
