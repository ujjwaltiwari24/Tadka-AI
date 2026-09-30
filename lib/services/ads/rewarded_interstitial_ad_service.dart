import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedInterstitialAdService {
  RewardedInterstitialAdService._();

  static final RewardedInterstitialAdService instance =
  RewardedInterstitialAdService._();

  // TADKA AI production rewarded interstitial ad unit.
  static const String adUnitId =
      'ca-app-pub-8115235789134813/6300830755';

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isLoading = false;
  bool _isShowing = false;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> load() async {
    if (_rewardedInterstitialAd != null || _isLoading) {
      return;
    }

    _isLoading = true;

    final completer = Completer<void>();

    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback:
      RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isLoading = false;

          debugPrint(
            'TADKA: Rewarded interstitial loaded successfully.',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isLoading = false;

          debugPrint(
            'TADKA: Rewarded interstitial failed to load.',
          );
          debugPrint('Domain: ${error.domain}');
          debugPrint('Code: ${error.code}');
          debugPrint('Message: ${error.message}');
          debugPrint(
            'ResponseInfo: ${error.responseInfo}',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    await completer.future;
  }

  // ===========================================================================
  // SHOW
  // ===========================================================================

  Future<bool> showRewardedInterstitialAd() async {
    if (_isShowing) {
      debugPrint(
        'TADKA: Rewarded interstitial is already showing.',
      );
      return false;
    }

    await load();

    final currentAd = _rewardedInterstitialAd;

    if (currentAd == null) {
      debugPrint(
        'TADKA: Rewarded interstitial is not ready.',
      );
      return false;
    }

    _rewardedInterstitialAd = null;
    _isShowing = true;

    final completer = Completer<bool>();
    bool rewardEarned = false;

    currentAd.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            debugPrint(
              'TADKA: Rewarded interstitial shown.',
            );
          },

          onAdImpression: (ad) {
            debugPrint(
              'TADKA: Rewarded interstitial impression recorded.',
            );
          },

          onAdClicked: (ad) {
            debugPrint(
              'TADKA: Rewarded interstitial clicked.',
            );
          },

          onAdFailedToShowFullScreenContent: (
              ad,
              error,
              ) {
            debugPrint(
              'TADKA: Rewarded interstitial failed to show.',
            );
            debugPrint('Domain: ${error.domain}');
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');

            ad.dispose();

            _isShowing = false;

            // Start loading the next ad.
            load();

            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },

          onAdDismissedFullScreenContent: (ad) {
            debugPrint(
              'TADKA: Rewarded interstitial dismissed.',
            );

            ad.dispose();

            _isShowing = false;

            // Preload the next ad.
            load();

            if (!completer.isCompleted) {
              completer.complete(rewardEarned);
            }
          },
        );

    currentAd.show(
      onUserEarnedReward: (
          AdWithoutView ad,
          RewardItem reward,
          ) {
        rewardEarned = true;

        debugPrint(
          'TADKA: Reward earned from rewarded interstitial.',
        );
        debugPrint(
          'Reward amount: ${reward.amount}',
        );
        debugPrint(
          'Reward type: ${reward.type}',
        );
      },
    );

    return completer.future;
  }

  // ===========================================================================
  // PRELOAD
  // ===========================================================================

  void preload() {
    load();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _isLoading = false;
    _isShowing = false;
  }
}