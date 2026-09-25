// lib/features/cooking/start_cooking_screen.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../recipes/recipe.dart';

class StartCookingScreen extends StatefulWidget {
  final Recipe recipe;

  const StartCookingScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<StartCookingScreen> createState() => _StartCookingScreenState();
}

class _StartCookingScreenState extends State<StartCookingScreen> {
  // ---------------------------------------------------------------------
  // AD UNIT IDS
  // ---------------------------------------------------------------------
  static const String _bannerAdUnitId =
      'ca-app-pub-8115235789134813/3760343619';
  static const String _interstitialAdUnitId =
      'ca-app-pub-8115235789134813/1381592283';

  int _currentStep = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerRunning = false;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  Recipe get recipe => widget.recipe;

  List<String> get steps => recipe.steps.isEmpty
      ? ['Your recipe is ready. Enjoy cooking!']
      : recipe.steps;

  String get currentInstruction => steps[_currentStep];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _loadBannerAd();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // ADS
  // ---------------------------------------------------------------------

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() => _isBannerAdReady = false);
          }
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialReady = false;
        },
      ),
    );
  }

  void _showInterstitialThenComplete(VoidCallback onComplete) {
    final ad = _interstitialAd;

    if (ad == null || !_isInterstitialReady) {
      onComplete();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        onComplete();
      },
    );

    ad.show();
  }

  // ---------------------------------------------------------------------
  // STEP NAVIGATION & TIMERS
  // ---------------------------------------------------------------------

  void _nextStep() {
    HapticFeedback.mediumImpact();

    if (_currentStep < steps.length - 1) {
      setState(() {
        _currentStep++;
        _stopTimer();
        _remainingSeconds = 0;
      });
    } else {
      _showCompletion();
    }
  }

  void _previousStep() {
    if (_currentStep == 0) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentStep--;
      _stopTimer();
      _remainingSeconds = 0;
    });
  }

  void _jumpToStep(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentStep = index;
      _stopTimer();
      _remainingSeconds = 0;
    });
  }

  void _startTimer(int seconds) {
    if (seconds <= 0) return;

    _timer?.cancel();

    setState(() {
      _remainingSeconds = seconds;
      _timerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
          _timerRunning = false;
        });

        HapticFeedback.heavyImpact();
        _showTimerFinished();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;

    if (mounted) {
      setState(() {
        _timerRunning = false;
      });
    }
  }

  void _showTimerFinished() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: colors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Timer Finished',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your cooking timer has completed. Check your preparation and continue when ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue Cooking',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWheelTimerPicker() {
    int selectedMins = 5;
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Timer Duration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController:
                    FixedExtentScrollController(initialItem: 4),
                    onSelectedItemChanged: (index) {
                      selectedMins = index + 1;
                      HapticFeedback.selectionClick();
                    },
                    children: List.generate(60, (index) {
                      final mins = index + 1;
                      return Center(
                        child: Text(
                          '$mins minute${mins > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startTimer(selectedMins * 60);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Timer',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIngredients() {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.60,
          minChildSize: 0.40,
          maxChildSize: 0.88,
          expand: false,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const Text(
                  'Recipe Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recipe.ingredients.length} items required • ${recipe.servings} Servings',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ...recipe.ingredients.map(
                      (ingredient) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ingredient.available
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 16,
                          color: ingredient.available
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ingredient.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          ingredient.quantity,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllStepsSheet() {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          expand: false,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const Text(
                  'Recipe Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any step to jump directly to it.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(steps.length, (index) {
                  final isCurrent = index == _currentStep;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? colors.primary.withValues(alpha: 0.08)
                          : colors.surfaceContainerHighest
                          .withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? colors.primary.withValues(alpha: 0.3)
                            : colors.outline.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _jumpToStep(index);
                      },
                      leading: CircleAvatar(
                        radius: 13,
                        backgroundColor: isCurrent
                            ? colors.primary
                            : colors.onSurfaceVariant.withValues(alpha: 0.15),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isCurrent
                                ? Colors.white
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        steps[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                          isCurrent ? FontWeight.w800 : FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.play_arrow_rounded,
                          color: colors.primary, size: 18)
                          : null,
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionTile(
                  icon: Icons.list_alt_rounded,
                  title: 'View all steps',
                  subtitle: 'Jump to any step in the recipe',
                  onTap: () {
                    Navigator.pop(context);
                    _showAllStepsSheet();
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.shopping_basket_outlined,
                  title: 'View ingredients',
                  subtitle: 'Check ingredient list & quantities',
                  onTap: () {
                    Navigator.pop(context);
                    _showIngredients();
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Restart cooking',
                  subtitle: 'Go back to step 1',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentStep = 0;
                      _stopTimer();
                      _remainingSeconds = 0;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletion() {
    HapticFeedback.heavyImpact();

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return PopScope(
          canPop: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.72),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recipe Completed! 🎉',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.name} is ready to serve. Enjoy your meal!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        _showInterstitialThenComplete(() {
                          if (!mounted) return;
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Finish & Exit',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = (_currentStep + 1) / steps.length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Exit cooking',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COOKING MODE',
              style: TextStyle(
                color: colors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              recipe.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View steps',
            onPressed: _showAllStepsSheet,
            icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Ingredients',
            onPressed: _showIngredients,
            icon: const Icon(Icons.shopping_basket_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert_rounded, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          // MAIN SCROLLABLE CONTENT VIEW
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // PROGRESS TRACKER BAR
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'STEP ${_currentStep + 1} OF ${steps.length}',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(progress * 100).toInt()}% Done',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 5,
                                  backgroundColor:
                                  colors.primary.withValues(alpha: 0.10),
                                  valueColor:
                                  AlwaysStoppedAnimation(colors.primary),
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // STEP TIMER CARD (PLACED AT THE TOP)
                    _TimerCard(
                      remainingSeconds: _remainingSeconds,
                      running: _timerRunning,
                      onStartTimer: _startTimer,
                      onStartCustom: _showWheelTimerPicker,
                      onStop: _stopTimer,
                    ),

                    const SizedBox(height: 14),

                    if (recipe.imageUrl.trim().isNotEmpty) ...[
                      _HeroImage(
                        imageUrl: recipe.imageUrl,
                        name: recipe.name,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // STEP INSTRUCTION CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.outline.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'INSTRUCTION',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentInstruction,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 17,
                              height: 1.45,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CHEF TIP CARD
                    _GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: colors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CHEF\'S TIP',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  recipe.tips.isNotEmpty
                                      ? recipe.tips[
                                  _currentStep % recipe.tips.length]
                                      : 'Keep your ingredients prepped and cook on steady heat.',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 11.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (recipe.warnings.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _GlassCard(
                        accent: colors.error,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: colors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recipe.warnings[
                                _currentStep % recipe.warnings.length],
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 11.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),

          // ANCHORED BOTTOM CONTROL BAR & AD CONTAINER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isBannerAdReady && _bannerAd != null)
                  Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    alignment: Alignment.center,
                    color: colors.surface,
                    child: AdWidget(ad: _bannerAd!),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.outline.withValues(alpha: 0.08),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha:
                          theme.brightness == Brightness.dark ? 0.20 : 0.04,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _currentStep == 0 ? null : _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(
                                color: colors.outline.withValues(alpha: 0.20),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _nextStep,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep == steps.length - 1
                                        ? 'Finish Cooking'
                                        : 'Next Step',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _currentStep == steps.length - 1
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final String name;

  const _HeroImage({
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.85,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accent;

  const _GlassCard({
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent?.withValues(alpha: 0.20) ??
              colors.outline.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}

class _TimerCard extends StatelessWidget {
  final int remainingSeconds;
  final bool running;
  final Function(int) onStartTimer;
  final VoidCallback onStartCustom;
  final VoidCallback onStop;

  const _TimerCard({
    required this.remainingSeconds,
    required this.running,
    required this.onStartTimer,
    required this.onStartCustom,
    required this.onStop,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                running ? 'TIMER ACTIVE' : 'STEP TIMER',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (running)
                GestureDetector(
                  onTap: onStop,
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                running
                    ? _formatTime(remainingSeconds)
                    : 'Set timer for this step',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: running ? 20 : 12,
                  fontWeight: running ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!running)
                Row(
                  children: [
                    _PresetChip(
                      label: '2m',
                      onTap: () => onStartTimer(120),
                      colors: colors,
                    ),
                    const SizedBox(width: 4),
                    _PresetChip(
                      label: '5m',
                      onTap: () => onStartTimer(300),
                      colors: colors,
                    ),
                    const SizedBox(width: 4),
                    _PresetChip(
                      label: 'Custom',
                      onTap: onStartCustom,
                      colors: colors,
                      isPrimary: true,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colors;
  final bool isPrimary;

  const _PresetChip({
    required this.label,
    required this.onTap,
    required this.colors,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isPrimary
              ? colors.primary
              : colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : colors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}