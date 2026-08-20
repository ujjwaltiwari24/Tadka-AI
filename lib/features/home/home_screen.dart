import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../legal/legal_screens.dart';
import '../auth/auth_screen.dart';
import '../ingredients/ingredients_screen.dart';
import '../recipes/search_recipe_screen.dart';
import '../profile/profile_screen.dart';
import '../cookbook/cookbook_screen.dart';
import '../streak/daily_streak_screen.dart';
import '../../services/coins/coin_service.dart';
import '../../services/auth/auth_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ============================================================================
// RECENT DISH MODEL
// ============================================================================

class _RecentDish {
  final String id;
  final String name;
  final String category;
  final String imageUrl;

  const _RecentDish({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
  });

  factory _RecentDish.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data() ?? {};

    String imageUrl = '';

    final primaryImage =
        data['primaryImageUrl']?.toString().trim() ?? '';

    if (primaryImage.isNotEmpty) {
      imageUrl = primaryImage;
    } else {
      final imageUrls = data['imageUrls'];

      if (imageUrls is List && imageUrls.isNotEmpty) {
        imageUrl = imageUrls.first.toString().trim();
      }
    }

    return _RecentDish(
      id: document.id,
      name: data['name']?.toString().trim() ?? '',
      category:
      data['category']?.toString().trim() ?? 'Other',
      imageUrl: imageUrl,
    );
  }
}

// ============================================================================
// HOME STATE
// ============================================================================

class _HomeScreenState extends State<HomeScreen> {
  String _selectedQuickOption = '';


  List<_RecentDish> _recentDishes = [];
  bool _recentDishesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentDishes();
  }

// ==========================================================================
// NAVIGATION
// ==========================================================================

  void _openIngredients() {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IngredientsScreen(),
      ),
    );
  }

  void _openDishSearch() {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchRecipeScreen(),
      ),
    );
  }

  void _openRecentDish(String dishName) {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchRecipeScreen(
          initialDish: dishName,
        ),
      ),
    );
  }

// ==========================================================================
// PROFILE
// ==========================================================================

  Future<void> _openCookbook() async {
    HapticFeedback.selectionClick();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CookbookScreen(),
      ),
    );
  }

  Future<void> _openProfile() async {
    HapticFeedback.selectionClick();

    final signedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (signedIn == true && mounted) {
      setState(() {});
    }
  }

  void _showProfileSheet() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final photoUrl = user.photoURL?.trim() ?? '';
        final displayName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'TADKA User';
        final email = user.email?.trim() ?? '';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          color: colors.primary,
                          size: 29,
                        ),
                      )
                          : Icon(
                        Icons.person_rounded,
                        color: colors.primary,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _MenuTile(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Saved recipes',
                  subtitle: 'View your saved recipes',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openProfile();
                  },
                ),

                const SizedBox(height: 8),

                _MenuTile(
                  icon: Icons.gavel_rounded,
                  title: 'Legal',
                  subtitle: 'Privacy, terms and account policies',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPagesScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'Sign out of your TADKA account',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await AuthService.instance.signOut();
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openQuickPick(String option) {
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedQuickOption = option;
    });

    switch (option) {
      case 'Quick':
        _openIngredientsWithPreference(
          initialTime: '20 min',
        );
        break;

      case 'Vegan':
        _openIngredientsWithPreference(
          initialDiet: 'Vegan',
        );
        break;

      case 'Spicy':
        _openIngredientsWithPreference(
          initialSpice: 'Spicy',
        );
        break;

      case 'Beginner':
        _openIngredientsWithPreference(
          initialSkill: 'Beginner',
        );
        break;
    }
  }

  void _openIngredientsWithPreference({
    String? initialTime,
    String? initialDiet,
    String? initialSpice,
    String? initialSkill,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientsScreen(
          initialTime: initialTime,
          initialDiet: initialDiet,
          initialSpice: initialSpice,
          initialSkill: initialSkill,
        ),
      ),
    );
  }

