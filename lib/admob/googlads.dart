import 'dart:math';
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

  final List<String> _adUnitIds = [
    'ca-app-pub-1587740600496860/8068871053',
    'ca-app-pub-1587740600496860/8713521277', // Tambahkan unit iklan lain di sini
    'ca-app-pub-1587740600496860/8068871053',
    'ca-app-pub-1587740600496860/9966553889',
    'ca-app-pub-1587740600496860/5951626568',
    'ca-app-pub-1587740600496860/4638544897',
    'ca-app-pub-1587740600496860/8653472215', // Tambahkan unit iklan lain di sini
  ];

  String get _randomAdUnitId {
    final random = Random();
    return _adUnitIds[random.nextInt(_adUnitIds.length)];
  }

  void loadInterstitialAd() {
    _interstitialAd?.dispose();
    _isInterstitialAdReady = false;

    InterstitialAd.load(
      adUnitId: _randomAdUnitId,
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
    } else {
      onAdFailed();
    }
  }

  void resetInterstitialAdStatus() {
    _isInterstitialAdReady = false;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
