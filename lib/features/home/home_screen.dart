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
  // NAVIGATION & PREFERENCE FILTER LOGIC
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colors.primary.withValues(alpha: 0.12),
                        backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Icon(Icons.person_rounded,
                            color: colors.primary, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 14),
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
                                fontWeight: FontWeight.w800,
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved Recipes',
                  subtitle: 'View and manage your personal cookbook',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openProfile();
                  },
                ),
                const SizedBox(height: 6),
                _MenuTile(
                  icon: Icons.gavel_rounded,
                  title: 'Legal & Privacy',
                  subtitle: 'Terms of service, guidelines and policies',
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
                const SizedBox(height: 6),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Disconnect from your TADKA account',
                  isDestructive: true,
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
      case 'Veg':
        _openIngredientsWithPreference(initialDiet: 'Veg');
        break;
      case 'Non-Veg':
        _openIngredientsWithPreference(initialDiet: 'Non-Veg');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  title: 'Culinary Suite',
                  subtitle: 'Tools, saved collections & features',
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuTile(
                          icon: Icons.menu_book_rounded,
                          title: 'Cookbook Library',
                          subtitle: 'Explore saved dishes & custom collections',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openCookbook();
                          },
                        ),
                        const SizedBox(height: 6),
                        _MenuTile(
                          icon: Icons.bookmark_outline_rounded,
                          title: 'Saved Recipes',
                          subtitle: 'View your favorite unlocked recipes',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openProfile();
                          },
                        ),
                        const SizedBox(height: 6),
                        _MenuTile(
                          icon: Icons.gavel_rounded,
                          title: 'Legal & Privacy',
                          subtitle: 'Privacy policy, terms & legal information',
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
                        const SizedBox(height: 6),
                        _MenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About TADKA AI',
                          subtitle: 'Learn about your intelligent cooking companion',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showAboutDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: colors.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
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
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'TADKA AI',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Your intelligent AI culinary companion.\n\n'
                'Craft custom step-by-step recipes from ingredients you already have, '
                'or search for any dish worldwide.',
            style: TextStyle(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = colors.onSurface;
    final textSecondary = colors.onSurfaceVariant;

    final border = colors.outline.withValues(
      alpha: isDark ? 0.18 : 0.08,
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
                      // 1. TOP BAR
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

                      const SizedBox(height: 20),

                      // 2. GREETING
                      _Greeting(
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primary: colors.primary,
                      ),

                      const SizedBox(height: 18),

                      // 3. SEARCH BAR
                      _SearchDishCard(
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: _openDishSearch,
                      ),

                      const SizedBox(height: 18),

                      // 4. PANTRY GENERATOR HERO CARD
                      _HeroGenerateRecipeCard(
                        primary: colors.primary,
                        onTap: _openIngredients,
                      ),

                      const SizedBox(height: 18),

                      // 5. STREAK CARD
                      const _DailyStreakHomeButton(),

                      const SizedBox(height: 24),

                      // 6. QUICK COOKING MODES
                      _SectionHeader(
                        title: 'Quick Cooking Modes',
                        subtitle: 'Filter by prep time, diet, or skill',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 12),

                      _QuickOptions(
                        selected: _selectedQuickOption,
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onSelect: _openQuickPick,
                      ),

                      const SizedBox(height: 24),

                      // 7. RECIPE DISCOVERY
                      _RecentDishesSection(
                        dishes: _recentDishes,
                        loading: _recentDishesLoading,
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: _openRecentDish,
                      ),

                      const SizedBox(height: 24),

                      // 8. KITCHEN SHORTCUTS
                      _SectionHeader(
                        title: 'Kitchen Shortcuts',
                        subtitle: 'Smart tools for your everyday cooking',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 12),

                      _FeatureList(
                        primary: colors.primary,
                        surface: colors.surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onOpenIngredients: _openIngredients,
                        onOpenCookbook: _openCookbook,
                      ),

                      const SizedBox(height: 32),

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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TADKA',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'AI CULINARY',
              style: TextStyle(
                color: primary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
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
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.more_horiz_rounded,
          textPrimary: textPrimary,
          onTap: onMore,
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfile,
            onLongPress: onProfileLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: textPrimary.withValues(alpha: 0.12),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: textPrimary.withValues(alpha: 0.85),
            size: 19,
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
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              greeting.toUpperCase(),
              style: TextStyle(
                color: primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'What are you\ncooking today?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Search any dish worldwide or generate custom recipes from pantry items.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SEARCH DISH CARD
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primary.withValues(alpha: 0.25),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 21,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Try "Paneer Tikka", "Pasta", or "Dal Tadka"',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HOT',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI POWERED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Cook with What You Have',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transform your current pantry items into delicious, custom step-by-step recipes.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select Ingredients & Cook',
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: primary,
                      size: 20,
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
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
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
      name: 'Veg',
      subtitle: 'Pure vegetarian',
      icon: Icons.grass_rounded,
      ),
      (
      name: 'Non-Veg',
      subtitle: 'Meat & poultry',
      icon: Icons.set_meal_rounded,
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
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selected == option.name;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onSelect(option.name),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 118,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? primary.withValues(alpha: 0.1) : surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primary : border,
                    width: isSelected ? 1.6 : 1,
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
                          size: 18,
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 14,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      option.name,
                      style: TextStyle(
                        color: isSelected ? primary : textPrimary,
                        fontSize: 12,
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
  final ValueChanged<String> onTap;

  const _RecentDishesSection({
    required this.dishes,
    required this.loading,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
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
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dishes.length} DISHES',
                  style: TextStyle(
                    color: primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          SizedBox(
            height: 180,
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
            height: 180,
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
                  onTap: onTap,
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
      width: 150,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(dish.name);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                                fontWeight: FontWeight.w800,
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
      color: primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: primary.withValues(alpha: 0.6),
          size: 22,
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
      color: primary.withValues(alpha: 0.04),
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
      width: 150,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.04),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: 90, height: 10),
                const SizedBox(height: 5),
                _SkeletonLine(width: 60, height: 8),
                const SizedBox(height: 14),
                _SkeletonLine(width: 70, height: 8),
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
        borderRadius: BorderRadius.circular(4),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: primary,
              size: 22,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Recommended dishes will appear here automatically.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: textSecondary.withValues(alpha: 0.4),
                size: 12,
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
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Made with ❤ In India',
            style: TextStyle(
              color: textSecondary.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: primary.withValues(alpha: 0.7),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Powered by TADKA AI',
                style: TextStyle(
                  color: textSecondary.withValues(alpha: 0.5),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
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
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = isDestructive ? colors.error : colors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: isDestructive ? colors.error : colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 12,
        color: colors.onSurfaceVariant.withValues(alpha: 0.5),
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
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => _openStreak(context),
            borderRadius: BorderRadius.circular(18),
            splashColor: colors.primary.withValues(alpha: 0.05),
            highlightColor: colors.primary.withValues(alpha: 0.025),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 20,
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
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            if (current > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DAY $current',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.monetization_on_rounded,
                                color: colors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'COINS',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'waiting for you',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
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
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+$todayReward COINS',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'claimed',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
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
                                        : colors.outline
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
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
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
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