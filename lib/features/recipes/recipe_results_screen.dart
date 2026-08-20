// lib/features/recipes/recipe_results_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ads/banner_ad_widget.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/coins/coin_service.dart';
import '../auth/auth_screen.dart';
import '../cooking/start_cooking_screen.dart';
import 'recipe.dart';

// ============================================================================
// FEEDBACK TYPE
// ============================================================================

enum _FeedbackType { success, info, error }

class RecipeResultsScreen extends StatelessWidget {
  final List<Recipe> recipes;

  const RecipeResultsScreen({
    super.key,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              tooltip: 'Back',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        title: Text(
          'Your Kitchen Creations',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            letterSpacing: -0.4,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: recipes.isEmpty
                  ? _EmptyState(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                primary: primary,
              )
                  : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  // Premium Header Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1F1D2B), const Color(0xFF18181B)]
                            : [const Color(0xFFFFF3E0), const Color(0xFFFFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: primary.withValues(alpha: isDark ? 0.3 : 0.2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${recipes.length} ${recipes.length == 1 ? 'idea' : 'ideas'} from your kitchen',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Personalized around your ingredients and preferences.',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                primary.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AI PICKED',
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
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(
                    recipes.length,
                        (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == recipes.length - 1 ? 0 : 16,
                      ),
                      child: _RecipeCard(
                        recipe: recipes[index],
                        index: index,
                        isTopMatch: index == 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const BannerAdWidget(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RECIPE CARD
// ============================================================================

class _RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final int index;
  final bool isTopMatch;

  const _RecipeCard({
    required this.recipe,
    required this.index,
    required this.isTopMatch,
  });

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? const Color(0xFF18181B) : Colors.white;
    final primary = theme.colorScheme.primary;

    final textPrimary = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    final border = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    final match = widget.recipe.ingredientMatch.clamp(0, 100);
    final hasImage = widget.recipe.imageUrl.trim().isNotEmpty;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onHighlightChanged: (highlighted) {
            setState(() {
              _isPressed = highlighted;
            });
          },
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: widget.recipe),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isTopMatch
                    ? primary
                    : border,
                width: widget.isTopMatch ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isTopMatch
                      ? primary.withValues(alpha: isDark ? 0.2 : 0.08)
                      : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Stack(
                      children: [
                        Image.network(
                          widget.recipe.imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#${widget.index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasImage) ...[
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.isTopMatch
                                      ? [primary, primary.withValues(alpha: 0.8)]
                                      : [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.08)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.index + 1}',
                                  style: TextStyle(
                                    color: widget.isTopMatch ? Colors.white : primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.isTopMatch)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFB74D),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: Color(0xFFE65100),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'BEST MATCH',
                                          style: TextStyle(
                                            color: const Color(0xFFE65100),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  widget.recipe.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: primary,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.recipe.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Safe Flex Pills Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: _Meta(
                                icon: Icons.timer_outlined,
                                iconColor: const Color(0xFF0288D1),
                                text: '${widget.recipe.timeMinutes}m',
                                textColor: textPrimary,
                              ),
                            ),
                            _Dot(color: textSecondary),
                            Flexible(
                              child: _Meta(
                                icon: Icons.currency_rupee_rounded,
                                iconColor: const Color(0xFF2E7D32),
                                text: '₹${widget.recipe.estimatedCost}',
                                textColor: textPrimary,
                              ),
                            ),
                            _Dot(color: textSecondary),
                            Flexible(
                              child: _Meta(
                                icon: Icons.people_outline_rounded,
                                iconColor: const Color(0xFFE65100),
                                text: '${widget.recipe.servings} Serv',
                                textColor: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Match Bar Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$match% MATCH',
                              style: TextStyle(
                                color: primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              widget.recipe.missingIngredients.isEmpty
                                  ? 'All ingredients ready'
                                  : '${widget.recipe.missingIngredients.length} missing',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.recipe.missingIngredients.isEmpty
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFD84315),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: match / 100,
                          minHeight: 6,
                          backgroundColor: primary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                      if (widget.recipe.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _IngredientPreview(
                          recipe: widget.recipe,
                          textSecondary: textSecondary,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'VIEW FULL RECIPE',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: primary,
                            size: 15,
                          ),
                        ],
                      ),
                    ],
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
// INGREDIENT PREVIEW
// ============================================================================

class _IngredientPreview extends StatelessWidget {
  final Recipe recipe;
  final Color textSecondary;

  const _IngredientPreview({
    required this.recipe,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final available = recipe.ingredients
        .where((ingredient) => ingredient.available)
        .take(4)
        .toList();

    if (available.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              available.map((ingredient) => ingredient.name).join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1B5E20),
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

// ============================================================================
// META
// ============================================================================

class _Meta extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  const _Meta({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DOT
// ============================================================================

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;

  const _EmptyState({
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing to cook yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adding a few more ingredients and let TADKA find something for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RECIPE DETAIL SCREEN
// ============================================================================

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isUnlocked;
  final bool isSaved;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.isUnlocked = false,
    this.isSaved = false,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late bool _isUnlocked;
  bool _isUnlocking = false;
  bool _isSaving = false;
  bool _isSaved = false;
  String? _savedDocumentId;

  Recipe get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    _isUnlocked = widget.isUnlocked;
    _isSaved = widget.isSaved;

    if (AuthService.instance.isSignedIn) {
      _checkSavedStatus();
    }
  }

  // ===========================================================================
  // FIRESTORE MAPPER
  // ===========================================================================

  Map<String, dynamic> _recipeToMap() {
    return {
      'name': recipe.name,
      'description': recipe.description,
      'timeMinutes': recipe.timeMinutes,
      'estimatedCost': recipe.estimatedCost,
      'servings': recipe.servings,
      'difficulty': recipe.difficulty,
      'ingredientMatch': recipe.ingredientMatch,
      'ingredients': recipe.ingredients
          .map(
            (ingredient) => {
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'available': ingredient.available,
        },
      )
          .toList(),
      'missingIngredients': recipe.missingIngredients,
      'substitutions': recipe.substitutions,
      'equipment': recipe.equipment,
      'steps': recipe.steps,
      'tips': recipe.tips,
      'warnings': recipe.warnings,
      'imageUrl': recipe.imageUrl,
    };
  }

  // ===========================================================================
  // CHECK SAVED STATUS
  // ===========================================================================

  Future<void> _checkSavedStatus() async {
    final user = AuthService.instance.currentUser;
    if (user == null || !mounted) return;

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedRecipes')
          .where('name', isEqualTo: recipe.name)
          .limit(1)
          .get();

      if (!mounted) return;

      if (result.docs.isNotEmpty) {
        setState(() {
          _isSaved = true;
          _savedDocumentId = result.docs.first.id;
        });
      } else {
        setState(() {
          _isSaved = false;
          _savedDocumentId = null;
        });
      }
    } catch (error) {
      debugPrint('Check saved status error: $error');
    }
  }

  // ===========================================================================
  // SAVE / UNSAVE RECIPE
  // ===========================================================================

  Future<void> _toggleSave() async {
    if (_isSaving) return;
    HapticFeedback.selectionClick();

    if (!AuthService.instance.isSignedIn) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );

      if (!mounted) return;
      if (result != true && !AuthService.instance.isSignedIn) return;
      await _checkSavedStatus();
      if (!mounted) return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showMessage(
        'Please sign in to save recipes.',
        type: _FeedbackType.info,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedRecipes');

      if (_isSaved) {
        String? documentId = _savedDocumentId;

        if (documentId == null) {
          final result = await collection
              .where('name', isEqualTo: recipe.name)
              .limit(1)
              .get();

          if (result.docs.isNotEmpty) {
            documentId = result.docs.first.id;
          }
        }

        if (documentId != null) {
          await collection.doc(documentId).delete();
        }

        if (!mounted) return;

        setState(() {
          _isSaved = false;
          _savedDocumentId = null;
          _isSaving = false;
        });

        HapticFeedback.mediumImpact();
        _showMessage(
          'Removed from your cookbook.',
          type: _FeedbackType.info,
        );
        return;
      }

      final existing = await collection
          .where('name', isEqualTo: recipe.name)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _isSaved = true;
          _savedDocumentId = existing.docs.first.id;
          _isSaving = false;
        });
        _showMessage(
          'Recipe is already in your cookbook.',
          type: _FeedbackType.info,
        );
        return;
      }

      final data = _recipeToMap();
      data['savedAt'] = FieldValue.serverTimestamp();
      data['savedBy'] = user.uid;
      data['savedFrom'] = 'recipe_detail';

      final document = await collection.add(data);

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _savedDocumentId = document.id;
        _isSaving = false;
      });

      HapticFeedback.mediumImpact();
      _showMessage(
        'Recipe saved to your cookbook.',
        type: _FeedbackType.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showMessage(
        'Could not save this recipe. Please try again.',
        type: _FeedbackType.error,
      );
    }
  }

  // ===========================================================================
  // WALLET & UNLOCKING
  // ===========================================================================

  Future<void> _initializeWallet() async {
    await CoinService.instance.ensureWallet();
  }

  Future<void> _unlockWithCoin() async {
    if (_isUnlocking) return;

    if (!AuthService.instance.isSignedIn) {
      _showMessage(
        'Sign in to use TADKA Coins.',
        type: _FeedbackType.info,
      );
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      await _initializeWallet();
      await CoinService.instance.spendCoin();

      if (!mounted) return;

      setState(() {
        _isUnlocked = true;
        _isUnlocking = false;
      });

      HapticFeedback.mediumImpact();
    } on CoinException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUnlocking = false;
      });
      _showMessage(e.message, type: _FeedbackType.error);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUnlocking = false;
      });
      _showMessage(
        'Could not unlock this recipe. Please try again.',
        type: _FeedbackType.error,
      );
    }
  }

  Future<void> _watchAdToUnlock() async {
    if (_isUnlocking) return;

    if (!AuthService.instance.isSignedIn) {
      _showMessage(
        'Sign in to earn TADKA Coins.',
        type: _FeedbackType.info,
      );
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      await _initializeWallet();
      final rewarded = await RewardedAdService.instance.showRewardedAd();

      if (!rewarded) {
        if (!mounted) return;
        setState(() {
          _isUnlocking = false;
        });
        _showMessage(
          'The reward ad is not ready. Please try again.',
          type: _FeedbackType.error,
        );
        return;
      }

      await CoinService.instance.grantRewardCoin();
      await CoinService.instance.spendCoin();

      if (!mounted) return;

      setState(() {
        _isUnlocked = true;
        _isUnlocking = false;
      });

      HapticFeedback.mediumImpact();
    } on CoinException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUnlocking = false;
      });
      _showMessage(e.message, type: _FeedbackType.error);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUnlocking = false;
      });
      _showMessage(
        'Could not unlock this recipe. Please try again.',
        type: _FeedbackType.error,
      );
    }
  }

  Future<void> _goToSignIn() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );

    if (!mounted) return;

    if (AuthService.instance.isSignedIn) {
      try {
        await _initializeWallet();
      } catch (_) {}
      await _checkSavedStatus();
      if (!mounted) return;
      setState(() {});
    }
  }

  void _showMessage(
      String message, {
        _FeedbackType type = _FeedbackType.info,
      }) {
    if (!mounted) return;

    final IconData icon;
    final Color? backgroundColor;

    switch (type) {
      case _FeedbackType.success:
        icon = Icons.check_circle_rounded;
        backgroundColor = const Color(0xFF2E7D32);
        break;
      case _FeedbackType.error:
        icon = Icons.error_outline_rounded;
        backgroundColor = const Color(0xFFC62828);
        break;
      case _FeedbackType.info:
        icon = Icons.info_outline_rounded;
        backgroundColor = null;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final textPrimary = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final surface = isDark ? const Color(0xFF18181B) : Colors.white;

    final match = recipe.ingredientMatch.clamp(0, 100);
    final hasImage = recipe.imageUrl.trim().isNotEmpty;

    if (!_isUnlocked) {
      return _LockedRecipeView(
        recipe: recipe,
        isUnlocking: _isUnlocking,
        onUseCoin: _unlockWithCoin,
        onWatchAd: _watchAdToUnlock,
        onSignIn: _goToSignIn,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              tooltip: 'Back',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        title: Text(
          'Recipe Overview',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: _isSaved ? 'Remove from cookbook' : 'Save recipe',
                onPressed: _isSaving ? null : _toggleSave,
                icon: _isSaving
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                )
                    : Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saved Badge
              if (_isSaved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_rounded, size: 14, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        'SAVED TO COOKBOOK',
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Featured Image Banner
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    recipe.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Header
              Text(
                'YOUR RECIPE',
                style: TextStyle(
                  color: primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recipe.name,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                recipe.description,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              // Responsive Meta Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailMeta(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF0288D1),
                    label: '${recipe.timeMinutes} mins',
                    surface: surface,
                  ),
                  _DetailMeta(
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFFE65100),
                    label: '${recipe.servings} Servings',
                    surface: surface,
                  ),
                  _DetailMeta(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    label: '₹${recipe.estimatedCost}',
                    surface: surface,
                  ),
                  _DetailMeta(
                    icon: Icons.signal_cellular_alt_rounded,
                    iconColor: primary,
                    label: recipe.difficulty,
                    surface: surface,
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Why This Recipe Card
              _SectionHeading(
                title: 'Why this recipe',
                subtitle: 'TADKA picked it based on your ingredients.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1F1D2B), surface]
                        : [const Color(0xFFFFF3E0), surface],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$match% of the recipe matches your ingredients',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: match / 100,
                        minHeight: 6,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Ingredients
              _SectionHeading(
                title: 'Ingredients',
                subtitle: 'Everything you need to make it.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 14),
              if (recipe.ingredients.isEmpty)
                Text(
                  'No ingredient details were returned.',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                )
              else
                ...recipe.ingredients.map((ingredient) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ingredient.available
                            ? const Color(0xFF81C784).withValues(alpha: 0.4)
                            : const Color(0xFFFF8A65).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Check / Add Icon
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: ingredient.available
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFE8E5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            ingredient.available ? Icons.check_rounded : Icons.add_rounded,
                            size: 15,
                            color: ingredient.available
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFD84315),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Ingredient Name
                        Expanded(
                          flex: 4,
                          child: Text(
                            ingredient.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quantity (Flexible / Constrained)
                        Flexible(
                          flex: 5,
                          child: Text(
                            ingredient.quantity,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // Missing Ingredients
              if (recipe.missingIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionHeading(
                  title: 'You may need',
                  subtitle: "A few things that aren't in your kitchen list.",
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.missingIngredients.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFFD84315),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Substitutions
              if (recipe.substitutions.isNotEmpty) ...[
                const SizedBox(height: 26),
                _SectionHeading(
                  title: 'Easy substitutions',
                  subtitle: 'Alternatives you can use if needed.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipe.substitutions.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 16,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Equipment
              if (recipe.equipment.isNotEmpty) ...[
                const SizedBox(height: 26),
                _SectionHeading(
                  title: 'Equipment',
                  subtitle: 'Keep these things ready.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.equipment.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                        ),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 26),

              // Cooking Steps
              _SectionHeading(
                title: 'How to cook',
                subtitle: 'Follow these steps from start to finish.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 14),
              if (recipe.steps.isEmpty)
                Text(
                  'No cooking steps were returned.',
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                )
              else
                ...List.generate(recipe.steps.length, (index) {
                  final isLast = index == recipe.steps.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: primary.withValues(alpha: 0.25),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                ),
                              ),
                              child: Text(
                                recipe.steps[index],
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // Chef Tips Card
              if (recipe.tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionHeading(
                  title: 'Chef tips',
                  subtitle: 'Small details that can make a difference.',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1B00) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipe.tips.map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              size: 16,
                              color: Color(0xFFFF8F00),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Good to Know / Warnings
              if (recipe.warnings.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE57373).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Color(0xFFC62828),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Good to know',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...recipe.warnings.map((warning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $warning',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 26),

              // Start Cooking Primary CTA
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StartCookingScreen(recipe: recipe),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready to cook?',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Start Cooking Mode',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Save Recipe CTA Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSaved
                                ? 'Saved in your cookbook'
                                : 'Love this recipe?',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSaved
                                ? 'Find it anytime in Cookbook.'
                                : 'Save it for next time.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: _isSaving ? null : _toggleSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _isSaved ? 'Saved' : 'Save',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
// LOCKED RECIPE VIEW
// ============================================================================

class _LockedRecipeView extends StatelessWidget {
  final Recipe recipe;
  final bool isUnlocking;
  final VoidCallback onUseCoin;
  final VoidCallback onWatchAd;
  final VoidCallback onSignIn;

  const _LockedRecipeView({
    required this.recipe,
    required this.isUnlocking,
    required this.onUseCoin,
    required this.onWatchAd,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final signedIn = AuthService.instance.isSignedIn;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Unlock Recipe',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
          child: Column(
            children: [
              if (recipe.imageUrl.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    recipe.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 0),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: colors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                recipe.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your recipe is ready. Unlock it to see the complete ingredients and cooking steps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<int>(
                stream: signedIn
                    ? CoinService.instance.watchCoins()
                    : Stream<int>.value(0),
                builder: (context, snapshot) {
                  final coins = snapshot.data ?? 0;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFE49A00),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TADKA Coins',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                signedIn
                                    ? '$coins ${coins == 1 ? 'coin' : 'coins'} available'
                                    : 'Sign in to get your welcome coins',
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
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              if (!signedIn)
                _SignInUnlockCard(onTap: onSignIn)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: isUnlocking ? null : onUseCoin,
                    icon: const Icon(Icons.monetization_on_rounded, size: 20),
                    label: Text(
                      isUnlocking ? 'Unlocking...' : 'Use 1 Coin to Unlock',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: isUnlocking ? null : onWatchAd,
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isUnlocking ? 'Preparing reward...' : 'Watch Ad to Unlock',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Watching a rewarded ad earns 1 coin and uses it to unlock this recipe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SIGN IN UNLOCK CARD
// ============================================================================

class _SignInUnlockCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SignInUnlockCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Text(
            'Sign in required',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your TADKA wallet and receive 10 welcome coins.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign in with Google',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DETAIL META
// ============================================================================

class _DetailMeta extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color surface;

  const _DetailMeta({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION HEADING
// ============================================================================

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;

  const _SectionHeading({
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}