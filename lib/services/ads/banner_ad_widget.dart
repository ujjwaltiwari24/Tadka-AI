import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // TADKA AI Banner Ad Unit ID
  static const String _bannerAdUnitId =
      'ca-app-pub-8698720966428005/5557703106';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },

        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          debugPrint(
            'TADKA AdMob banner failed: ${error.message}',
          );

          if (!mounted) return;

          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },

        onAdOpened: (ad) {
          debugPrint('TADKA AdMob banner opened.');
        },

        onAdClosed: (ad) {
          debugPrint('TADKA AdMob banner closed.');
        },

        onAdImpression: (ad) {
          debugPrint('TADKA AdMob banner impression.');
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(
            ad: _bannerAd!,
          ),
        ),
      ),
    );
  }
}