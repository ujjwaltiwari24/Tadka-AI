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
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen>
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
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Preload interstitial ad early
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
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _dayReward(int day) {
    final safeDay = day.clamp(1, _rewards.length);
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
    if (_claiming) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in to claim your daily coins.');
      return;
    }

    setState(() {
      _claiming = true;
    });

    try {
      await StreakInterstitialAdService.instance.showIfAvailable();

      if (!mounted) return;

      final StreakReward result = await CoinService.instance.claimDailyStreak();

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      await _showClaimSuccess(result);
    } on CoinException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      debugPrint('Daily streak claim error: $e');

      if (!mounted) return;
      _showMessage('We could not claim your coins. Please try again.');
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

  Future<void> _showClaimSuccess(StreakReward reward) async {
    final colors = Theme.of(context).colorScheme;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Daily reward claimed',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primary,
                              colors.primary.withValues(alpha: 0.75),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reward Claimed!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+${reward.coins}',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.monetization_on_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COINS',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Day ${reward.currentStreak} complete! Your coins have been added to your wallet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu_rounded,
                              color: colors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Use your coins to unlock premium recipes.',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
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
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingView();
            }

            final user = authSnapshot.data;

            if (user == null) {
              return _SignedOutView(onSignIn: _openSignIn);
            }

            return StreamBuilder<Map<String, dynamic>>(
              stream: CoinService.instance.watchStreak(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? <String, dynamic>{};

                final rawCurrent = _intValue(data['current']);
                final longest = _intValue(data['longest']);
                final claimedToday = data['claimedToday'] == true;
                final rawNextDay = _intValue(data['nextDay']);

                // Streak Reset / Broken state check
                final bool streakBroken = data['streakBroken'] == true ||
                    (!claimedToday && rawNextDay == 1 && rawCurrent > 0);

                // Derived current streak and active claim day
                final current = streakBroken ? 0 : rawCurrent;
                final claimDay = _safeDay(
                  streakBroken
                      ? 1
                      : (rawNextDay > 0 ? rawNextDay : current + 1),
                );

                final todayReward = _dayReward(
                  claimedToday ? current.clamp(1, 7) : claimDay,
                );

                final tomorrowDay = _safeDay(
                  claimedToday ? claimDay : claimDay + 1,
                );

                final tomorrowReward = _dayReward(tomorrowDay);

                return Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(colors)),
                        SliverToBoxAdapter(child: _buildBalanceCard(colors)),
                        if (streakBroken)
                          SliverToBoxAdapter(
                            child: _buildStreakBrokenBanner(colors),
                          ),
                        SliverToBoxAdapter(
                          child: _buildHero(
                            colors,
                            current,
                            longest,
                            claimedToday,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildJourney(
                            colors,
                            current,
                            claimDay,
                            claimedToday,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildTodayReward(
                            colors,
                            claimedToday,
                            current,
                            claimDay,
                            todayReward,
                            tomorrowDay,
                            tomorrowReward,
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildHowCoinsWork(colors)),
                        SliverToBoxAdapter(
                          child: _buildReturnCard(
                            colors,
                            current,
                            claimedToday,
                            tomorrowDay,
                            tomorrowReward,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 120),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: !claimedToday
                          ? _buildPersistentClaimBar(
                        colors,
                        todayReward,
                        claimDay,
                      )
                          : _buildClaimedBottomBar(colors, tomorrowReward),
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
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          Material(
            color: colors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Rewards',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Log in daily to unlock coins',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BALANCE CARD
  // ===========================================================================

  Widget _buildBalanceCard(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COIN BALANCE',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Available in wallet',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: CoinService.instance.watchCoins(),
            builder: (context, snapshot) {
              final coins = snapshot.data ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: colors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STREAK BROKEN BANNER
  // ===========================================================================

  Widget _buildStreakBrokenBanner(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.heart_broken_rounded, color: colors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak Reset',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'You missed a day! Claim now to start your Day 1 streak.',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
  // HERO
  // ===========================================================================

  Widget _buildHero(
      ColorScheme colors,
      int current,
      int longest,
      bool claimedToday,
      ) {
    final progress = (current.clamp(0, 7) / 7).toDouble();

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = 0.12 + (_glowController.value * 0.06);

        return Container(
          margin: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.primary.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: glow),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                current == 0 ? 'Start Your Streak' : '$current Day Streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                claimedToday
                    ? 'Today’s reward is safely in your wallet.'
                    : 'Claim your daily reward to keep your streak alive.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$current / 7 days completed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Best: $longest days',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-DAY REWARD TIMELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Earn up to 75 total coins per week',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'WEEKLY GOAL',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            7,
                (index) {
              final day = index + 1;
              final reward = _dayReward(day);
              final completed = current >= day;
              final active = !claimedToday && day == claimDay && !completed;

              return _RewardRow(
                day: day,
                reward: reward,
                completed: completed,
                active: active,
                isLast: day == 7,
                primary: colors.primary,
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TODAY REWARD CARD
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
    final displayedDay = claimedToday ? current.clamp(1, 7) : claimDay;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  claimedToday
                      ? Icons.check_circle_rounded
                      : Icons.card_giftcard_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claimedToday ? 'TODAY\'S CLAIM' : 'READY TO CLAIM',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claimedToday
                          ? 'Day $displayedDay Completed'
                          : 'Day $displayedDay Reward',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$todayReward',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.monetization_on_rounded,
                    color: colors.primary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  claimedToday
                      ? Icons.check_circle_outline_rounded
                      : Icons.touch_app_rounded,
                  color: colors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    claimedToday
                        ? 'Today’s reward is active in your account.'
                        : 'Tap the claim button below to add coins.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  // ===========================================================================
  // HOW COINS WORK
  // ===========================================================================

  Widget _buildHowCoinsWork(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
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
              Icon(
                Icons.info_outline_rounded,
                color: colors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'HOW COINS WORK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Use coins to unlock customized AI recipes once your free daily requests are used.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.card_giftcard_rounded,
            text: 'Claim daily rewards to maintain your balance.',
            primary: colors.primary,
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.play_circle_fill_rounded,
            text: 'Watch rewarded ads to earn extra bonus coins anytime.',
            primary: colors.primary,
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
    final title = current == 0
        ? 'First reward ready'
        : claimedToday
        ? 'Next: Day $tomorrowDay (+$tomorrowReward Coins)'
        : 'Reward waiting';

    final subtitle = current == 0
        ? 'Claim today to start your 7-day streak.'
        : claimedToday
        ? 'Come back tomorrow to keep your streak going.'
        : 'Claim today’s coins to keep your streak active.';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            claimedToday ? Icons.event_available_rounded : Icons.star_rounded,
            color: colors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY $day REWARD',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '+$reward Coins Ready',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: _claiming
                    ? null
                    : () => _claimReward(
                  expectedDay: day,
                  expectedReward: reward,
                ),
                icon: _claiming
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.local_fire_department_rounded, size: 18),
                label: Text(
                  _claiming ? 'Claiming...' : 'Claim +$reward Coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.10)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: colors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Claimed today! Come back tomorrow for +$tomorrowReward coins.',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// REWARD ROW
// =============================================================================

class _RewardRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: isLast ? 48 : 58,
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 17,
              top: 32,
              bottom: 0,
              child: Container(
                width: 2,
                color: completed
                    ? primary.withValues(alpha: 0.3)
                    : colors.outline.withValues(alpha: 0.10),
              ),
            ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: completed
                      ? primary
                      : active
                      ? colors.surface
                      : colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? primary
                        : completed
                        ? primary
                        : colors.outline.withValues(alpha: 0.15),
                    width: active ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                      : active
                      ? Icon(Icons.local_fire_department_rounded,
                      color: primary, size: 18)
                      : Icon(Icons.lock_outline_rounded,
                      color: colors.onSurfaceVariant, size: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: completed || active
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      completed
                          ? 'Collected'
                          : active
                          ? 'Ready to claim'
                          : 'Locked',
                      style: TextStyle(
                        color: active ? primary : colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: completed || active
                      ? primary.withValues(alpha: 0.10)
                      : colors.outline.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+$reward',
                      style: TextStyle(
                        color: completed || active
                            ? primary
                            : colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.monetization_on_rounded,
                      color: completed || active
                          ? primary
                          : colors.onSurfaceVariant,
                      size: 13,
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color primary;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// AUTH LOADING VIEW
// =============================================================================

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Loading rewards...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SIGNED OUT VIEW
// =============================================================================

class _SignedOutView extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignedOutView({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: colors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daily Rewards',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to collect daily coins and unlock custom AI recipes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign In to Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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