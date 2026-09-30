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

  late final AnimationController _flamePulseController;

  @override
  void initState() {
    super.initState();

    _flamePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Preload interstitial ad early
    StreakInterstitialAdService.instance.preload();
  }

  @override
  void dispose() {
    _flamePulseController.dispose();
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
  // CLAIM ACTION
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Daily reward claimed',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE4E4E7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF97316),
                                  Color(0xFFEA580C),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF97316).withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Day ${reward.currentStreak} Complete!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF09090B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${reward.coins}',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ADDED TO WALLET',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Great job! Keep your daily streak going to unlock maximum milestone rewards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Awesome!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.2,
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
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
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
                        SliverToBoxAdapter(child: _buildHeader(isDark)),
                        SliverToBoxAdapter(child: _buildWalletBar(isDark)),
                        if (streakBroken)
                          SliverToBoxAdapter(
                            child: _buildStreakBrokenBanner(isDark),
                          ),
                        SliverToBoxAdapter(
                          child: _buildHeroDashboard(
                            isDark,
                            current,
                            longest,
                            claimedToday,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildHorizontalMilestoneTrack(
                            isDark,
                            current,
                            claimDay,
                            claimedToday,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildStatusInsightCard(
                            isDark,
                            claimedToday,
                            current,
                            claimDay,
                            todayReward,
                            tomorrowDay,
                            tomorrowReward,
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildUtilityGuide(isDark)),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 120),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: !claimedToday
                          ? _buildFloatingClaimCTA(
                        isDark,
                        todayReward,
                        claimDay,
                      )
                          : _buildClaimedFloatingBar(isDark, tomorrowReward),
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
  // SIGN IN NAVIGATOR
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                ),
              ),
            ),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF09090B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                ),
                Text(
                  'Check in daily for coins & rewards',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
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
  // WALLET BALANCE CARD
  // ===========================================================================

  Widget _buildWalletBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WALLET BALANCE',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Use them to unlock recipes for FREE',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                    fontSize: 11.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 15,
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

  Widget _buildStreakBrokenBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.heart_broken_rounded, color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Reset',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You missed a day! Claim today to start your new Day 1 streak.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                    fontSize: 11.5,
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
  // HERO DASHBOARD
  // ===========================================================================

  Widget _buildHeroDashboard(
      bool isDark,
      int current,
      int longest,
      bool claimedToday,
      ) {
    final progress = (current.clamp(0, 7) / 7).toDouble();

    return AnimatedBuilder(
      animation: _flamePulseController,
      builder: (context, child) {
        final glowScale = 0.15 + (_flamePulseController.value * 0.10);

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF111827),
                Color(0xFF1F2937),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: glowScale),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF97316),
                      ),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFF97316),
                      size: 38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                current == 0 ? 'Start Your Streak' : '$current Day Streak!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                claimedToday
                    ? 'Today’s check-in complete. Come back tomorrow!'
                    : 'Claim your daily reward to keep your streak alive.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF22C55E),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$current / 7 Days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Best: $longest Days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // HORIZONTAL MILESTONE TRACK
  // ===========================================================================

  Widget _buildHorizontalMilestoneTrack(
      bool isDark,
      int current,
      int claimDay,
      bool claimedToday,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STREAK MILESTONES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              const Text(
                '75 Total Coins/Week',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF97316),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = index + 1;
              final reward = _dayReward(day);
              final completed = current >= day;
              final active = !claimedToday && day == claimDay && !completed;
              final isJackpot = day == 7;

              return Container(
                width: isJackpot ? 110 : 88,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isJackpot
                      ? (isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF))
                      : (completed
                      ? (isDark ? const Color(0xFF18181B) : Colors.white)
                      : (active
                      ? (isDark ? const Color(0xFF27272A) : Colors.white)
                      : (isDark ? const Color(0xFF121215) : const Color(0xFFF1F5F9)))),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFF97316)
                        : (isJackpot
                        ? const Color(0xFF6366F1)
                        : (completed
                        ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)))),
                    width: active || isJackpot ? 2 : 1,
                  ),
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isJackpot ? 'DAY 7 👑' : 'Day $day',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: active
                            ? const Color(0xFFF97316)
                            : (isDark ? Colors.white : const Color(0xFF09090B)),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: completed
                            ? const Color(0xFF22C55E)
                            : (active
                            ? const Color(0xFFF97316)
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0))),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed
                            ? Icons.check_rounded
                            : (active
                            ? Icons.local_fire_department_rounded
                            : Icons.lock_outline_rounded),
                        color: completed || active
                            ? Colors.white
                            : (isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8)),
                        size: 18,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+$reward',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: active
                                ? const Color(0xFFF97316)
                                : (isDark ? Colors.white : const Color(0xFF09090B)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFF59E0B),
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STATUS INSIGHT CARD
  // ===========================================================================

  Widget _buildStatusInsightCard(
      bool isDark,
      bool claimedToday,
      int current,
      int claimDay,
      int todayReward,
      int tomorrowDay,
      int tomorrowReward,
      ) {
    final displayedDay = claimedToday ? current.clamp(1, 7) : claimDay;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  claimedToday
                      ? Icons.task_alt_rounded
                      : Icons.card_giftcard_rounded,
                  color: const Color(0xFFF97316),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claimedToday ? 'CHECK-IN COMPLETE' : 'READY TO CLAIM',
                      style: const TextStyle(
                        color: Color(0xFFF97316),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claimedToday
                          ? 'Day $displayedDay Claimed'
                          : 'Day $displayedDay Bonus Available',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
                    style: const TextStyle(
                      color: Color(0xFFF97316),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  claimedToday
                      ? Icons.schedule_rounded
                      : Icons.touch_app_rounded,
                  color: const Color(0xFFF97316),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    claimedToday
                        ? 'Come back tomorrow for Day $tomorrowDay (+$tomorrowReward coins).'
                        : 'Tap the button below to add coins to your wallet.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                      fontSize: 12,
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
  // UTILITY GUIDE
  // ===========================================================================

  Widget _buildUtilityGuide(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'WHAT CAN YOU DO WITH COINS?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: isDark ? Colors.white : const Color(0xFF09090B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GuideItem(
            icon: Icons.restaurant_menu_rounded,
            text: 'Unlock custom AI recipe generations when daily limits end.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _GuideItem(
            icon: Icons.play_circle_fill_rounded,
            text: 'Earn extra coins anytime by watching quick rewarded video ads.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FLOATING CLAIM CTA BAR
  // ===========================================================================

  Widget _buildFloatingClaimCTA(
      bool isDark,
      int reward,
      int day,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY\'S REWARD',
                  style: TextStyle(
                    color: Color(0xFFF97316),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                Text(
                  '+$reward Coins Ready',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _claiming
                  ? null
                  : () => _claimReward(
                expectedDay: day,
                expectedReward: reward,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              icon: _claiming
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.local_fire_department_rounded, size: 20),
              label: Text(
                _claiming ? 'Claiming...' : 'Claim +$reward Coins',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CLAIMED FLOATING BAR
  // ===========================================================================

  Widget _buildClaimedFloatingBar(
      bool isDark,
      int tomorrowReward,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22C55E),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reward claimed! Check in tomorrow for +$tomorrowReward coins.',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF09090B),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER GUIDE ITEM
// =============================================================================

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _GuideItem({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFF97316)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFF97316),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Loading rewards...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFFF97316),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Daily Rewards',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to collect daily coins and unlock custom AI recipes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign In to Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
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