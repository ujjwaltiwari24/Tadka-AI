import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cookbook/cookbook_screen.dart';
import '../ingredients/ingredients_screen.dart';
import '../legal/legal_screens.dart';
import '../profile/profile_screen.dart';
import '../recipes/search_recipe_screen.dart';
import '../streak/daily_streak_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../services/coins/coin_service.dart';

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

    final primaryImage = data['primaryImageUrl']?.toString().trim() ?? '';

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
      category: data['category']?.toString().trim() ?? 'Other',
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
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final photoUrl = user.photoURL?.trim() ?? '';
        final displayName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'TADKA Chef';
        final email = user.email?.trim() ?? '';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
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
                          size: 26,
                        ),
                      )
                          : Icon(
                        Icons.person_rounded,
                        color: colors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved Recipes',
                  subtitle: 'View and manage your cookbook',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openProfile();
                  },
                ),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.gavel_rounded,
                  title: 'Legal & Privacy',
                  subtitle: 'Terms of service and policies',
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
                  title: 'Sign Out',
                  subtitle: 'Disconnect from your TADKA account',
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
        _openIngredientsWithPreference(initialTime: '20 min');
        break;
      case 'Vegan':
        _openIngredientsWithPreference(initialDiet: 'Vegan');
        break;
      case 'Spicy':
        _openIngredientsWithPreference(initialSpice: 'Spicy');
        break;
      case 'Beginner':
        _openIngredientsWithPreference(initialSkill: 'Beginner');
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
  // FIRESTORE & REFRESH LOGIC
  // ==========================================================================

  Future<void> _loadRecentDishes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dishes')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .get();

      final dishes = snapshot.docs
          .map(_RecentDish.fromFirestore)
          .where((dish) => dish.name.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _recentDishes = dishes;
        _recentDishesLoading = false;
      });
    } catch (error) {
      debugPrint('Recent dishes error: $error');

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
  // MORE MENU & ABOUT DIALOG
  // ==========================================================================

  void _showMoreMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BottomSheetHeader(
                  title: 'More Features',
                  subtitle: 'TADKA Culinary Suite',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuTile(
                          icon: Icons.menu_book_rounded,
                          title: 'Cookbook Library',
                          subtitle: 'Explore saved dishes & collections',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openCookbook();
                          },
                        ),
                        const SizedBox(height: 8),
                        _MenuTile(
                          icon: Icons.bookmark_outline_rounded,
                          title: 'Saved Recipes',
                          subtitle: 'View your saved favorite recipes',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openProfile();
                          },
                        ),
                        const SizedBox(height: 8),
                        _MenuTile(
                          icon: Icons.gavel_rounded,
                          title: 'Legal & Privacy',
                          subtitle: 'Privacy, terms, and guidelines',
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
                          icon: Icons.info_outline_rounded,
                          title: 'About TADKA AI',
                          subtitle: 'Learn about your AI cooking assistant',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showAboutDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
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
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'TADKA AI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Your intelligent AI culinary companion.\n\n'
                'Craft custom step-by-step recipes from ingredients you already have, '
                'or search for any dish worldwide.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GOT IT',
                  style: TextStyle(fontWeight: FontWeight.w800)),
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
    final textSecondary = colors.onSurfaceVariant;

    final border = colors.outline.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.20 : 0.08,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: _refreshHome,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // 1. TOP HEADER BAR
                      _TopBar(
                        textPrimary: textPrimary,
                        primary: colors.primary,
                        signedIn: AuthService.instance.isSignedIn,
                        photoUrl: AuthService.instance.currentUser?.photoURL,
                        onProfile: _openProfile,
                        onProfileLongPress: _showProfileSheet,
                        onCookbook: _openCookbook,
                        onMore: _showMoreMenu,
                      ),

                      const SizedBox(height: 16),

                      // 2. HERO GREETING
                      _Greeting(
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primary: colors.primary,
                      ),

                      const SizedBox(height: 14),

                      // 3. HIGHLIGHTED PROMINENT DISH SEARCH BAR
                      _SearchDishCard(
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: _openDishSearch,
                      ),

                      const SizedBox(height: 14),

                      // 4. PRIMARY HERO RECIPE GENERATOR
                      _HeroGenerateRecipeCard(
                        primary: colors.primary,
                        onTap: _openIngredients,
                      ),

                      const SizedBox(height: 14),

                      // 5. STREAK & COINS CARD
                      const _DailyStreakHomeButton(),

                      const SizedBox(height: 20),

                      // 6. QUICK COOKING MODES
                      _SectionHeader(
                        title: 'Quick Cooking Modes',
                        subtitle: 'Filter by prep time, diet, or skill',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 10),

                      _QuickOptions(
                        selected: _selectedQuickOption,
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onSelect: _openQuickPick,
                      ),

                      const SizedBox(height: 20),

                      // 7. RECIPE DISCOVERY
                      _RecentDishesSection(
                        dishes: _recentDishes,
                        loading: _recentDishesLoading,
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onDishTap: _openRecentDish,
                      ),

                      const SizedBox(height: 20),

                      // 8. KITCHEN SHORTCUTS
                      _SectionHeader(
                        title: 'Kitchen Shortcuts',
                        subtitle: 'Smart tools for your everyday cooking',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 10),

                      _FeatureList(
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onOpenIngredients: _openIngredients,
                        onOpenCookbook: _openCookbook,
                      ),

                      const SizedBox(height: 28),

                      // 9. FOOTER
                      _HomeFooter(
                        textSecondary: textSecondary,
                        primary: colors.primary,
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
  final VoidCallback onProfileLongPress;
  final VoidCallback onCookbook;
  final VoidCallback onMore;

  const _TopBar({
    required this.textPrimary,
    required this.primary,
    required this.signedIn,
    required this.photoUrl,
    required this.onProfile,
    required this.onProfileLongPress,
    required this.onCookbook,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(primary, Colors.black, 0.22) ?? primary,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TADKA',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'AI CULINARY',
              style: TextStyle(
                color: textPrimary.withValues(alpha: 0.45),
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        _HeaderIconButton(
          icon: Icons.menu_book_rounded,
          textPrimary: textPrimary,
          onTap: onCookbook,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.more_horiz_rounded,
          textPrimary: textPrimary,
          onTap: onMore,
        ),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfile,
            onLongPress: onProfileLongPress,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: textPrimary.withValues(alpha: 0.10),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: signedIn && (photoUrl?.trim().isNotEmpty ?? false)
                  ? Image.network(
                photoUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_outline_rounded,
                  color: textPrimary,
                  size: 18,
                ),
              )
                  : Icon(
                signedIn
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                color: textPrimary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color textPrimary;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: textPrimary.withValues(alpha: 0.85),
            size: 18,
          ),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              greeting.toUpperCase(),
              style: TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'What are you\ncooking today?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Search any dish or generate custom recipes from pantry items.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PROMINENT HIGHLIGHTED SEARCH DISH CARD
// ============================================================================

class _SearchDishCard extends StatelessWidget {
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withValues(alpha: 0.28),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Recipe or Dish',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Try "Paneer Tikka", "Pasta", or "Dal Tadka"',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SEARCH',
                  style: TextStyle(
                    color: primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
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
// PRIMARY HERO CTA CARD
// ============================================================================

class _HeroGenerateRecipeCard extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const _HeroGenerateRecipeCard({
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(primary, Colors.black, 0.18) ?? primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI POWERED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Cook with What You Have',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transform your current pantry items into delicious, custom step-by-step recipes.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select Ingredients & Cook',
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: primary,
                      size: 18,
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

class _SectionHeader extends StatelessWidget {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK OPTIONS
// ============================================================================

class _QuickOptions extends StatelessWidget {
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
      subtitle: '20 min prep',
      icon: Icons.bolt_rounded,
      ),
      (
      name: 'Vegan',
      subtitle: 'Plant-based',
      icon: Icons.eco_outlined,
      ),
      (
      name: 'Spicy',
      subtitle: 'Bring heat',
      icon: Icons.local_fire_department_outlined,
      ),
      (
      name: 'Beginner',
      subtitle: 'Easy steps',
      icon: Icons.school_outlined,
      ),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selected == option.name;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onSelect(option.name),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? primary.withValues(alpha: 0.10) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? primary : border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          option.icon,
                          color: isSelected ? primary : textSecondary,
                          size: 16,
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 13,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      option.name,
                      style: TextStyle(
                        color: isSelected ? primary : textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
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
// RECENT DISHES SECTION
// ============================================================================

class _RecentDishesSection extends StatelessWidget {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHeader(
                title: 'Featured Culinary Ideas',
                subtitle: 'Popular recipes from the community',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            if (!loading && dishes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${dishes.length} DISHES',
                  style: TextStyle(
                    color: primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (loading)
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
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
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          )
        else
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dishes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _RecentDishCard(
                  dish: dishes[index],
                  primary: primary,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: onDishTap,
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

class _RecentDishCard extends StatelessWidget {
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
      width: 146,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(dish.name);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 98,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (dish.imageUrl.isNotEmpty)
                        Image.network(
                          dish.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _DishPlaceholder(primary: primary);
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _DishImageLoading(primary: primary);
                          },
                        )
                      else
                        _DishPlaceholder(primary: primary),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 45,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          dish.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'View recipe',
                              style: TextStyle(
                                color: primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 10,
                              color: primary,
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
// IMAGE PLACEHOLDER & LOADING
// ============================================================================

class _DishPlaceholder extends StatelessWidget {
  final Color primary;

  const _DishPlaceholder({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.08),
            primary.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_rounded,
            color: primary.withValues(alpha: 0.55),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _DishImageLoading extends StatelessWidget {
  final Color primary;

  const _DishImageLoading({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withValues(alpha: 0.05),
      child: Center(
        child: CircularProgressIndicator(
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

class _RecentDishSkeleton extends StatelessWidget {
  final Color surface;
  final Color border;

  const _RecentDishSkeleton({
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 98,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.04),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: 90, height: 9),
                const SizedBox(height: 5),
                _SkeletonLine(width: 60, height: 7),
                const SizedBox(height: 12),
                _SkeletonLine(width: 70, height: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
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
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ============================================================================
// EMPTY RECENT DISHES
// ============================================================================

class _EmptyRecentDishes extends StatelessWidget {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your gallery is updating',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Recommended dishes will appear here automatically.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.5,
                    height: 1.3,
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

// ============================================================================
// FEATURE LIST
// ============================================================================

class _FeatureList extends StatelessWidget {
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onOpenIngredients;
  final VoidCallback onOpenCookbook;

  const _FeatureList({
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onOpenIngredients,
    required this.onOpenCookbook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureTile(
          icon: Icons.grid_view_rounded,
          title: 'Pantry Recipe Generator',
          subtitle: 'Select available items & create custom meals',
          primary: primary,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: onOpenIngredients,
        ),
        const SizedBox(height: 8),
        _FeatureTile(
          icon: Icons.collections_bookmark_rounded,
          title: 'My Cookbook Collection',
          subtitle: 'Access your unlocked and saved recipe library',
          primary: primary,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: onOpenCookbook,
        ),
      ],
    );
  }
}

// ============================================================================
// FEATURE TILE
// ============================================================================

class _FeatureTile extends StatelessWidget {
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: textSecondary.withValues(alpha: 0.5),
                size: 11,
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

class _HomeFooter extends StatelessWidget {
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
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Made with ❤ In India',
            style: TextStyle(
              color: textSecondary.withValues(alpha: 0.75),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: primary.withValues(alpha: 0.65),
                size: 11,
              ),
              const SizedBox(width: 3),
              Text(
                'Powered by TADKA AI',
                style: TextStyle(
                  color: textSecondary.withValues(alpha: 0.45),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
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
// BOTTOM SHEET HEADER
// ============================================================================

class _BottomSheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BottomSheetHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
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

class _MenuTile extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: colors.primary,
          size: 19,
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
          color: colors.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 12,
      ),
      onTap: onTap,
    );
  }
}

// ============================================================================
// DAILY STREAK - HOME CARD
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

        final current = (data['current'] as num?)?.toInt() ?? 0;
        final claimedToday = data['claimedToday'] == true;
        final rawNextDay =
            (data['nextDay'] as num?)?.toInt() ?? (current + 1);

        final claimDay = rawNextDay.clamp(1, 7);
        final todayDay = claimedToday ? current.clamp(1, 7) : claimDay;
        final todayReward = _rewardForDay(todayDay);

        final tomorrowDay =
        claimedToday ? claimDay.clamp(1, 7) : ((claimDay + 1).clamp(1, 7));
        final tomorrowReward = _rewardForDay(tomorrowDay);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _openStreak(context),
            borderRadius: BorderRadius.circular(16),
            splashColor: colors.primary.withValues(alpha: 0.05),
            highlightColor: colors.primary.withValues(alpha: 0.025),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(alpha: 0.12),
                    colors.primary.withValues(alpha: 0.04),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.20),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.78),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'DAILY REWARD',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (current > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DAY $current',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (!claimedToday)
                          Row(
                            children: [
                              Text(
                                '+$todayReward',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.monetization_on_rounded,
                                color: colors.primary,
                                size: 13,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'COINS',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'waiting for you',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '+$todayReward COINS',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'claimed',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(
                            7,
                                (index) {
                              final day = index + 1;
                              final completed = current >= day;
                              final active = !claimedToday && day == todayDay;

                              return Expanded(
                                child: Container(
                                  height: 3,
                                  margin: EdgeInsets.only(
                                    right: index == 6 ? 0 : 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: completed || active
                                        ? colors.primary
                                        : colors.outline.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          claimedToday
                              ? 'Come back tomorrow • +$tomorrowReward COINS'
                              : 'Claim today and keep your streak alive',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colors.primary,
                    size: 12,
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