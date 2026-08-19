import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinException implements Exception {
  final String message;

  const CoinException(this.message);

  @override
  String toString() => message;
}

class StreakReward {
  final int day;
  final int coins;
  final int currentStreak;
  final bool claimedToday;

  const StreakReward({
    required this.day,
    required this.coins,
    required this.currentStreak,
    required this.claimedToday,
  });
}

class CoinService {
  CoinService._();

  static final CoinService instance = CoinService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // DAILY STREAK REWARDS
  // ============================================================

  static const List<int> streakRewards = [
    2,  // Day 1
    4,  // Day 2
    6,  // Day 3
    8,  // Day 4
    10, // Day 5
    15, // Day 6
    30, // Day 7
  ];

  // ============================================================
  // AUTH
  // ============================================================

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  // ============================================================
  // USER REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>> _userRef(
      String uid,
      ) {
    return _firestore
        .collection('users')
        .doc(uid);
  }

  // ============================================================
  // ENSURE WALLET
  // ============================================================

  Future<void> ensureWallet() async {
    final user = currentUser;

    if (user == null) {
      throw const CoinException(
        'Please sign in first.',
      );
    }

    final ref = _userRef(user.uid);

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set(
        {
          'coins': 10,

          'streakCurrent': 0,
          'streakLongest': 0,

          'lastStreakClaimAt': null,
          'lastStreakClaimDate': null,

          'createdAt':
          FieldValue.serverTimestamp(),

          'updatedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    final data = snapshot.data() ?? {};

    final updates =
    <String, dynamic>{};

    if (!data.containsKey('coins')) {
      updates['coins'] = 10;
    }

    if (!data.containsKey('streakCurrent')) {
      updates['streakCurrent'] = 0;
    }

    if (!data.containsKey('streakLongest')) {
      updates['streakLongest'] = 0;
    }

    if (!data.containsKey(
      'lastStreakClaimAt',
    )) {
      updates['lastStreakClaimAt'] = null;
    }

    if (!data.containsKey(
      'lastStreakClaimDate',
    )) {
      updates['lastStreakClaimDate'] = null;
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] =
          FieldValue.serverTimestamp();

      await ref.set(
        updates,
        SetOptions(merge: true),
      );
    }
  }

  // ============================================================
  // COIN STREAM
  // ============================================================

  Stream<int> watchCoins() {
    final user = currentUser;

    if (user == null) {
      return Stream<int>.value(0);
    }

    return _userRef(user.uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      final value = data['coins'];

      if (value is int) {
        return value;
      }

      return int.tryParse(
        value?.toString() ?? '',
      ) ??
          0;
    });
  }

  // ============================================================
  // GET COINS
  // ============================================================

  Future<int> getCoins() async {
    final user = currentUser;

    if (user == null) {
      return 0;
    }

    final snapshot =
    await _userRef(user.uid).get();

    final data =
        snapshot.data() ?? {};

    return int.tryParse(
      data['coins']?.toString() ?? '0',
    ) ??
        0;
  }

  // ============================================================
  // SPEND ONE COIN
  // ============================================================

  Future<void> spendCoin() async {
    final user = currentUser;

    if (user == null) {
      throw const CoinException(
        'Please sign in first.',
      );
    }

    final ref = _userRef(user.uid);

    await _firestore.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(ref);

        final data =
            snapshot.data() ?? {};

        final coins =
            int.tryParse(
              data['coins']
                  ?.toString() ??
                  '0',
            ) ??
                0;

        if (coins <= 0) {
          throw const CoinException(
            'You do not have enough coins.',
          );
        }

        transaction.update(
          ref,
          {
            'coins': coins - 1,
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // ADD ONE COIN
  // ============================================================

  Future<void> grantRewardCoin() async {
    final user = currentUser;

    if (user == null) {
      throw const CoinException(
        'Please sign in first.',
      );
    }

    final ref = _userRef(user.uid);

    await _firestore.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(ref);

        final data =
            snapshot.data() ?? {};

        final coins =
            int.tryParse(
              data['coins']
                  ?.toString() ??
                  '0',
            ) ??
                0;

        transaction.set(
          ref,
          {
            'coins': coins + 1,
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      },
    );
  }

  // ============================================================
  // STREAK STREAM
  // ============================================================

  Stream<Map<String, dynamic>> watchStreak() {
    final user = currentUser;

    if (user == null) {
      return Stream<
          Map<String, dynamic>>.value(
        {
          'current': 0,
          'longest': 0,
          'claimedToday': false,
          'nextDay': 1,
          'nextReward': streakRewards[0],
        },
      );
    }

    return _userRef(user.uid)
        .snapshots()
        .map((snapshot) {
      final data =
          snapshot.data() ?? {};

      final current =
          int.tryParse(
            data['streakCurrent']
                ?.toString() ??
                '0',
          ) ??
              0;

      final longest =
          int.tryParse(
            data['streakLongest']
                ?.toString() ??
                '0',
          ) ??
              0;

      final lastClaimDate =
      data['lastStreakClaimDate']
          ?.toString();

      final today =
      _dateKey(DateTime.now());

      final claimedToday =
          lastClaimDate == today;

      int nextDay;

      if (claimedToday) {
        nextDay =
        current >= 7
            ? 1
            : current + 1;
      } else {
        nextDay =
        current >= 7
            ? 1
            : current + 1;
      }

      return {
        'current': current,
        'longest': longest,
        'claimedToday': claimedToday,
        'nextDay': nextDay,
        'nextReward':
        streakRewards[nextDay - 1],
      };
    });
  }

  // ============================================================
  // CLAIM DAILY STREAK
  // ============================================================

  Future<StreakReward>
  claimDailyStreak() async {
    final user = currentUser;

    if (user == null) {
      throw const CoinException(
        'Please sign in to claim your daily reward.',
      );
    }

    final ref = _userRef(user.uid);

    final now = DateTime.now();

    final today =
    _dateKey(now);

    final yesterday =
    _dateKey(
      now.subtract(
        const Duration(days: 1),
      ),
    );

    late StreakReward result;

    await _firestore.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(ref);

        final data =
            snapshot.data() ?? {};

        final lastClaimDate =
        data['lastStreakClaimDate']
            ?.toString();

        // --------------------------------------------------------
        // ALREADY CLAIMED
        // --------------------------------------------------------

        if (lastClaimDate == today) {
          throw const CoinException(
            'You have already claimed today.',
          );
        }

        int currentStreak =
            int.tryParse(
              data['streakCurrent']
                  ?.toString() ??
                  '0',
            ) ??
                0;

        int longestStreak =
            int.tryParse(
              data['streakLongest']
                  ?.toString() ??
                  '0',
            ) ??
                0;

        // --------------------------------------------------------
        // CONTINUE STREAK
        // --------------------------------------------------------

        if (lastClaimDate == yesterday) {
          currentStreak++;

          if (currentStreak > 7) {
            currentStreak = 1;
          }
        }

        // --------------------------------------------------------
        // BROKEN / NEW STREAK
        // --------------------------------------------------------

        else {
          currentStreak = 1;
        }

        final rewardCoins =
        streakRewards[
        currentStreak - 1];

        if (currentStreak >
            longestStreak) {
          longestStreak =
              currentStreak;
        }

        final currentCoins =
            int.tryParse(
              data['coins']
                  ?.toString() ??
                  '0',
            ) ??
                0;

        transaction.set(
          ref,
          {
            'coins':
            currentCoins +
                rewardCoins,

            'streakCurrent':
            currentStreak,

            'streakLongest':
            longestStreak,

            'lastStreakClaimAt':
            FieldValue.serverTimestamp(),

            'lastStreakClaimDate':
            today,

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        result = StreakReward(
          day: currentStreak,
          coins: rewardCoins,
          currentStreak:
          currentStreak,
          claimedToday: true,
        );
      },
    );

    return result;
  }

  // ============================================================
  // DATE KEY
  // ============================================================

  String _dateKey(DateTime date) {
    final year =
    date.year.toString();

    final month =
    date.month
        .toString()
        .padLeft(2, '0');

    final day =
    date.day
        .toString()
        .padLeft(2, '0');

    return '$year-$month-$day';
  }
}