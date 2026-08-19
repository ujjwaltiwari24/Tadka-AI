import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_service.dart';

class CoinService {
  CoinService._();

  static final CoinService instance = CoinService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const int welcomeCoins = 10;
  static const int rewardCoinsPerAd = 1;
  static const int dailyRewardAdLimit = 10;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  User? get currentUser =>
      AuthService.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final user = currentUser;
    if (user == null) return null;

    return _users.doc(user.uid);
  }

  Future<int> ensureWallet() async {
    final document = _userDocument;

    if (document == null) {
      throw const CoinException(
        'Please sign in to use TADKA Coins.',
      );
    }

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (!snapshot.exists) {
        transaction.set(
          document,
          {
            'coins': welcomeCoins,
            'coinWalletCreatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return welcomeCoins;
      }

      final data = snapshot.data() ?? {};
      final existingCoins = _toInt(data['coins']);

      if (!data.containsKey('coins')) {
        transaction.update(
          document,
          {
            'coins': welcomeCoins,
            'coinWalletCreatedAt':
            FieldValue.serverTimestamp(),
          },
        );

        return welcomeCoins;
      }

      return existingCoins;
    });
  }

  Future<int> getCoins() async {
    final document = _userDocument;

    if (document == null) return 0;

    final snapshot = await document.get();

    if (!snapshot.exists) {
      return ensureWallet();
    }

    final data = snapshot.data() ?? {};

    if (!data.containsKey('coins')) {
      return ensureWallet();
    }

    return _toInt(data['coins']);
  }

  Stream<int> watchCoins() {
    final document = _userDocument;

    if (document == null) {
      return Stream<int>.value(0);
    }

    return document.snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;

      final data = snapshot.data() ?? {};
      return _toInt(data['coins']);
    });
  }

  Future<int> spendCoin() async {
    final document = _userDocument;

    if (document == null) {
      throw const CoinException(
        'Please sign in to use TADKA Coins.',
      );
    }

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (!snapshot.exists) {
        throw const CoinException(
          'Your coin wallet could not be found.',
        );
      }

      final data = snapshot.data() ?? {};
      final coins = _toInt(data['coins']);

      if (coins <= 0) {
        throw const CoinException(
          'You do not have enough TADKA Coins.',
        );
      }

      final updatedCoins = coins - 1;

      transaction.update(
        document,
        {
          'coins': updatedCoins,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      return updatedCoins;
    });
  }

  Future<int> grantRewardCoin() async {
    final document = _userDocument;

    if (document == null) {
      throw const CoinException(
        'Please sign in to earn TADKA Coins.',
      );
    }

    final today = _dateKey(DateTime.now());

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (!snapshot.exists) {
        transaction.set(
          document,
          {
            'coins': welcomeCoins,
            'coinWalletCreatedAt':
            FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        throw const CoinException(
          'Your coin wallet was just created. Please try the ad again.',
        );
      }

      final data = snapshot.data() ?? {};

      final previousDate =
          data['rewardedAdDate']?.toString() ?? '';

      var adsToday = _toInt(
        data['rewardedAdsToday'],
      );

      if (previousDate != today) {
        adsToday = 0;
      }

      if (adsToday >= dailyRewardAdLimit) {
        throw const CoinException(
          'You have reached today’s ad reward limit. Come back tomorrow.',
        );
      }

      final coins = _toInt(data['coins']);
      final updatedCoins = coins + rewardCoinsPerAd;

      transaction.update(
        document,
        {
          'coins': updatedCoins,
          'rewardedAdsToday': adsToday + 1,
          'rewardedAdDate': today,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      return updatedCoins;
    });
  }

  Future<int> watchAdAndUnlock() async {
    throw const CoinException(
      'Use RewardedAdService to show the ad, then call grantRewardCoin() '
          'and spendCoin() after the reward callback.',
    );
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}

class CoinException implements Exception {
  final String message;

  const CoinException(this.message);

  @override
  String toString() => message;
}
