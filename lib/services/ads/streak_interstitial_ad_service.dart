import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class StreakInterstitialAdService {
  StreakInterstitialAdService._();

  static final StreakInterstitialAdService instance =
  StreakInterstitialAdService._();

  // ---------------------------------------------------------------------------
  // AD UNIT IDS
  // ---------------------------------------------------------------------------

  // Google-provided Android test interstitial.
  // Used automatically during debug development.
  static const String _debugAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // TADKA AI production interstitial supplied by the developer.
  // Used only in release builds.
  static const String _productionAdUnitId =
      'ca-app-pub-8115235789134813/4883416699';

  String get _adUnitId =>
      kDebugMode ? _debugAdUnitId : _productionAdUnitId;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // PRELOAD
  // ---------------------------------------------------------------------------

  Future<void> preload() async {
    if (_interstitialAd != null || _isLoading) {
      return;
    }

    _isLoading = true;

    final completer = Completer<void>();

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoading = false;

          debugPrint(
            'Streak interstitial loaded successfully.',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isLoading = false;

          debugPrint(
            'Streak interstitial failed to load: $error',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    await completer.future;
  }

  // ---------------------------------------------------------------------------
  // SHOW
  // ---------------------------------------------------------------------------

  Future<bool> showIfAvailable() async {
    await preload();

    final ad = _interstitialAd;

    if (ad == null) {
      debugPrint(
        'Streak interstitial unavailable. Continuing without ad.',
      );
      return false;
    }

    _interstitialAd = null;

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint(
          'Streak interstitial shown.',
        );
      },
      onAdImpression: (ad) {
        debugPrint(
          'Streak interstitial impression recorded.',
        );
      },
      onAdClicked: (ad) {
        debugPrint(
          'Streak interstitial clicked.',
        );
      },
      onAdFailedToShowFullScreenContent: (
          ad,
          error,
          ) {
        debugPrint(
          'Streak interstitial failed to show: $error',
        );

        ad.dispose();

        // Prepare the next ad.
        preload();

        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          'Streak interstitial dismissed.',
        );

        ad.dispose();

        // Preload the next interstitial for a future claim.
        preload();

        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );

    ad.show();

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
  }
}