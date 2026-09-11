import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ads/streak_interstitial_ad_service.dart';
import '../../services/coins/coin_service.dart';
import '../auth/auth_screen.dart';

class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({
    super.key,
  });

  @override
  State<DailyStreakScreen> createState() =>
      _DailyStreakScreenState();
}

class _DailyStreakScreenState
    extends State<DailyStreakScreen>
    with SingleTickerProviderStateMixin {
  static const List<int> _rewards = [
    2,
    4,
    6,
    8,
    10,
    15,
    30,
  ];

  bool _claiming = false;

  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    )..repeat(reverse: true);

    // Preload the claim interstitial early.
    StreakInterstitialAdService.instance.preload();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  int _intValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  int _dayReward(int day) {
    final safeDay = day.clamp(
      1,
      _rewards.length,
    );

    return _rewards[safeDay - 1];
  }

  int _safeDay(int day) {
    return day.clamp(1, 7);
  }

  // ===========================================================================
  // CLAIM
  // ===========================================================================

  Future<void> _claimReward({
    required int expectedDay,
    required int expectedReward,
  }) async {
    if (_claiming) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to claim your daily coins.',
      );
      return;
    }

    setState(() {
      _claiming = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * The interstitial is shown before the claim.
       *
       * The ad itself does NOT grant the reward.
       * The daily streak service remains the source of truth
       * for the actual coin reward.
       *
       * If the ad is unavailable, the user can still claim.
       * This prevents an ad availability problem from blocking
       * the core reward functionality.
       */
      await StreakInterstitialAdService.instance
          .showIfAvailable();

      if (!mounted) {
        return;
      }

      /*
       * The service is the final source of truth.
       *
       * We display the ACTUAL reward returned by the claim
       * operation and never calculate the reward locally.
       */
      final StreakReward result =
      await CoinService.instance.claimDailyStreak();

      if (!mounted) {
        return;
      }

      HapticFeedback.heavyImpact();

      await _showClaimSuccess(result);
    } on CoinException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(e.message);
    } catch (e) {
      debugPrint(
        'Daily streak claim error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'We could not claim your coins. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _claiming = false;
        });
      }
    }
  }

  // ===========================================================================
  // SUCCESS DIALOG
  // ===========================================================================

  Future<void> _showClaimSuccess(
      StreakReward reward,
      ) async {
    final colors =
        Theme.of(context).colorScheme;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Daily reward claimed',
      barrierColor:
      Colors.black.withValues(alpha: 0.58),
      transitionDuration:
      const Duration(milliseconds: 300),
      pageBuilder: (
          _,
          __,
          ___,
          ) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    22,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius:
                    BorderRadius.circular(30),
                    border: Border.all(
                      color: colors.outline
                          .withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.22),
                        blurRadius: 45,
                        offset:
                        const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration:
                        BoxDecoration(
                          gradient:
                          LinearGradient(
                            begin:
                            Alignment.topLeft,
                            end:
                            Alignment.bottomRight,
                            colors: [
                              colors.primary,
                              colors.primary
                                  .withValues(
                                alpha: 0.70,
                              ),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons
                              .local_fire_department_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Reward claimed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            '+${reward.coins}',
                            style: TextStyle(
                              color:
                              colors.primary,
                              fontSize: 29,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons
                                .monetization_on_rounded,
                            color:
                            colors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'COINS',
                            style: TextStyle(
                              color:
                              colors.primary,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Day ${reward.currentStreak} is complete. '
                            'Your coins have been added to your TADKA wallet.',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          color:
                          colors.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight:
                          FontWeight.w600,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(13),
                        decoration:
                        BoxDecoration(
                          color: colors.primary
                              .withValues(
                            alpha: 0.055,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .restaurant_menu_rounded,
                              color:
                              colors.primary,
                              size: 18,
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Text(
                                'Use your coins to unlock more recipes.',
                                style: TextStyle(
                                  color:
                                  colors.onSurface,
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            );
                          },
                          style:
                          FilledButton.styleFrom(
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(15),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
          _,
          animation,
          __,
          child,
          ) {
        final curved =
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: curved,
            child: child,
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.all(16),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(15),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,

      body: SafeArea(
        child: StreamBuilder<User?>(
          stream:
          FirebaseAuth.instance
              .authStateChanges(),
          builder: (
              context,
              authSnapshot,
              ) {
            if (authSnapshot
                .connectionState ==
                ConnectionState.waiting) {
              return const _AuthLoadingView();
            }

            final user =
                authSnapshot.data;

            if (user == null) {
              return _SignedOutView(
                onSignIn: _openSignIn,
              );
            }

            return StreamBuilder<
                Map<String, dynamic>>(
              stream:
              CoinService.instance
                  .watchStreak(),
              builder: (
                  context,
                  snapshot,
                  ) {
                final data =
                    snapshot.data ??
                        <String, dynamic>{};

                final current =
                _intValue(
                  data['current'],
                );

                final longest =
                _intValue(
                  data['longest'],
                );

                final claimedToday =
                    data['claimedToday'] ==
                        true;

                final rawNextDay =
                _intValue(
                  data['nextDay'],
                );

                final claimDay =
                _safeDay(
                  rawNextDay > 0
                      ? rawNextDay
                      : current + 1,
                );

                final todayReward =
                _dayReward(
                  claimedToday
                      ? current.clamp(
                    1,
                    7,
                  )
                      : claimDay,
                );

                final tomorrowDay =
                _safeDay(
                  claimedToday
                      ? claimDay
                      : claimDay + 1,
                );

                final tomorrowReward =
                _dayReward(
                  tomorrowDay,
                );

                return Stack(
                  children: [
                    CustomScrollView(
                      physics:
                      const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child:
                          _buildHeader(
                            colors,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                          _buildBalanceCard(
                            colors,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                          _buildHero(
                            colors,
                            current,
                            longest,
                            claimedToday,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                          _buildJourney(
                            colors,
                            current,
                            claimDay,
                            claimedToday,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                          _buildTodayReward(
                            colors,
                            claimedToday,
                            current,
                            claimDay,
                            todayReward,
                            tomorrowDay,
                            tomorrowReward,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                          _buildHowCoinsWork(
                            colors,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                          _buildReturnCard(
                            colors,
                            current,
                            claimedToday,
                            tomorrowDay,
                            tomorrowReward,
                          ),
                        ),

                        /*
                         * Extra bottom space so the persistent CTA
                         * never covers the final content.
                         */
                        const SliverToBoxAdapter(
                          child:
                          SizedBox(
                            height: 135,
                          ),
                        ),
                      ],
                    ),

                    // ===========================================================
                    // PERSISTENT CLAIM CTA
                    // ===========================================================

                    if (!claimedToday)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child:
                        _buildPersistentClaimBar(
                          colors,
                          todayReward,
                          claimDay,
                        ),
                      )
                    else
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child:
                        _buildClaimedBottomBar(
                          colors,
                          tomorrowReward,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  Future<void> _openSignIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AuthScreen(),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(
      ColorScheme colors,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        0,
      ),
      child: Row(
        children: [
          Material(
            color: colors.surface,
            shape:
            const CircleBorder(),
            child: InkWell(
              customBorder:
              const CircleBorder(),
              onTap: () {
                HapticFeedback
                    .selectionClick();

                Navigator.pop(
                  context,
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
                  border: Border.all(
                    color: colors
                        .outline
                        .withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons
                      .arrow_back_rounded,
                  size: 21,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Rewards',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Come back daily. Earn free coins.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.08,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .card_giftcard_rounded,
              color:
              colors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BALANCE
  // ===========================================================================

  Widget _buildBalanceCard(
      ColorScheme colors,
      ) {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        0,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      decoration:
      BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: colors.outline
              .withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.09,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .monetization_on_rounded,
              color:
              colors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'COIN BALANCE',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing:
                    0.9,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Use coins to unlock recipes',
                  style: TextStyle(
                    color:
                    colors.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<int>(
            stream:
            CoinService.instance
                .watchCoins(),
            builder: (
                context,
                snapshot,
                ) {
              final coins =
                  snapshot.data ?? 0;

              return Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .monetization_on_rounded,
                    color:
                    colors.primary,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    '$coins',
                    style: TextStyle(
                      color:
                      colors.primary,
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero(
      ColorScheme colors,
      int current,
      int longest,
      bool claimedToday,
      ) {
    final progress =
        current.clamp(0, 7) / 7;

    return AnimatedBuilder(
      animation:
      _glowController,
      builder: (
          context,
          child,
          ) {
        final glow =
            0.10 +
                (_glowController.value *
                    0.04);

        return Container(
          margin:
          const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            18,
          ),
          padding:
          const EdgeInsets.fromLTRB(
            23,
            23,
            23,
            20,
          ),
          decoration:
          BoxDecoration(
            gradient:
            LinearGradient(
              begin:
              Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.primary
                    .withValues(
                  alpha: 0.74,
                ),
              ],
            ),
            borderRadius:
            BorderRadius.circular(
              30,
            ),
            boxShadow: [
              BoxShadow(
                color:
                colors.primary
                    .withValues(
                  alpha: glow,
                ),
                blurRadius: 32,
                offset:
                const Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: Colors.white
                        .withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons
                      .local_fire_department_rounded,
                  color:
                  Colors.white,
                  size: 36,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                current == 0
                    ? 'Start Your Streak'
                    : '$current Day Streak',
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 27,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                claimedToday
                    ? 'Today’s reward is already in your wallet.'
                    : 'Your daily reward is ready. Keep the fire going.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.86,
                  ),
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                  height: 1.4,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child:
                LinearProgressIndicator(
                  value:
                  progress,
                  minHeight: 7,
                  backgroundColor:
                  Colors.white
                      .withValues(
                    alpha: 0.18,
                  ),
                  valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                    Colors.white,
                  ),
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
                children: [
                  Text(
                    '$current / 7 days',
                    style:
                    TextStyle(
                      color:
                      Colors.white
                          .withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Best: $longest days',
                    style:
                    TextStyle(
                      color:
                      Colors.white
                          .withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 7 DAY JOURNEY
  // ===========================================================================

  Widget _buildJourney(
      ColorScheme colors,
      int current,
      int claimDay,
      bool claimedToday,
      ) {
    return Container(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      padding:
      const EdgeInsets.fromLTRB(
        19,
        20,
        19,
        18,
      ),
      decoration:
      BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(
          25,
        ),
        border: Border.all(
          color: colors.outline
              .withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-DAY COIN JOURNEY',
                      style:
                      TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing:
                        1.0,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Bigger rewards. Better consistency.',
                      style:
                      TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color: colors
                      .primary
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  '75 COINS',
                  style:
                  TextStyle(
                    color:
                    colors.primary,
                    fontSize: 8,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          ...List.generate(
            7,
                (index) {
              final day =
                  index + 1;

              final reward =
              _dayReward(day);

              final completed =
                  current >= day;

              final active =
                  !claimedToday &&
                      day == claimDay &&
                      !completed;

              return _RewardRow(
                day: day,
                reward: reward,
                completed:
                completed,
                active: active,
                isLast:
                day == 7,
                primary:
                colors.primary,
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TODAY REWARD
  // ===========================================================================

  Widget _buildTodayReward(
      ColorScheme colors,
      bool claimedToday,
      int current,
      int claimDay,
      int todayReward,
      int tomorrowDay,
      int tomorrowReward,
      ) {
    final displayedDay =
    claimedToday
        ? current.clamp(1, 7)
        : claimDay;

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        0,
      ),
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            colors.primary
                .withValues(
              alpha: 0.09,
            ),
            colors.primary
                .withValues(
              alpha: 0.025,
            ),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          25,
        ),
        border: Border.all(
          color: colors.primary
              .withValues(
            alpha: 0.11,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  claimedToday
                      ? Icons
                      .check_circle_rounded
                      : Icons
                      .card_giftcard_rounded,
                  color:
                  colors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      claimedToday
                          ? 'TODAY’S REWARD'
                          : 'READY TO CLAIM',
                      style:
                      TextStyle(
                        color:
                        colors.primary,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing:
                        0.9,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      claimedToday
                          ? 'Day $displayedDay completed'
                          : 'Day $displayedDay reward',
                      style:
                      TextStyle(
                        color: colors
                            .onSurfaceVariant,
                        fontSize: 9.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '+$todayReward',
                style:
                TextStyle(
                  color:
                  colors.primary,
                  fontSize: 23,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                width: 3,
              ),

              Icon(
                Icons
                    .monetization_on_rounded,
                color:
                colors.primary,
                size: 18,
              ),
            ],
          ),

          const SizedBox(
            height: 3,
          ),

          Align(
            alignment:
            Alignment.centerRight,
            child: Text(
              'COINS',
              style:
              TextStyle(
                color:
                colors.primary,
                fontSize: 7.5,
                fontWeight:
                FontWeight.w900,
                letterSpacing:
                0.7,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration:
            BoxDecoration(
              color: colors.surface
                  .withValues(
                alpha: 0.70,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  claimedToday
                      ? Icons
                      .check_circle_outline_rounded
                      : Icons
                      .touch_app_rounded,
                  color:
                  colors.primary,
                  size: 17,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    claimedToday
                        ? 'Today’s coins are safely in your wallet.'
                        : 'Use the Claim button below — it stays visible while you scroll.',
                    style:
                    TextStyle(
                      color: colors
                          .onSurfaceVariant,
                      fontSize: 9.5,
                      fontWeight:
                      FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (claimedToday) ...[
            const SizedBox(
              height: 10,
            ),
            Text(
              'Come back tomorrow for +$tomorrowReward COINS',
              style:
              TextStyle(
                color:
                colors.onSurfaceVariant,
                fontSize: 9,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // HOW COINS WORK
  // ===========================================================================

  Widget _buildHowCoinsWork(
      ColorScheme colors,
      ) {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        0,
      ),
      padding:
      const EdgeInsets.all(19),
      decoration:
      BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(
          23,
        ),
        border: Border.all(
          color: colors.outline
              .withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.09,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  Icons
                      .monetization_on_rounded,
                  color:
                  colors.primary,
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Text(
                'HOW COINS WORK',
                style:
                TextStyle(
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing:
                  1,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Text(
            'Coins are your TADKA recipe credits.',
            style:
            TextStyle(
              color:
              colors.onSurface,
              fontSize: 12,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'After your free recipes are used, spend coins to unlock additional recipes.',
            style:
            TextStyle(
              color:
              colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight:
              FontWeight.w500,
              height: 1.45,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _InfoLine(
            icon:
            Icons.card_giftcard_rounded,
            text:
            'Claim your daily reward to earn free coins.',
            primary:
            colors.primary,
          ),

          const SizedBox(
            height: 8,
          ),

          _InfoLine(
            icon:
            Icons.play_circle_fill_rounded,
            text:
            'Watch optional rewarded ads separately to earn additional coins.',
            primary:
            colors.primary,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RETURN CARD
  // ===========================================================================

  Widget _buildReturnCard(
      ColorScheme colors,
      int current,
      bool claimedToday,
      int tomorrowDay,
      int tomorrowReward,
      ) {
    final title =
    current == 0
        ? 'Your first reward is waiting.'
        : claimedToday
        ? 'Tomorrow: +$tomorrowReward COINS'
        : 'Your reward is ready.';

    final subtitle =
    current == 0
        ? 'Start today and turn your daily visits into free coins.'
        : claimedToday
        ? 'Come back tomorrow to claim Day $tomorrowDay and keep earning.'
        : 'Claim today’s coins using the button that stays visible below.';

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        0,
      ),
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: colors.primary
            .withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          21,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.10,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              claimedToday
                  ? Icons
                  .event_available_rounded
                  : Icons
                  .auto_awesome_rounded,
              color:
              colors.primary,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  subtitle,
                  style:
                  TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PERSISTENT CLAIM BAR
  // ===========================================================================

  Widget _buildPersistentClaimBar(
      ColorScheme colors,
      int reward,
      int day,
      ) {
    return Container(
      decoration:
      BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outline
                .withValues(
              alpha: 0.08,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.10,
            ),
            blurRadius: 24,
            offset:
            const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  Icons
                      .card_giftcard_rounded,
                  color:
                  colors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY $day REWARD',
                      style:
                      TextStyle(
                        color:
                        colors.primary,
                        fontSize: 8,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing:
                        0.8,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '+$reward TADKA Coins',
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds: 180,
                ),
                child: SizedBox(
                  key: ValueKey(
                    _claiming,
                  ),
                  height: 48,
                  child: FilledButton(
                    onPressed:
                    _claiming
                        ? null
                        : () =>
                        _claimReward(
                          expectedDay:
                          day,
                          expectedReward:
                          reward,
                        ),
                    style:
                    FilledButton.styleFrom(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 19,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          15,
                        ),
                      ),
                    ),
                    child: _claiming
                        ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2.2,
                        color:
                        Colors.white,
                      ),
                    )
                        : Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .local_fire_department_rounded,
                          size: 17,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          'CLAIM +$reward',
                          style:
                          const TextStyle(
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .w900,
                          ),
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
    );
  }

  // ===========================================================================
  // CLAIMED BOTTOM BAR
  // ===========================================================================

  Widget _buildClaimedBottomBar(
      ColorScheme colors,
      int tomorrowReward,
      ) {
    return Container(
      decoration:
      BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outline
                .withValues(
              alpha: 0.08,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.08,
            ),
            blurRadius: 20,
            offset:
            const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10,
          ),
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons
                      .check_circle_rounded,
                  color:
                  colors.primary,
                  size: 20,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        'REWARD CLAIMED TODAY',
                        style:
                        TextStyle(
                          color:
                          colors.primary,
                          fontSize: 8,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing:
                          0.7,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        'Come back tomorrow for +$tomorrowReward coins',
                        style:
                        TextStyle(
                          color: colors
                              .onSurfaceVariant,
                          fontSize: 9.5,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// REWARD ROW
// =============================================================================

class _RewardRow
    extends StatelessWidget {
  final int day;
  final int reward;
  final bool completed;
  final bool active;
  final bool isLast;
  final Color primary;

  const _RewardRow({
    required this.day,
    required this.reward,
    required this.completed,
    required this.active,
    required this.isLast,
    required this.primary,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final locked =
        !completed && !active;

    return SizedBox(
      height:
      isLast ? 68 : 78,
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 20,
              top: 43,
              bottom: 0,
              child: Container(
                width: 2,
                decoration:
                BoxDecoration(
                  color: completed
                      ? primary
                      .withValues(
                    alpha: 0.28,
                  )
                      : colors.outline
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    4,
                  ),
                ),
              ),
            ),

          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration:
                BoxDecoration(
                  gradient: completed
                      ? LinearGradient(
                    begin:
                    Alignment.topLeft,
                    end:
                    Alignment
                        .bottomRight,
                    colors: [
                      primary,
                      primary
                          .withValues(
                        alpha: 0.72,
                      ),
                    ],
                  )
                      : null,
                  color:
                  completed ||
                      active
                      ? null
                      : colors
                      .surface,
                  shape:
                  BoxShape.circle,
                  border:
                  Border.all(
                    color: active
                        ? primary
                        : completed
                        ? primary
                        : colors
                        .outline
                        .withValues(
                      alpha:
                      0.10,
                    ),
                    width:
                    active
                        ? 1.8
                        : 1,
                  ),
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color:
                      primary
                          .withValues(
                        alpha: 0.17,
                      ),
                      blurRadius:
                      14,
                    ),
                  ]
                      : null,
                ),
                child:
                Center(
                  child:
                  completed
                      ? const Icon(
                    Icons
                        .check_rounded,
                    color:
                    Colors.white,
                    size: 19,
                  )
                      : active
                      ? Icon(
                    Icons
                        .radio_button_checked_rounded,
                    color:
                    primary,
                    size: 18,
                  )
                      : Icon(
                    Icons
                        .lock_outline_rounded,
                    color: colors
                        .onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Day $day',
                      style:
                      TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w900,
                        color: locked
                            ? colors
                            .onSurfaceVariant
                            : colors
                            .onSurface,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      completed
                          ? 'Coins collected'
                          : active
                          ? 'Ready to claim'
                          : 'Keep your streak alive',
                      style:
                      TextStyle(
                        color: active
                            ? primary
                            : colors
                            .onSurfaceVariant,
                        fontSize: 8.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration:
                BoxDecoration(
                  color: completed ||
                      active
                      ? primary
                      .withValues(
                    alpha: 0.09,
                  )
                      : colors.outline
                      .withValues(
                    alpha: 0.05,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Text(
                      '+$reward',
                      style:
                      TextStyle(
                        color: completed ||
                            active
                            ? primary
                            : colors
                            .onSurfaceVariant,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Icon(
                      Icons
                          .monetization_on_rounded,
                      color: completed ||
                          active
                          ? primary
                          : colors
                          .onSurfaceVariant,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// INFO LINE
// =============================================================================

class _InfoLine
    extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color primary;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.primary,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: primary,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            text,
            style:
            TextStyle(
              color: colors
                  .onSurfaceVariant,
              fontSize: 9.5,
              fontWeight:
              FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// AUTH LOADING
// =============================================================================

class _AuthLoadingView
    extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
              BoxDecoration(
                color: colors.primary
                    .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(
                  19,
                ),
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color:
                  colors.primary,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Opening your rewards',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              'Checking your account...',
              style:
              TextStyle(
                color: colors
                    .onSurfaceVariant,
                fontSize: 10,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SIGNED OUT
// =============================================================================

class _SignedOutView
    extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignedOutView({
    required this.onSignIn,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
            const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration:
                  BoxDecoration(
                    color: colors.primary
                        .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      23,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .card_giftcard_rounded,
                    color:
                    colors.primary,
                    size: 38,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Daily rewards are waiting',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  'Sign in to collect daily COINS and use them to unlock more recipes.',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w600,
                    height: 1.45,
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  height: 50,
                  child:
                  FilledButton(
                    onPressed:
                    onSignIn,
                    style:
                    FilledButton
                        .styleFrom(
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          15,
                        ),
                      ),
                    ),
                    child:
                    const Text(
                      'Sign in to continue',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                TextButton(
                  onPressed:
                      () => Navigator
                      .pop(
                    context,
                  ),
                  child:
                  const Text(
                    'Go back',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}