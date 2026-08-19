import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance =
  RewardedAdService._();

  // Google test rewarded ad unit for Android development.
  // Replace ONLY when preparing the production release.
  static const String testAdUnitId =
      'ca-app-pub-8698720966428005/7178509171';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  Future<void> load() async {
    if (_rewardedAd != null || _isLoading) {
      return;
    }

    _isLoading = true;

    final completer = Completer<void>();

    RewardedAd.load(
      adUnitId: testAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    await completer.future;
  }

  Future<bool> showRewardedAd() async {
    await load();

    final ad = _rewardedAd;

    if (ad == null) {
      await load();

      if (_rewardedAd == null) {
        return false;
      }
    }

    final currentAd = _rewardedAd;
    _rewardedAd = null;

    if (currentAd == null) {
      return false;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;

    currentAd.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            load();

            if (!completer.isCompleted) {
              completer.complete(rewardEarned);
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            load();

            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        );

    currentAd.show(
      onUserEarnedReward: (_, reward) {
        rewardEarned = true;
      },
    );

    return completer.future;
  }
}