// ==========================================================================
// FIRESTORE
// ==========================================================================

  Future<void> _loadRecentDishes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dishes')
          .orderBy(
        'createdAt',
        descending: true,
      )
          .limit(8)
          .get();

      final dishes = snapshot.docs
          .map(_RecentDish.fromFirestore)
          .where(
            (dish) => dish.name.isNotEmpty,
      )
          .toList();

      if (!mounted) return;

      setState(() {
        _recentDishes = dishes;
        _recentDishesLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Recent dishes error: $error',
      );

      if (!mounted) return;

      setState(() {
        _recentDishesLoading = false;
      });
    }
  }

  Future<void> _refreshHome() async {
    HapticFeedback.selectionClick();

    setState(() {
      _recentDishesLoading = true;
    });

    await _loadRecentDishes();
  }

// ==========================================================================
// MORE
// ==========================================================================

  void _showComingSoon(String feature) {
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature is coming soon.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          duration: const Duration(
            seconds: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showMoreMenu() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BottomSheetHeader(
                  title: 'More',
                  subtitle: 'TADKA AI',
                ),

                const SizedBox(height: 14),

                // SAVED RECIPES
                _MenuTile(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Saved recipes',
                  subtitle: 'View your saved recipes',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openProfile();
                  },
                ),

                const SizedBox(height: 8),

                // LEGAL
                _MenuTile(
                  icon: Icons.gavel_rounded,
                  title: 'Legal',
                  subtitle: 'Privacy, terms and account policies',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPagesScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // ABOUT
                _MenuTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About TADKA',
                  subtitle: 'Your AI cooking assistant',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showAboutDialog();
                  },
                ),

                const SizedBox(height: 8),

                // CLOSE
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),
          title: const Text(
            'TADKA AI',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Your AI cooking companion. '
                'Discover recipes from ingredients '
                'you already have or search for any dish.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

// ==========================================================================
// BUILD
// ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final textPrimary = colors.onSurface;
    final textSecondary =
        colors.onSurfaceVariant;

    final border = colors.outline.withValues(
      alpha: theme.brightness ==
          Brightness.dark
          ? 0.30
          : 0.13,
    );

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,

      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: _refreshHome,
          child: CustomScrollView(
            physics:
            const BouncingScrollPhysics(
              parent:
              AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  32,
                ),
                sliver: SliverList(
                  delegate:
                  SliverChildListDelegate(
                    [
// ======================================================
// HEADER
// ======================================================

                      _TopBar(
                        textPrimary: textPrimary,
                        primary: colors.primary,
                        signedIn:
                        AuthService.instance.isSignedIn,
                        photoUrl:
                        AuthService.instance.currentUser?.photoURL,
                        onProfile: _openProfile,
                      ),

                      const SizedBox(
                        height: 30,
                      ),

// ======================================================
// HERO
// ======================================================

                      _Greeting(
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                        primary:
                        colors.primary,
                      ),

                      const SizedBox(
                        height: 23,
                      ),

// ======================================================
// SEARCH ANY DISH
// ======================================================

                      _SearchDishCard(
                        primary:
                        colors.primary,
                        surface:
                        colors.surface,
                        border: border,
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                        onTap:
                        _openDishSearch,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

// ======================================================
// INGREDIENT CTA
// ======================================================

                      _MainActionCard(
                        primary:
                        colors.primary,
                        onTap:
                        _openIngredients,
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      const _DailyStreakHomeButton(),

                      const SizedBox(
                        height: 31,
                      ),

// ======================================================
// QUICK PICKS
// ======================================================

                      _SectionHeader(
                        title:
                        'Quick picks',
                        subtitle:
                        'Choose a starting point',
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                      ),

                      const SizedBox(
                        height: 13,
                      ),

                      _QuickOptions(
                        selected:
                        _selectedQuickOption,
                        primary:
                        colors.primary,
                        surface:
                        colors.surface,
                        border: border,
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                        onSelect:
                        _openQuickPick,
                      ),

                      const SizedBox(
                        height: 34,
                      ),

// ======================================================
// RECENTLY ADDED
// ======================================================

                      _RecentDishesSection(
                        dishes:
                        _recentDishes,
                        loading:
                        _recentDishesLoading,
                        primary:
                        colors.primary,
                        surface:
                        colors.surface,
                        border: border,
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                        onDishTap:
                        _openRecentDish,
                      ),

                      const SizedBox(
                        height: 34,
                      ),

// ======================================================
// MORE FEATURES
// ======================================================

                      _SectionHeader(
                        title:
                        'More from TADKA',
                        subtitle:
                        'More ways to cook smarter',
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _FeatureList(
                        primary:
                        colors.primary,
                        surface:
                        colors.surface,
                        border: border,
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                        onComingSoon:
                        _showComingSoon,
                      ),

                      const SizedBox(
                        height: 38,
                      ),

// ======================================================
// FOOTER
// ======================================================

                      _HomeFooter(
                        textSecondary:
                        textSecondary,
                        primary:
                        colors.primary,
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

// ============================================================================
// TOP BAR
// ============================================================================

class _TopBar extends StatelessWidget {
  final Color textPrimary;
  final Color primary;
  final bool signedIn;
  final String? photoUrl;
  final VoidCallback onProfile;

  const _TopBar({
    required this.textPrimary,
    required this.primary,
    required this.signedIn,
    required this.photoUrl,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
// Logo
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(
                  primary,
                  Colors.black,
                  0.18,
                ) ??
                    primary,
              ],
            ),
            borderRadius:
            BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                primary.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 13,
                offset:
                const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),

        const SizedBox(width: 11),

        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'TADKA',
              style: TextStyle(
                color: textPrimary,
                fontSize: 19,
                fontWeight:
                FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              'AI COOKING',
              style: TextStyle(
                color: textPrimary.withValues(
                  alpha: 0.40,
                ),
                fontSize: 7,
                fontWeight:
                FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
          ],
        ),

        const Spacer(),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.045),
                shape: BoxShape.circle,
                border: Border.all(
                  color: textPrimary.withValues(alpha: 0.07),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: signedIn &&
                  (photoUrl?.trim().isNotEmpty ?? false)
                  ? Image.network(
                photoUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_outline_rounded,
                  color: textPrimary,
                  size: 22,
                ),
              )
                  : Icon(
                signedIn
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                color: textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// GREETING
// ============================================================================

class _Greeting extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;

  const _Greeting({
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              greeting,
              style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        Text(
          'What are you\ncooking today?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 34,
            height: 1.04,
            fontWeight:
            FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),

        const SizedBox(height: 11),

        Text(
          'Find a recipe from what you have, '
              'or tell TADKA exactly what you want.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            height: 1.5,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SEARCH DISH
// ============================================================================

class _SearchDishCard
    extends StatelessWidget {
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _SearchDishCard({
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius:
      BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(21),
        child: Container(
          padding:
          const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(21),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topLeft,
                    end:
                    Alignment.bottomRight,
                    colors: [
                      primary.withValues(
                        alpha: 0.16,
                      ),
                      primary.withValues(
                        alpha: 0.06,
                      ),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search any dish',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask AI for the recipe you want',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN ACTION
// ============================================================================

class _MainActionCard extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary,
      borderRadius:
      BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(25),
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            20,
            18,
            18,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(25),
            gradient: LinearGradient(
              begin:
              Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(
                  primary,
                  Colors.black,
                  0.13,
                ) ??
                    primary,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                    ),
                    child: const Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 10,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI POWERED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing:
                            0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'What do you have?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Turn your ingredients into a recipe '
                    'made around what is already in your kitchen.',
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.80,
                  ),
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              const SizedBox(height: 19),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration:
                      BoxDecoration(
                        color: primary
                            .withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          9,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: primary,
                        size: 19,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        'Add ingredients',
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_rounded,
                      color: primary,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight:
            FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK OPTIONS
// ============================================================================

class _QuickOptions
    extends StatelessWidget {
  final String selected;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onSelect;

  const _QuickOptions({
    required this.selected,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (
      name: 'Quick',
      subtitle: '20 min',
      icon: Icons.bolt_rounded,
      ),
      (
      name: 'Vegan',
      subtitle: 'Plant-based',
      icon: Icons.eco_outlined,
      ),
      (
      name: 'Spicy',
      subtitle: 'Bring the heat',
      icon:
      Icons.local_fire_department_outlined,
      ),
      (
      name: 'Beginner',
      subtitle: 'Easy cooking',
      icon: Icons.school_outlined,
      ),
    ];

    return SizedBox(
      height: 91,
      child: ListView.separated(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 10),
        itemBuilder:
            (context, index) {
          final option = options[index];
          final isSelected =
              selected == option.name;

          return Material(
            color: Colors.transparent,
            borderRadius:
            BorderRadius.circular(17),
            child: InkWell(
              onTap: () =>
                  onSelect(option.name),
              borderRadius:
              BorderRadius.circular(17),
              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 180,
                ),
                width: 130,
                padding:
                const EdgeInsets.all(
                  13,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(
                    alpha: 0.10,
                  )
                      : surface,
                  borderRadius:
                  BorderRadius.circular(
                    17,
                  ),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : border,
                    width:
                    isSelected
                        ? 1.4
                        : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          option.icon,
                          color: isSelected
                              ? primary
                              : textSecondary,
                          size: 20,
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons
                                .check_circle_rounded,
                            color: primary,
                            size: 14,
                          ),
                      ],
                    ),

                    const Spacer(),

                    Text(
                      option.name,
                      style: TextStyle(
                        color: isSelected
                            ? primary
                            : textPrimary,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      option.subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// RECENT DISHES
// ============================================================================

class _RecentDishesSection
    extends StatelessWidget {
  final List<_RecentDish> dishes;
  final bool loading;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onDishTap;

  const _RecentDishesSection({
    required this.dishes,
    required this.loading,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onDishTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHeader(
                title:
                'Recently added',
                subtitle:
                'Fresh from the TADKA kitchen',
                textPrimary:
                textPrimary,
                textSecondary:
                textSecondary,
              ),
            ),

            if (!loading &&
                dishes.isNotEmpty)
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  '${dishes.length} new',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        if (loading)
          SizedBox(
            height: 207,
            child: ListView.separated(
              scrollDirection:
              Axis.horizontal,
              physics:
              const BouncingScrollPhysics(),
              itemCount: 3,
              separatorBuilder:
                  (_, __) =>
              const SizedBox(
                width: 12,
              ),
              itemBuilder: (_, __) {
                return _RecentDishSkeleton(
                  surface: surface,
                  border: border,
                );
              },
            ),
          )
        else if (dishes.isEmpty)
          _EmptyRecentDishes(
            primary: primary,
            surface: surface,
            border: border,
            textPrimary:
            textPrimary,
            textSecondary:
            textSecondary,
          )
        else
          SizedBox(
            height: 207,
            child: ListView.separated(
              scrollDirection:
              Axis.horizontal,
              physics:
              const BouncingScrollPhysics(),
              itemCount: dishes.length,
              separatorBuilder:
                  (_, __) =>
              const SizedBox(
                width: 12,
              ),
              itemBuilder:
                  (context, index) {
                return _RecentDishCard(
                  dish: dishes[index],
                  primary: primary,
                  surface: surface,
                  border: border,
                  textPrimary:
                  textPrimary,
                  textSecondary:
                  textSecondary,
                  onTap:
                  onDishTap,
                );
              },
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// RECENT DISH CARD
// ============================================================================

class _RecentDishCard
    extends StatelessWidget {
  final _RecentDish dish;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onTap;

  const _RecentDishCard({
    required this.dish,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      child: Material(
        color: surface,
        borderRadius:
        BorderRadius.circular(20),
        clipBehavior:
        Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(dish.name);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: border,
              ),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 123,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (dish.imageUrl
                          .isNotEmpty)
                        Image.network(
                          dish.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return _DishPlaceholder(
                              primary:
                              primary,
                            );
                          },
                          loadingBuilder:
                              (
                              context,
                              child,
                              progress,
                              ) {
                            if (progress ==
                                null) {
                              return child;
                            }

                            return _DishImageLoading(
                              primary:
                              primary,
                            );
                          },
                        )
                      else
                        _DishPlaceholder(
                          primary: primary,
                        ),

// Image gradient
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 65,
                        child: IgnorePointer(
                          child:
                          DecoratedBox(
                            decoration:
                            BoxDecoration(
                              gradient:
                              LinearGradient(
                                begin:
                                Alignment
                                    .topCenter,
                                end:
                                Alignment
                                    .bottomCenter,
                                colors: [
                                  Colors
                                      .transparent,
                                  Colors.black
                                      .withValues(
                                    alpha:
                                    0.45,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

// New badge
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            primary,
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child:
                          const Text(
                            'NEW',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontSize:
                              8,
                              fontWeight:
                              FontWeight
                                  .w900,
                              letterSpacing:
                              0.5,
                            ),
                          ),
                        ),
                      ),

// Arrow
                      Positioned(
                        right: 9,
                        bottom: 9,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration:
                          BoxDecoration(
                            color: Colors
                                .white
                                .withValues(
                              alpha: 0.94,
                            ),
                            shape:
                            BoxShape
                                .circle,
                          ),
                          child:
                          Icon(
                            Icons
                                .arrow_forward_rounded,
                            color:
                            primary,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      12,
                      10,
                      12,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          dish.name,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            color:
                            textPrimary,
                            fontSize:
                            13,
                            fontWeight:
                            FontWeight
                                .w900,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          dish.category,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            color:
                            textSecondary,
                            fontSize:
                            10,
                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),

                        const Spacer(),

                        Row(
                          children: [
                            Icon(
                              Icons
                                  .auto_awesome_rounded,
                              size: 11,
                              color:
                              primary,
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              'View recipe',
                              style:
                              TextStyle(
                                color:
                                primary,
                                fontSize:
                                9,
                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
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
      ),
    );
  }
}

// ============================================================================
// IMAGE PLACEHOLDER
// ============================================================================

class _DishPlaceholder
    extends StatelessWidget {
  final Color primary;

  const _DishPlaceholder({
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            primary.withValues(
              alpha: 0.10,
            ),
            primary.withValues(
              alpha: 0.03,
            ),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: 0.75,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_rounded,
            color: primary.withValues(
              alpha: 0.55,
            ),
            size: 25,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// IMAGE LOADING
// ============================================================================

class _DishImageLoading
    extends StatelessWidget {
  final Color primary;

  const _DishImageLoading({
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withValues(
        alpha: 0.06,
      ),
      child: Center(
        child:
        CircularProgressIndicator(
          strokeWidth: 2,
          color: primary,
        ),
      ),
    );
  }
}

// ============================================================================
// SKELETON
// ============================================================================

class _RecentDishSkeleton
    extends StatelessWidget {
  final Color surface;
  final Color border;

  const _RecentDishSkeleton({
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 174,
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      clipBehavior:
      Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 123,
            width: double.infinity,
            color: Colors.black
                .withValues(
              alpha: 0.045,
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _SkeletonLine(
                  width: 105,
                  height: 11,
                ),
                const SizedBox(
                  height: 8,
                ),
                _SkeletonLine(
                  width: 72,
                  height: 8,
                ),
                const SizedBox(
                  height: 20,
                ),
                _SkeletonLine(
                  width: 85,
                  height: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine
    extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black
            .withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(10),
      ),
    );
  }
}

// ============================================================================
// EMPTY RECENT DISHES
// ============================================================================

class _EmptyRecentDishes
    extends StatelessWidget {
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _EmptyRecentDishes({
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: primary,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Your gallery is getting ready',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'New dishes will appear here automatically.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight:
                    FontWeight.w500,
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
// FEATURE LIST
// ============================================================================

class _FeatureList
    extends StatelessWidget {
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onComingSoon;

  const _FeatureList({
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureTile(
          icon: Icons.camera_alt_outlined,
          title: 'Fridge scanner',
          subtitle:
          'Find ingredients from a photo',
          primary: primary,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary:
          textSecondary,
          onTap: () =>
              onComingSoon(
                'Fridge scanner',
              ),
        ),

        const SizedBox(height: 9),

        _FeatureTile(
          icon:
          Icons.calendar_month_outlined,
          title: 'Meal planner',
          subtitle:
          'Plan your week with AI',
          primary: primary,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary:
          textSecondary,
          onTap: () =>
              onComingSoon(
                'Meal planner',
              ),
        ),

        const SizedBox(height: 9),



      ],
    );
  }
}

// ============================================================================
// FEATURE TILE
// ============================================================================

class _FeatureTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius:
      BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(19),
        child: Container(
          padding:
          const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(19),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                        textPrimary,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                        textSecondary,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                  textPrimary.withValues(
                    alpha: 0.035,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                  textSecondary.withValues(
                    alpha: 0.7,
                  ),
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER
// ============================================================================

class _HomeFooter
    extends StatelessWidget {
  final Color textSecondary;
  final Color primary;

  const _HomeFooter({
    required this.textSecondary,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color:
              textSecondary.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Made with ❤ In India',
            style: TextStyle(
              color:
              textSecondary.withValues(
                alpha: 0.65,
              ),
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: primary.withValues(
                  alpha: 0.55,
                ),
                size: 11,
              ),
              const SizedBox(width: 3),
              Text(
                'Powered by TADKA AI',
                style: TextStyle(
                  color:
                  textSecondary.withValues(
                    alpha: 0.35,
                  ),
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET
// ============================================================================

class _BottomSheetHeader
    extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BottomSheetHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color:
                  colors.onSurface,
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                  colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MENU TILE
// ============================================================================

class _MenuTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 3,
      ),
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: colors.primary
              .withValues(
            alpha: 0.08,
          ),
          borderRadius:
          BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: colors.primary,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color:
          colors.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
      ),
      onTap: onTap,
    );
  }
}
// ============================================================================
// DAILY STREAK - PREMIUM HOME CARD
// ============================================================================

class _DailyStreakHomeButton extends StatelessWidget {
  const _DailyStreakHomeButton();

  void _openStreak(BuildContext context) {
    HapticFeedback.selectionClick();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DailyStreakScreen(),
      ),
    );
  }

  int _rewardForDay(int day) {
    const rewards = [2, 4, 6, 8, 10, 15, 30];

    final safeDay = day.clamp(1, 7);
    return rewards[safeDay - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<Map<String, dynamic>>(
      stream: CoinService.instance.watchStreak(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? <String, dynamic>{};

        final current =
            (data['current'] as num?)?.toInt() ?? 0;

        final claimedToday =
            data['claimedToday'] == true;

        final rawNextDay =
            (data['nextDay'] as num?)?.toInt() ??
                (current + 1);

        final claimDay =
        rawNextDay.clamp(1, 7);

        final todayDay =
        claimedToday
            ? current.clamp(1, 7)
            : claimDay;

        final todayReward =
        _rewardForDay(todayDay);

        final tomorrowDay =
        claimedToday
            ? (claimDay.clamp(1, 7))
            : ((claimDay + 1).clamp(1, 7));

        final tomorrowReward =
        _rewardForDay(tomorrowDay);

        final progress =
        (current.clamp(0, 7) / 7);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          child: InkWell(
            onTap: () => _openStreak(context),
            borderRadius: BorderRadius.circular(23),
            splashColor:
            colors.primary.withValues(alpha: 0.05),
            highlightColor:
            colors.primary.withValues(alpha: 0.025),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                15,
                14,
                13,
                14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(
                      alpha: 0.13,
                    ),
                    colors.primary.withValues(
                      alpha: 0.045,
                    ),
                    theme.scaffoldBackgroundColor
                        .withValues(alpha: 0.20),
                  ],
                  stops: const [
                    0.0,
                    0.55,
                    1.0,
                  ],
                ),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: colors.primary.withValues(
                    alpha: 0.14,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(
                      alpha: 0.055,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ----------------------------------------------------------
                  // REWARD ICON
                  // ----------------------------------------------------------

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          colors.primary.withValues(
                            alpha: 0.72,
                          ),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary
                              .withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 13,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ----------------------------------------------------------
                  // CONTENT
                  // ----------------------------------------------------------

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'DAILY REWARD',
                              style: TextStyle(
                                color:
                                colors.onSurface,
                                fontSize: 8.5,
                                fontWeight:
                                FontWeight.w900,
                                letterSpacing: 1.05,
                              ),
                            ),

                            if (current > 0) ...[
                              const SizedBox(width: 7),

                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: colors.primary
                                      .withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(8),
                                ),
                                child: Text(
                                  'DAY $current',
                                  style: TextStyle(
                                    color:
                                    colors.primary,
                                    fontSize: 6.8,
                                    fontWeight:
                                    FontWeight.w900,
                                    letterSpacing: 0.45,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        if (!claimedToday)
                          Row(
                            children: [
                              Text(
                                '+$todayReward',
                                style: TextStyle(
                                  color:
                                  colors.primary,
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons
                                    .monetization_on_rounded,
                                color:
                                colors.primary,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'COINS',
                                style: TextStyle(
                                  color:
                                  colors.primary,
                                  fontSize: 8,
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: 0.65,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'waiting for you',
                                style: TextStyle(
                                  color: colors
                                      .onSurfaceVariant,
                                  fontSize: 9,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons
                                    .check_circle_rounded,
                                color:
                                colors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '+$todayReward COINS',
                                style: TextStyle(
                                  color:
                                  colors.primary,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'claimed',
                                style: TextStyle(
                                  color: colors
                                      .onSurfaceVariant,
                                  fontSize: 9,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 7),

                        // ----------------------------------------------------
                        // 7-DAY PROGRESS
                        // ----------------------------------------------------

                        Row(
                          children: List.generate(
                            7,
                                (index) {
                              final day = index + 1;

                              final completed =
                                  current >= day;

                              final active =
                                  !claimedToday &&
                                      day == todayDay;

                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin:
                                  EdgeInsets.only(
                                    right:
                                    index == 6
                                        ? 0
                                        : 3,
                                  ),
                                  decoration:
                                  BoxDecoration(
                                    color: completed ||
                                        active
                                        ? colors.primary
                                        : colors.outline
                                        .withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          claimedToday
                              ? 'Come back tomorrow • +$tomorrowReward COINS'
                              : 'Claim today and keep your streak alive',
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                            colors.onSurfaceVariant,
                            fontSize: 7.8,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ----------------------------------------------------------
                  // ACTION
                  // ----------------------------------------------------------

                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: colors.surface
                          .withValues(
                        alpha: 0.88,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.outline
                            .withValues(
                          alpha: 0.07,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons
                          .arrow_forward_rounded,
                      color:
                      colors.primary,
                      size: 17,
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
}