import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/coins/coin_service.dart';

class DailyStreakCard extends StatefulWidget {
  const DailyStreakCard({
    super.key,
  });

  @override
  State<DailyStreakCard> createState() => _DailyStreakCardState();
}

class _DailyStreakCardState extends State<DailyStreakCard> {
  bool _claiming = false;

  // Helper for safe integer parsing
  int _intValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _claimReward() async {
    if (_claiming) return;

    setState(() {
      _claiming = true;
    });

    try {
      final reward = await CoinService.instance.claimDailyStreak();

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      _showRewardDialog(reward);
    } on CoinException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } catch (e) {
      debugPrint('Daily streak error: $e');

      if (!mounted) return;

      _showMessage('Could not claim your reward. Please try again.');
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
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 18),
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

  void _showRewardDialog(StreakReward reward) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
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
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary,
                            colors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${reward.currentStreak} Day Streak!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${reward.coins}',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.monetization_on_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'COINS ADDED',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Keep logging in daily to reach bigger milestone rewards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      elevation: 2,
                      shadowColor: colors.primary.withValues(alpha: 0.3),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<Map<String, dynamic>>(
      stream: CoinService.instance.watchStreak(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};

        final rawCurrent = _intValue(data['current']);
        final claimedToday = (data['claimedToday'] as bool?) ?? false;
        final rawNextDay = _intValue(data['nextDay']);

        // Check if streak was reset due to missed day
        final bool streakBroken = data['streakBroken'] == true ||
            (!claimedToday && rawNextDay == 1 && rawCurrent > 0);

        final current = streakBroken ? 0 : rawCurrent;
        final nextDay = (streakBroken ? 1 : (rawNextDay > 0 ? rawNextDay : 1))
            .clamp(1, 7);

        final nextReward = (data['nextReward'] as int?) ??
            CoinService.streakRewards[nextDay - 1];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.20),
                          colors.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY STREAK',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          streakBroken
                              ? 'Streak reset — Start Day 1'
                              : (current == 0
                              ? 'Start your daily streak'
                              : '$current day${current == 1 ? '' : 's'} streak active 🔥'),
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: claimedToday
                          ? colors.primary.withValues(alpha: 0.10)
                          : colors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: claimedToday
                          ? []
                          : [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!claimedToday) ...[
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          claimedToday ? 'CLAIMED' : '+$nextReward COINS',
                          style: TextStyle(
                            color: claimedToday ? colors.primary : Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (streakBroken) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: colors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A day was missed. Claim today to begin a new streak!',
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ============================================================
              // 7 DAY REWARD TRACK
              // ============================================================
              Row(
                children: List.generate(
                  7,
                      (index) {
                    final day = index + 1;
                    final reward = CoinService.streakRewards[index];
                    final completed = current >= day;
                    final active = !claimedToday && day == nextDay;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: day == 7 ? 0 : 6),
                        child: _StreakDay(
                          day: day,
                          reward: reward,
                          completed: completed,
                          active: active,
                          primary: colors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // CLAIM BUTTON
              // ============================================================
              if (!claimedToday)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _claiming ? null : _claimReward,
                    icon: _claiming
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _claiming ? 'Claiming Reward...' : 'Claim +$nextReward Coins',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      elevation: 3,
                      shadowColor: colors.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Today's reward collected",
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  claimedToday
                      ? 'Come back tomorrow to keep your streak going.'
                      : 'Maintain your daily visits for maximum coin bonuses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
// STREAK DAY NODE
// ============================================================================

class _StreakDay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'D$day',
          style: TextStyle(
            color: active
                ? primary
                : (completed ? colors.onSurface : colors.onSurfaceVariant),
            fontSize: 10.5,
            fontWeight: active || completed ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 40,
          decoration: BoxDecoration(
            color: completed
                ? primary
                : active
                ? primary.withValues(alpha: 0.15)
                : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? primary
                  : completed
                  ? primary
                  : colors.outline.withValues(alpha: 0.16),
              width: active ? 2 : 1,
            ),
            boxShadow: active
                ? [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ]
                : (completed
                ? [
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ]
                : null),
          ),
          child: Center(
            child: completed
                ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            )
                : active
                ? Icon(
              Icons.local_fire_department_rounded,
              color: primary,
              size: 18,
            )
                : Icon(
              Icons.lock_outline_rounded,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              size: 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '+$reward',
          style: TextStyle(
            color: completed || active ? primary : colors.onSurfaceVariant,
            fontSize: 10,
            fontWeight:
            completed || active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}