import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediasaver/pages/admob/models.dart';

class AdsPage extends StatefulWidget {
  const AdsPage({super.key});

  @override
  State<AdsPage> createState() => AdsState();
}

class AdsState extends State<AdsPage> {
  final adManager = AdManager();
  int _counter = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _preloadAds();
    _startCountdown();
  }

  void _preloadAds() {
    adManager.loadRewardedAd();
    adManager.loadInterstitialAd();
  }

  void _startCountdown() {
    _counter = 3;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_counter > 0) {
        setState(() {
          _counter--;
        });
      } else {
        timer.cancel();
        _showAds();
      }
    });
  }

  void _showAds() {
    if (adManager.isRewardedAdReady()) {
      adManager.showRewardedAd(
        onAdDismissed: () {
          if (adManager.isInterstitialAdReady()) {
            adManager.showInterstitialAd();
          }
        },
        onUserEarnedReward: () {
          print("User earned reward");
        },
      );
    } else if (adManager.isInterstitialAdReady()) {
      adManager.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("See why? in $_counter"),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
