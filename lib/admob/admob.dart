import 'package:admob_flutter/admob_flutter.dart';

class AdMobManager {
  static final String bannerAdUnitId = 'ca-app-pub-1587740600496860/5832599963';
  static final String interstitialAdUnitId = 'ca-app-pub-1587740600496860/5026369468';

  static AdmobInterstitial _interstitialAd = AdmobInterstitial(adUnitId: interstitialAdUnitId);

  static AdmobBanner getBanner() {
    return AdmobBanner(
      adUnitId: bannerAdUnitId,
      adSize: AdmobBannerSize.BANNER,
    );
  }

  static void loadInterstitial() {
    _interstitialAd.load();
  }

  static Future<void> showInterstitial() async {
    if (await _interstitialAd.isLoaded ?? false) {
      _interstitialAd.show();
    }
  }

  static void disposeInterstitial() {
    _interstitialAd.dispose();
  }
}
