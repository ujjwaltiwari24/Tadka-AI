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

  // TADKA AI production streak interstitial.
  // Used only in release builds.
  static const String _productionAdUnitId =
      'ca-app-pub-8115235789134813/5577710366';

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
            'TADKA: Streak interstitial loaded successfully.',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isLoading = false;

          debugPrint(
            'TADKA: Streak interstitial failed to load.',
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

  // ---------------------------------------------------------------------------
  // SHOW
  // ---------------------------------------------------------------------------

  Future<bool> showIfAvailable() async {
    await preload();

    final ad = _interstitialAd;

    if (ad == null) {
      debugPrint(
        'TADKA: Streak interstitial unavailable. Continuing without ad.',
      );
      return false;
    }

    _interstitialAd = null;

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint(
          'TADKA: Streak interstitial shown.',
        );
      },

      onAdImpression: (ad) {
        debugPrint(
          'TADKA: Streak interstitial impression recorded.',
        );
      },

      onAdClicked: (ad) {
        debugPrint(
          'TADKA: Streak interstitial clicked.',
        );
      },

      onAdFailedToShowFullScreenContent: (
          ad,
          error,
          ) {
        debugPrint(
          'TADKA: Streak interstitial failed to show.',
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

        preload();

        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },

      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          'TADKA: Streak interstitial dismissed.',
        );

        ad.dispose();

        preload();

        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );

    try {
      ad.show();
    } catch (error) {
      debugPrint(
        'TADKA: Exception while showing streak interstitial: $error',
      );

      ad.dispose();

      preload();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

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