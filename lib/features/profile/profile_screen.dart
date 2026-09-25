import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ads/rewarded_ad_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/coins/coin_service.dart';
import '../auth/auth_screen.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_results_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isLoadingAd = false;

  User? get _user => AuthService.instance.currentUser;

  /// Returns today's date string in `YYYY-MM-DD` format.
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _watchAdAndEarnCoin() async {
    final user = _user;

    if (user == null) {
      await _signIn();
      return;
    }

    if (_isLoadingAd) return;

    setState(() {
      _isLoadingAd = true;
    });

    try {
      final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnap = await userDocRef.get();
      final data = docSnap.data() ?? {};

      final lastAdDate = data['rewardedAdDate'] as String? ?? '';
      int currentCount = (data['rewardedAdsToday'] as int?) ?? 0;

      if (lastAdDate != _todayKey) {
        currentCount = 0;
      }

      if (currentCount >= 10) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have claimed all 10 TADKA coins for today!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.grey.shade900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        return;
      }

      await CoinService.instance.ensureWallet();

      final rewarded = await RewardedAdService.instance.showRewardedAd();

      if (!rewarded) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'The rewarded ad isn\'t ready yet. Please try again in a moment.',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

        return;
      }

      await userDocRef.set({
        'rewardedAdDate': _todayKey,
        'rewardedAdsToday': lastAdDate == _todayKey ? FieldValue.increment(1) : 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await CoinService.instance.grantRewardCoin();

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.stars_rounded, color: Color(0xFFFFC107), size: 22),
                SizedBox(width: 10),
                Text(
                  '+1 TADKA Coin added to your wallet!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    } on CoinException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Rewarded coin error: $e');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to process reward right now. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Your cookbook and saved recipes will remain securely synchronized with your account.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) return;

    await AuthService.instance.signOut();

    if (!mounted) return;

    setState(() {});
    HapticFeedback.mediumImpact();
  }

  Recipe _recipeFromDocument(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data() ?? {};

    return Recipe.fromJson({
      ...data,
      'imageUrl': data['imageUrl']?.toString() ?? '',
    });
  }

  Future<void> _openRecipe(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) async {
    final recipe = _recipeFromDocument(document);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          isUnlocked: true,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F0),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.06),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
              ),
            ),
          ),
        ),
        title: const Text(
          'Profile & Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          user == null
              ? _SignedOutProfile(
            onSignIn: _signIn,
          )
              : _SignedInProfile(
            user: user,
            todayKey: _todayKey,
            searchController: _searchController,
            searchQuery: _searchQuery,
            isLoadingAd: _isLoadingAd,
            onSignOut: _signOut,
            onOpenRecipe: _openRecipe,
            onWatchAdAndEarn: _watchAdAndEarnCoin,
          ),
          if (_isLoadingAd)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  color: Theme.of(context).colorScheme.primary,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12),
                                ),
                              ),
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Preparing Rewarded Ad...',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please hold on a moment',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// SIGNED OUT
// ============================================================================

