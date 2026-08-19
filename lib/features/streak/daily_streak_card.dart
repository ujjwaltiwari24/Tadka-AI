import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/coins/coin_service.dart';

class DailyStreakCard extends StatefulWidget {
  const DailyStreakCard({
    super.key,
  });

  @override
  State<DailyStreakCard>
  createState() =>
      _DailyStreakCardState();
}

class _DailyStreakCardState
    extends State<DailyStreakCard> {
  bool _claiming = false;

  Future<void> _claimReward() async {
    if (_claiming) return;

    setState(() {
      _claiming = true;
    });

    try {
      final reward =
      await CoinService.instance
          .claimDailyStreak();

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      _showRewardDialog(reward);
    } on CoinException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } catch (e) {
      debugPrint(
        'Daily streak error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Could not claim your reward. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _claiming = false;
        });
      }
    }
  }

  void _showMessage(String message) {
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
            BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showRewardDialog(
      StreakReward reward,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(28),
          ),
          child: Padding(
            padding:
            const EdgeInsets.all(26),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration:
                  BoxDecoration(
                    color: colors.primary
                        .withValues(
                      alpha: 0.10,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child:
                  const Center(
                    child: Text(
                      '🔥',
                      style:
                      TextStyle(
                        fontSize: 40,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Text(
                  '${reward.currentStreak} Day Streak!',
                  style:
                  const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  '+${reward.coins} coins added to your wallet',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  height: 48,
                  child:
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child:
                    const Text(
                      'Awesome!',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight.w900,
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

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return StreamBuilder<
        Map<String, dynamic>>(
      stream:
      CoinService.instance
          .watchStreak(),
      builder:
          (context, snapshot) {
        final data =
            snapshot.data ?? {};

        final current =
            (data['current']
            as int?) ??
                0;

        final claimedToday =
            (data['claimedToday']
            as bool?) ??
                false;

        final nextDay =
            (data['nextDay']
            as int?) ??
                1;

        final nextReward =
            (data['nextReward']
            as int?) ??
                2;

        return Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(17),
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
                  alpha: 0.12,
                ),
                colors.primary
                    .withValues(
                  alpha: 0.035,
                ),
              ],
            ),
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: colors.primary
                  .withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================

              Row(
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
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Center(
                      child: Text(
                        '🔥',
                        style:
                        TextStyle(
                          fontSize: 21,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'DAILY STREAK',
                          style:
                          TextStyle(
                            color: colors
                                .onSurface,
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .w900,
                            letterSpacing:
                            1.1,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          current == 0
                              ? 'Start your streak today'
                              : '$current day${current == 1 ? '' : 's'} strong 🔥',
                          style:
                          TextStyle(
                            color: colors
                                .onSurfaceVariant,
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .w600,
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
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color: colors
                          .primary
                          .withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                    child: Text(
                      claimedToday
                          ? 'CLAIMED'
                          : '+$nextReward',
                      style: TextStyle(
                        color:
                        colors.primary,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              // ============================================================
              // 7 DAY REWARD TRACK
              // ============================================================

              Row(
                children:
                List.generate(
                  7,
                      (index) {
                    final day =
                        index + 1;

                    final reward =
                    CoinService
                        .streakRewards[
                    index];

                    final completed =
                        current >= day;

                    final active =
                        !claimedToday &&
                            day ==
                                nextDay;

                    return Expanded(
                      child: Padding(
                        padding:
                        EdgeInsets.only(
                          right:
                          day == 7
                              ? 0
                              : 5,
                        ),
                        child:
                        _StreakDay(
                          day: day,
                          reward: reward,
                          completed:
                          completed,
                          active: active,
                          primary:
                          colors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              // ============================================================
              // CLAIM BUTTON
              // ============================================================

              if (!claimedToday)
                SizedBox(
                  width:
                  double.infinity,
                  height: 46,
                  child:
                  FilledButton(
                    onPressed:
                    _claiming
                        ? null
                        : _claimReward,
                    style:
                    FilledButton
                        .styleFrom(
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                      ),
                    ),
                    child:
                    _claiming
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color:
                        Colors.white,
                      ),
                    )
                        : Text(
                      'CLAIM +$nextReward COINS',
                      style:
                      const TextStyle(
                        fontSize:
                        10.5,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 12,
                  ),
                  decoration:
                  BoxDecoration(
                    color: colors.surface
                        .withValues(
                      alpha: 0.7,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                  ),
                  child:
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                        colors.primary,
                        size: 17,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Today\'s reward claimed',
                        style:
                        TextStyle(
                          color:
                          colors.primary,
                          fontSize: 10.5,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 9,
              ),

              Center(
                child: Text(
                  claimedToday
                      ? 'Come back tomorrow to continue your streak.'
                      : 'Keep coming back every day for bigger rewards.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// STREAK DAY
// ============================================================================

class _StreakDay
    extends StatelessWidget {
  final int day;
  final int reward;
  final bool completed;
  final bool active;
  final Color primary;

  const _StreakDay({
    required this.day,
    required this.reward,
    required this.completed,
    required this.active,
    required this.primary,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Column(
      children: [
        Text(
          'D$day',
          style: TextStyle(
            color:
            colors.onSurfaceVariant,
            fontSize: 7.5,
            fontWeight:
            FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 200,
          ),
          width: 31,
          height: 31,
          decoration:
          BoxDecoration(
            color: completed
                ? primary
                : active
                ? primary
                .withValues(
              alpha: 0.13,
            )
                : colors.surface,
            shape:
            BoxShape.circle,
            border: active
                ? Border.all(
              color: primary,
              width: 1.5,
            )
                : null,
          ),
          child: Center(
            child: completed
                ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            )
                : Text(
              '+$reward',
              style: TextStyle(
                color: active
                    ? primary
                    : colors
                    .onSurfaceVariant,
                fontSize: 7,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          '$reward',
          style: TextStyle(
            color: completed
                ? primary
                : colors
                .onSurfaceVariant,
            fontSize: 7.5,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ],
    );
  }
}