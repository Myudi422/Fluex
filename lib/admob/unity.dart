import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class UnityAdManager{
  static const String gameId = "5601846"; // Ganti dengan ID game Unity Ads Anda
  static const String interstitialPlacementId = "flue"; // Ganti dengan ID tempat iklan interstitial Unity Ads Anda

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static void initialize() {
    if (!_isInitialized) {
      UnityAds.init(
        gameId: gameId,
        testMode: false, // Setel ke false di produksi
        onComplete: () {
          print('Unity Ads initialization complete');
        },
        onFailed: (error, message) {
          print('Unity Ads initialization failed: $error $message');
        },
      );
      _isInitialized = true;
    }
  }

  static void loadInterstitialAd() {
    if (_isInitialized) {
      UnityAds.load(placementId: interstitialPlacementId);
    } else {
      print("Unity Ads is not initialized. Please call AdManager.initialize() first.");
    }
  }

  static void showInterstitialAd({required Function(String) onComplete, required Function(String, UnityAdsShowError, String) onFailed}) {
    if (_isInitialized) {
      UnityAds.showVideoAd(
        placementId: interstitialPlacementId,
        onComplete: onComplete,
        onFailed: onFailed,
      );
    } else {
      print("Unity Ads is not initialized. Please call AdManager.initialize() first.");
    }
  }
}