class _SignedOutProfile extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignedOutProfile({
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colors.primary.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withOpacity(0.16),
                        colors.primary.withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    color: colors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your TADKA Kitchen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to build your personal cookbook, save delicious culinary creations, and earn daily TADKA unlock coins.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(
                      Icons.login_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _FeatureTile(
            icon: Icons.bookmark_add_rounded,
            title: 'Personal Cookbook',
            subtitle: 'Save and organize all your unlocked favorite recipes in one place.',
          ),
          const SizedBox(height: 12),
          const _FeatureTile(
            icon: Icons.monetization_on_rounded,
            title: 'Earn Daily Coins',
            subtitle: 'Watch short ads daily to earn coins and unlock exciting premium dishes.',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SIGNED IN
// ============================================================================

class _SignedInProfile extends StatelessWidget {
  final User user;
  final String todayKey;
  final TextEditingController searchController;
  final String searchQuery;
  final bool isLoadingAd;
  final VoidCallback onSignOut;
  final Future<void> Function(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) onOpenRecipe;
  final Future<void> Function() onWatchAdAndEarn;

  const _SignedInProfile({
    required this.user,
    required this.todayKey,
    required this.searchController,
    required this.searchQuery,
    required this.isLoadingAd,
    required this.onSignOut,
    required this.onOpenRecipe,
    required this.onWatchAdAndEarn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedRecipes')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final documents = snapshot.data?.docs ?? [];

        final filtered = documents.where((document) {
          if (searchQuery.isEmpty) return true;

          final data = document.data();
          final name = data['name']?.toString().toLowerCase() ?? '';

          return name.contains(searchQuery);
        }).toList();

        return RefreshIndicator(
          color: colors.primary,
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(milliseconds: 450),
            );
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _ProfileHeader(
                        user: user,
                        onSignOut: onSignOut,
                      ),
                      const SizedBox(height: 14),
                      _CoinWalletCard(
                        user: user,
                        todayKey: todayKey,
                        isLoadingAd: isLoadingAd,
                        onWatchAdAndEarn: onWatchAdAndEarn,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Cookbook',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${documents.length} ${documents.length == 1 ? 'recipe' : 'recipes'}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (documents.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.025),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search your cookbook...',
                          hintStyle: TextStyle(
                            color: colors.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                            onPressed: searchController.clear,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (snapshot.hasError)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorCard(
                      message: snapshot.error.toString(),
                    ),
                  ),
                )
              else if (documents.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 32, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyCookbook(),
                  ),
                )
              else if (filtered.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 32, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: _NoSearchResults(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SavedRecipeCard(
                          document: filtered[index],
                          onTap: () => onOpenRecipe(filtered[index]),
                        );
                      },
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
// PROFILE HEADER
// ============================================================================

class _ProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onSignOut;

  const _ProfileHeader({
    required this.user,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.primary.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TADKA CHEF',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!
                      : 'Master Chef',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: onSignOut,
              tooltip: 'Sign out',
              icon: Icon(
                Icons.logout_rounded,
                color: colors.onSurfaceVariant,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final User user;

  const _Avatar({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photo = user.photoURL;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withOpacity(0.08),
        border: Border.all(
          color: colors.primary.withOpacity(0.2),
          width: 2.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.trim().isNotEmpty
          ? Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Icon(
            Icons.person_rounded,
            color: colors.primary,
            size: 30,
          );
        },
      )
          : Icon(
        Icons.person_rounded,
        color: colors.primary,
        size: 30,
      ),
    );
  }
}

// ============================================================================
// COIN WALLET
// ============================================================================

class _CoinWalletCard extends StatelessWidget {
  final User user;
  final String todayKey;
  final bool isLoadingAd;
  final Future<void> Function() onWatchAdAndEarn;

  const _CoinWalletCard({
    required this.user,
    required this.todayKey,
    required this.isLoadingAd,
    required this.onWatchAdAndEarn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<int>(
      stream: CoinService.instance.watchCoins(),
      builder: (context, coinSnapshot) {
        final coins = coinSnapshot.data ?? 0;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() ?? {};
            final lastAdDate = userData['rewardedAdDate'] as String? ?? '';
            final rawCount = (userData['rewardedAdsToday'] as int?) ?? 0;

            final adsWatchedToday = (lastAdDate == todayKey) ? rawCount : 0;
            final isDailyLimitReached = adsWatchedToday >= 10;
            final progress = (adsWatchedToday / 10).clamp(0.0, 1.0);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2C1810),
                    Color(0xFF1A0F0A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C1810).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFB300).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFFFC107),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TADKA Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1 coin unlocks 1 premium recipe',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFFFFC107),
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_fill_rounded,
                              color: isDailyLimitReached
                                  ? Colors.grey.shade500
                                  : colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDailyLimitReached
                                        ? 'Daily Ad Limit Reached'
                                        : 'Earn Coins via Ads',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$adsWatchedToday of 10 ads watched today',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                onPressed: (isDailyLimitReached || isLoadingAd)
                                    ? null
                                    : onWatchAdAndEarn,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  disabledBackgroundColor:
                                  Colors.white.withOpacity(0.12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isDailyLimitReached ? '10/10 Done' : 'Watch Ad',
                                  style: TextStyle(
                                    color: isDailyLimitReached
                                        ? Colors.white.withOpacity(0.4)
                                        : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDailyLimitReached
                                  ? const Color(0xFF10B981)
                                  : colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// SAVED RECIPE CARD
// ============================================================================

class _SavedRecipeCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onTap;

  const _SavedRecipeCard({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final data = document.data() ?? {};

    final name = data['name']?.toString() ?? 'Recipe';
    final description = data['description']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final time = data['timeMinutes']?.toString() ?? '0';
    final difficulty = data['difficulty']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.outline.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 120,
                child: imageUrl.trim().isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _ImageFallback(
                      primary: colors.primary,
                    );
                  },
                )
                    : _ImageFallback(
                  primary: colors.primary,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.bookmark_rounded,
                            color: colors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant.withOpacity(0.85),
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _SmallPill(
                            icon: Icons.schedule_rounded,
                            text: '$time min',
                            color: colors.primary,
                          ),
                          if (difficulty.isNotEmpty)
                            _SmallPill(
                              icon: Icons.bar_chart_rounded,
                              text: difficulty,
                              color: colors.primary,
                            ),
                        ],
                      ),
                    ],
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

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SmallPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATES & TILES
// ============================================================================

class _EmptyCookbook extends StatelessWidget {
  const _EmptyCookbook();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: colors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your Cookbook is Empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore recipes and tap the bookmark icon to save dishes directly into your private collection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant.withOpacity(0.8),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 44,
          color: colors.onSurfaceVariant.withOpacity(0.4),
        ),
        const SizedBox(height: 12),
        const Text(
          'No Matching Saved Recipes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Try searching with a different recipe title.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8B9B3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB3261E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not sync your cookbook. Please try again.',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outline.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
}

class _ImageFallback extends StatelessWidget {
  final Color primary;

  const _ImageFallback({
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withOpacity(0.08),
      child: Icon(
        Icons.restaurant_rounded,
        color: primary.withOpacity(0.5),
        size: 34,
      ),
    );
  }
}