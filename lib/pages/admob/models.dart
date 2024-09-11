import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleAdmob {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3805485538389573/8680759580';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3805485538389573/9008611388';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3805485538389573/5644081441';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}

class AdManager {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  Widget? showBannerAd() {
    if (_bannerAd != null) {
      return SizedBox(
        height: AdSize.largeBanner.height.toDouble(),
        width: AdSize.largeBanner.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      loadBannerAd();
      return null;
    }
  }

  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: GoogleAdmob.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print("Banner Ad loaded.");
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          print('Failed to load banner ad: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  void showInterstitialAd({Function? onAdDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          if (onAdDismissed != null) {
            onAdDismissed();
          }
        },
      );
      _interstitialAd!.show();
    } else {
      loadInterstitialAd();
    }
  }

  void loadInterstitialAd() {
    if (_interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: GoogleAdmob.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          print("Interstitial Ad loaded.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          print('Failed to load interstitial ad: $error');
        },
      ),
    );
  }

  void showRewardedAd({Function? onAdDismissed, Function? onUserEarnedReward}) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          if (onAdDismissed != null) {
            onAdDismissed();
          }
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (Ad ad, RewardItem reward) {
        if (onUserEarnedReward != null) {
          onUserEarnedReward();
        }
        print('User earned reward: $reward');
      });
    } else {
      loadRewardedAd();
    }
  }

  void loadRewardedAd() {
    if (_rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: GoogleAdmob.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          print("Rewarded Ad loaded.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          print('Failed to load rewarded ad: $error');
        },
      ),
    );
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  bool isRewardedAdReady() => _rewardedAd != null;
  bool isInterstitialAdReady() => _interstitialAd != null;
}
