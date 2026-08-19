import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth/auth_service.dart';
import '../../services/coins/coin_service.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../auth/auth_screen.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_results_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  User? get _user => AuthService.instance.currentUser;

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

    try {
      await CoinService.instance.ensureWallet();

      final rewarded = await RewardedAdService.instance
          .showRewardedAd();

      if (!rewarded) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'The reward ad is not ready. Please try again.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

        return;
      }

      await CoinService.instance.grantRewardCoin();

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 +1 TADKA Coin added to your wallet!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      setState(() {});
    } on CoinException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Rewarded coin error: $e');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not add your reward. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Sign out?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Your saved recipes will remain safely stored in your TADKA account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign out'),
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
    final colors = Theme.of(context).colorScheme;
    final user = _user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F1),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: user == null
          ? _SignedOutProfile(
        onSignIn: _signIn,
      )
          : _SignedInProfile(
        user: user,
        searchController: _searchController,
        searchQuery: _searchQuery,
        onSignOut: _signOut,
        onOpenRecipe: _openRecipe,
        onWatchAdAndEarn: _watchAdAndEarnCoin,
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.13),
                  colors.primary.withValues(alpha: 0.035),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.13),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: colors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your TADKA account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to save recipes and build your personal cookbook.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(
                      Icons.login_rounded,
                      size: 19,
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _FeatureTile(
            icon: Icons.bookmark_rounded,
            title: 'Save recipes',
            subtitle: 'Keep your favourite recipes in one place.',
          ),
          const SizedBox(height: 10),
          const _FeatureTile(
            icon: Icons.sync_rounded,
            title: 'Sync your cookbook',
            subtitle: 'Your saved recipes stay with your account.',
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
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onSignOut;
  final Future<void> Function(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) onOpenRecipe;
  final Future<void> Function() onWatchAdAndEarn;

  const _SignedInProfile({
    required this.user,
    required this.searchController,
    required this.searchQuery,
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
          final name =
              data['name']?.toString().toLowerCase() ?? '';

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _ProfileHeader(
                        user: user,
                        onSignOut: onSignOut,
                      ),
                      const SizedBox(height: 12),
                      _CoinWalletCard(
                        user: user,
                        onWatchAdAndEarn: onWatchAdAndEarn,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My Cookbook',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${documents.length} ${documents.length == 1 ? 'recipe' : 'recipes'}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 10,
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
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search your cookbook...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 21,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                          onPressed: searchController.clear,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 19,
                          ),
                        )
                            : null,
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: BorderSide(
                            color: colors.outline.withValues(alpha: 0.10),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: BorderSide(
                            color: colors.outline.withValues(alpha: 0.10),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: BorderSide(
                            color: colors.primary.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (snapshot.hasError)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorCard(
                      message: snapshot.error.toString(),
                    ),
                  ),
                )
              else if (documents.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyCookbook(),
                  ),
                )
              else if (filtered.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: _NoSearchResults(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 13),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.primary.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!
                      : 'TADKA Chef',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSignOut,
            tooltip: 'Sign out',
            icon: Icon(
              Icons.logout_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
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
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withValues(alpha: 0.11),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
          width: 2,
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
            size: 28,
          );
        },
      )
          : Icon(
        Icons.person_rounded,
        color: colors.primary,
        size: 28,
      ),
    );
  }
}

// ============================================================================
// COIN WALLET
// ============================================================================

class _CoinWalletCard extends StatelessWidget {
  final User user;
  final Future<void> Function() onWatchAdAndEarn;

  const _CoinWalletCard({
    required this.user,
    required this.onWatchAdAndEarn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<int>(
      stream: CoinService.instance.watchCoins(),
      builder: (context, snapshot) {
        final coins = snapshot.data ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFB300).withValues(alpha: 0.15),
                colors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: const Color(0xFFE5A000).withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300)
                          .withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFE29A00),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TADKA Coins',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '1 coin unlocks 1 recipe',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: colors.outline.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFE29A00),
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$coins',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  13,
                  11,
                  13,
                  11,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Earn 1 coin by watching an ad',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Up to 10 rewarded ads every day',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: onWatchAdAndEarn,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Watch Ad',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
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
    final description =
        data['description']?.toString() ?? '';
    final imageUrl =
        data['imageUrl']?.toString() ?? '';
    final time =
        data['timeMinutes']?.toString() ?? '0';
    final difficulty =
        data['difficulty']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 118,
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
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    13,
                    12,
                    13,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.bookmark_rounded,
                            color: colors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
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
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
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
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATES
// ============================================================================

class _EmptyCookbook extends StatelessWidget {
  const _EmptyCookbook();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: colors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cookbook is empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Find a recipe you love and tap the bookmark icon. It will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.45,
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
          size: 42,
          color: colors.onSurfaceVariant.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 10),
        const Text(
          'No saved recipes found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Try a different recipe name.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 11,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load your cookbook. Please try again.',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 11,
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
      padding: const EdgeInsets.all(14),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
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
}

class _ImageFallback extends StatelessWidget {
  final Color primary;

  const _ImageFallback({
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.restaurant_rounded,
        color: primary.withValues(alpha: 0.65),
        size: 32,
      ),
    );
  }
}
