import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance =
  RewardedAdService._();

  // ===========================================================================
  // PRODUCTION REWARDED AD UNIT
  // ===========================================================================

  static const String adUnitId =
      'ca-app-pub-8115235789134813/6255571053';

  RewardedAd? _rewardedAd;

  bool _isLoading = false;
  bool _isShowing = false;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> load() async {
    if (_rewardedAd != null) {
      return;
    }

    if (_isLoading) {
      return;
    }

    _isLoading = true;

    final completer = Completer<void>();

    debugPrint(
      'TADKA: Loading rewarded ad...',
    );

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoading = false;

          debugPrint(
            'TADKA: Rewarded ad loaded successfully.',
          );

          debugPrint(
            'TADKA: ResponseInfo: ${ad.responseInfo}',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },

        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isLoading = false;

          debugPrint(
            'TADKA: Rewarded ad failed to load.',
          );
          debugPrint(
            'TADKA: Domain: ${error.domain}',
          );
          debugPrint(
            'TADKA: Code: ${error.code}',
          );
          debugPrint(
            'TADKA: Message: ${error.message}',
          );
          debugPrint(
            'TADKA: ResponseInfo: ${error.responseInfo}',
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

  Future<bool> showRewardedAd() async {
    if (_isShowing) {
      debugPrint(
        'TADKA: Rewarded ad is already showing.',
      );

      return false;
    }

    await load();

    RewardedAd? currentAd = _rewardedAd;

    // If the first load did not produce an ad, do not
    // repeatedly request ads in the same user action.
    if (currentAd == null) {
      debugPrint(
        'TADKA: Rewarded ad is not ready.',
      );

      return false;
    }

    _rewardedAd = null;
    _isShowing = true;

    final completer = Completer<bool>();

    bool rewardEarned = false;

    currentAd.fullScreenContentCallback =
        FullScreenContentCallback(
          // -----------------------------------------------------------------------
          // SHOWN
          // -----------------------------------------------------------------------

          onAdShowedFullScreenContent: (ad) {
            debugPrint(
              'TADKA: Rewarded ad shown.',
            );
          },

          // -----------------------------------------------------------------------
          // IMPRESSION
          // -----------------------------------------------------------------------

          onAdImpression: (ad) {
            debugPrint(
              'TADKA: Rewarded ad impression recorded.',
            );
          },

          // -----------------------------------------------------------------------
          // CLICK
          // -----------------------------------------------------------------------

          onAdClicked: (ad) {
            debugPrint(
              'TADKA: Rewarded ad clicked.',
            );
          },

          // -----------------------------------------------------------------------
          // FAILED TO SHOW
          // -----------------------------------------------------------------------

          onAdFailedToShowFullScreenContent: (
              ad,
              error,
              ) {
            debugPrint(
              'TADKA: Rewarded ad failed to show.',
            );
            debugPrint(
              'TADKA: Domain: ${error.domain}',
            );
            debugPrint(
              'TADKA: Code: ${error.code}',
            );
            debugPrint(
              'TADKA: Message: ${error.message}',
            );

            ad.dispose();

            _isShowing = false;

            // Preload the next rewarded ad.
            load();

            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },

          // -----------------------------------------------------------------------
          // DISMISSED
          // -----------------------------------------------------------------------

          onAdDismissedFullScreenContent: (ad) {
            debugPrint(
              'TADKA: Rewarded ad dismissed.',
            );

            ad.dispose();

            _isShowing = false;

            // Preload the next rewarded ad.
            load();

            if (!completer.isCompleted) {
              completer.complete(rewardEarned);
            }
          },
        );

    // =========================================================================
    // SHOW AD
    // =========================================================================

    try {
      currentAd.show(
        onUserEarnedReward: (
            AdWithoutView ad,
            RewardItem reward,
            ) {
          rewardEarned = true;

          debugPrint(
            'TADKA: Reward earned successfully.',
          );

          debugPrint(
            'TADKA: Reward amount: ${reward.amount}',
          );

          debugPrint(
            'TADKA: Reward type: ${reward.type}',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'TADKA: Exception while showing rewarded ad: $error',
      );

      currentAd.dispose();

      _isShowing = false;

      load();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  // ===========================================================================
  // PRELOAD
  // ===========================================================================

  void preload() {
    if (_rewardedAd != null || _isLoading) {
      return;
    }

    load();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  void dispose() {
    _rewardedAd?.dispose();

    _rewardedAd = null;

    _isLoading = false;
    _isShowing = false;
  }
}