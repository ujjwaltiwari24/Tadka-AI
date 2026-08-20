

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ads/banner_ad_widget.dart';
import '../../services/auth/auth_service.dart';
import '../auth/auth_screen.dart';
import '../cooking/start_cooking_screen.dart';
import '../../services/coins/coin_service.dart';
import '../../services/ads/rewarded_ad_service.dart';
import 'recipe.dart';

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

    final textPrimary = isDark
        ? Colors.white
        : const Color(0xFF211D19);

    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF77716A);

    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          tooltip: 'Back',
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Your recipes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  24,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${recipes.length} ${recipes.length == 1 ? 'idea' : 'ideas'} from your kitchen',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Personalized around your ingredients and preferences.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AI PICKED',
                              style: TextStyle(
                                color: primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  ...List.generate(
                    recipes.length,
                        (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == recipes.length - 1
                            ? 0
                            : 14,
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

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int index;
  final bool isTopMatch;

  const _RecipeCard({
    required this.recipe,
    required this.index,
    required this.isTopMatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    final surface =
        theme.colorScheme.surface;
    final primary =
        theme.colorScheme.primary;

    final textPrimary = isDark
        ? Colors.white
        : const Color(0xFF211D19);

    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF77716A);

    final border =
    theme.colorScheme.outline
        .withValues(
      alpha: isDark ? 0.20 : 0.10,
    );

    final match =
    recipe.ingredientMatch
        .clamp(0, 100);

    return Material(
      color: surface,
      borderRadius:
      BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RecipeDetailScreen(
                    recipe: recipe,
                  ),
            ),
          );
        },
        child: Container(
          padding:
          const EdgeInsets.all(18),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.16 : 0.045,
                ),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration:
                    BoxDecoration(
                      color:
                      primary.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        if (isTopMatch)
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              bottom: 5,
                            ),
                            child: Text(
                              'BEST MATCH',
                              style:
                              TextStyle(
                                color:
                                primary,
                                fontSize: 9,
                                fontWeight:
                                FontWeight
                                    .w900,
                                letterSpacing:
                                1.1,
                              ),
                            ),
                          ),

                        Text(
                          recipe.name,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          TextStyle(
                            color:
                            textPrimary,
                            fontSize: 19,
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing:
                            -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                    textSecondary,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(
                height: 11,
              ),

              Text(
                recipe.description,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              Row(
                children: [
                  _Meta(
                    icon:
                    Icons.timer_outlined,
                    text:
                    '${recipe.timeMinutes} min',
                    textColor:
                    textSecondary,
                  ),
                  _Dot(
                    color: textSecondary,
                  ),
                  _Meta(
                    icon:
                    Icons.currency_rupee_rounded,
                    text:
                    '₹${recipe.estimatedCost}',
                    textColor:
                    textSecondary,
                  ),
                  _Dot(
                    color: textSecondary,
                  ),
                  _Meta(
                    icon:
                    Icons.people_outline_rounded,
                    text:
                    '${recipe.servings}',
                    textColor:
                    textSecondary,
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Row(
                children: [
                  Text(
                    '$match% ingredient match',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const Spacer(),

                  if (recipe
                      .missingIngredients
                      .isEmpty)
                    Text(
                      'Everything you need',
                      style:
                      TextStyle(
                        color:
                        textSecondary,
                        fontSize: 9.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      '${recipe.missingIngredients.length} missing',
                      style:
                      TextStyle(
                        color:
                        textSecondary,
                        fontSize: 9.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child:
                LinearProgressIndicator(
                  value: match / 100,
                  minHeight: 5,
                  backgroundColor:
                  primary.withValues(
                    alpha: 0.08,
                  ),
                  valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                    primary,
                  ),
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              if (recipe
                  .ingredients
                  .isNotEmpty)
                _IngredientPreview(
                  recipe: recipe,
                  textSecondary:
                  textSecondary,
                ),

              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Text(
                    'VIEW RECIPE',
                    style:
                    TextStyle(
                      color: primary,
                      fontSize: 10.5,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing:
                      0.7,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Icon(
                    Icons
                        .arrow_forward_rounded,
                    color: primary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INGREDIENT PREVIEW
// ============================================================================

class _IngredientPreview
    extends StatelessWidget {
  final Recipe recipe;
  final Color textSecondary;

  const _IngredientPreview({
    required this.recipe,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final available = recipe
        .ingredients
        .where(
          (ingredient) =>
      ingredient.available,
    )
        .take(4)
        .toList();

    if (available.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 15,
          color: Color(0xFF4CAF50),
        ),
        const SizedBox(
          width: 6,
        ),
        Expanded(
          child: Text(
            available
                .map(
                  (ingredient) =>
              ingredient.name,
            )
                .join('  •  '),
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              color: textSecondary,
              fontSize: 10.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// META
// ============================================================================

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;

  const _Meta({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: textColor,
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 10.5,
            fontWeight:
            FontWeight.w700,
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

  const _Dot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      child: Container(
        width: 3,
        height: 3,
        decoration:
        BoxDecoration(
          color:
          color.withValues(
            alpha: 0.5,
          ),
          shape:
          BoxShape.circle,
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY
// ============================================================================

class _EmptyState
    extends StatelessWidget {
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
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration:
              BoxDecoration(
                color:
                primary.withValues(
                  alpha: 0.09,
                ),
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .restaurant_menu_rounded,
                color: primary,
                size: 32,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'Nothing to cook yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'Try adding a few more ingredients and let TADKA find something for you.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                textSecondary,
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

class RecipeDetailScreen
    extends StatefulWidget {
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
  State<RecipeDetailScreen>
  createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState
    extends State<RecipeDetailScreen> {
  late bool _isUnlocked;

  bool _isUnlocking = false;

  bool _isSaving = false;

  bool _isSaved = false;

  String? _savedDocumentId;

  Recipe get recipe =>
      widget.recipe;

  @override
  void initState() {
    super.initState();

    _isUnlocked =
        widget.isUnlocked;

    _isSaved =
        widget.isSaved;

    if (AuthService.instance
        .isSignedIn) {
      _checkSavedStatus();
    }
  }

  // ===========================================================================
  // FIRESTORE RECIPE DATA
  // ===========================================================================

  Map<String, dynamic>
  _recipeToMap() {
    return {
      'name': recipe.name,
      'description':
      recipe.description,
      'timeMinutes':
      recipe.timeMinutes,
      'estimatedCost':
      recipe.estimatedCost,
      'servings':
      recipe.servings,
      'difficulty':
      recipe.difficulty,
      'ingredientMatch':
      recipe.ingredientMatch,

      'ingredients':
      recipe.ingredients
          .map(
            (ingredient) => {
          'name':
          ingredient.name,
          'quantity':
          ingredient.quantity,
          'available':
          ingredient.available,
        },
      )
          .toList(),

      'missingIngredients':
      recipe.missingIngredients,

      'substitutions':
      recipe.substitutions,

      'equipment':
      recipe.equipment,

      'steps':
      recipe.steps,

      'tips':
      recipe.tips,

      'warnings':
      recipe.warnings,

      'imageUrl':
      recipe.imageUrl,
    };
  }

  // ===========================================================================
  // CHECK SAVED
  // ===========================================================================

  Future<void>
  _checkSavedStatus() async {
    final user =
        AuthService.instance
            .currentUser;

    if (user == null) {
      return;
    }

    try {
      final result =
      await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .collection(
        'savedRecipes',
      )
          .where(
        'name',
        isEqualTo: recipe.name,
      )
          .limit(1)
          .get();

      if (!mounted) return;

      if (result.docs.isNotEmpty) {
        setState(() {
          _isSaved = true;
          _savedDocumentId =
              result.docs.first.id;
        });
      } else {
        setState(() {
          _isSaved = false;
          _savedDocumentId = null;
        });
      }
    } catch (error) {
      debugPrint(
        'Check saved status error: $error',
      );
    }
  }

  // ===========================================================================
  // SAVE / UNSAVE
  // ===========================================================================

  Future<void>
  _toggleSave() async {
    if (_isSaving) {
      return;
    }

    HapticFeedback.selectionClick();

    // -------------------------------------------------------------------------
    // LOGIN REQUIRED
    // -------------------------------------------------------------------------

    if (!AuthService.instance
        .isSignedIn) {
      final result =
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const AuthScreen(),
        ),
      );

      if (!mounted) return;

      if (result != true &&
          !AuthService.instance
              .isSignedIn) {
        return;
      }

      // Re-check after login.
      await _checkSavedStatus();

      if (!mounted) return;
    }

    final user =
        AuthService.instance
            .currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to save recipes.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final collection =
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(
        'savedRecipes',
      );

      // =======================================================================
      // REMOVE
      // =======================================================================

      if (_isSaved) {
        String? documentId =
            _savedDocumentId;

        // If we don't have the ID, find it.
        if (documentId == null) {
          final result =
          await collection
              .where(
            'name',
            isEqualTo:
            recipe.name,
          )
              .limit(1)
              .get();

          if (result.docs
              .isNotEmpty) {
            documentId =
                result.docs.first.id;
          }
        }

        if (documentId != null) {
          await collection
              .doc(documentId)
              .delete();
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
        );

        return;
      }

      // =======================================================================
      // SAVE
      // =======================================================================

      // One final duplicate check.
      final existing =
      await collection
          .where(
        'name',
        isEqualTo:
        recipe.name,
      )
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _isSaved = true;
          _savedDocumentId =
              existing.docs.first.id;
          _isSaving = false;
        });

        _showMessage(
          'Recipe is already in your cookbook.',
        );

        return;
      }

      final data =
      _recipeToMap();

      data['savedAt'] =
          FieldValue.serverTimestamp();

      data['savedBy'] =
          user.uid;

      data['savedFrom'] =
      'recipe_detail';

      final document =
      await collection.add(data);

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _savedDocumentId =
            document.id;
        _isSaving = false;
      });

      HapticFeedback.mediumImpact();

      _showMessage(
        'Recipe saved to your cookbook.',
      );
    } on FirebaseException catch (
    error) {
      debugPrint(
        'Save recipe Firebase error: '
            '${error.code} - ${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (error.code ==
          'permission-denied') {
        _showMessage(
          'Permission denied. Please check your Firebase rules.',
        );
      } else {
        _showMessage(
          'Could not save this recipe. Please try again.',
        );
      }
    } catch (error) {
      debugPrint(
        'Save recipe error: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Could not save this recipe. Please try again.',
      );
    }
  }

  // ===========================================================================
  // WALLET
  // ===========================================================================

  Future<void>
  _initializeWallet() async {
    await CoinService.instance
        .ensureWallet();
  }

  // ===========================================================================
  // COIN UNLOCK
  // ===========================================================================

  Future<void>
  _unlockWithCoin() async {
    if (_isUnlocking) return;

    if (!AuthService.instance
        .isSignedIn) {
      _showMessage(
        'Sign in to use TADKA Coins.',
      );
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      await _initializeWallet();

      await CoinService.instance
          .spendCoin();

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

      _showMessage(e.message);
    } catch (error) {
      debugPrint(
        'Coin unlock error: $error',
      );

      if (!mounted) return;

      setState(() {
        _isUnlocking = false;
      });

      _showMessage(
        'Could not unlock this recipe. Please try again.',
      );
    }
  }

  // ===========================================================================
  // REWARDED AD UNLOCK
  // ===========================================================================

  Future<void>
  _watchAdToUnlock() async {
    if (_isUnlocking) return;

    if (!AuthService.instance
        .isSignedIn) {
      _showMessage(
        'Sign in to earn TADKA Coins.',
      );
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      await _initializeWallet();

      final rewarded =
      await RewardedAdService
          .instance
          .showRewardedAd();

      if (!rewarded) {
        if (!mounted) return;

        setState(() {
          _isUnlocking = false;
        });

        _showMessage(
          'The reward ad is not ready. Please try again.',
        );

        return;
      }

      await CoinService.instance
          .grantRewardCoin();

      await CoinService.instance
          .spendCoin();

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

      _showMessage(e.message);
    } catch (error) {
      debugPrint(
        'Reward unlock error: $error',
      );

      if (!mounted) return;

      setState(() {
        _isUnlocking = false;
      });

      _showMessage(
        'Could not unlock this recipe. Please try again.',
      );
    }
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  Future<void>
  _goToSignIn() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AuthScreen(),
      ),
    );

    if (!mounted) return;

    if (AuthService.instance
        .isSignedIn) {
      try {
        await _initializeWallet();
      } catch (_) {}

      await _checkSavedStatus();

      if (!mounted) return;

      setState(() {});
    }
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                message.toLowerCase().contains(
                  'saved',
                ) &&
                    !message
                        .toLowerCase()
                        .contains(
                      'removed',
                    )
                    ? Icons
                    .check_circle_rounded
                    : Icons
                    .info_outline_rounded,
                color: Colors.white,
                size: 19,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  message,
                ),
              ),
            ],
          ),
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final primary =
        theme.colorScheme.primary;

    final textPrimary = isDark
        ? Colors.white
        : const Color(0xFF211D19);

    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF77716A);

    final surface =
        theme.colorScheme.surface;

    final match =
    recipe.ingredientMatch
        .clamp(0, 100);

    // ========================================================================
    // LOCKED
    // ========================================================================

    if (!_isUnlocked) {
      return _LockedRecipeView(
        recipe: recipe,
        isUnlocking:
        _isUnlocking,
        onUseCoin:
        _unlockWithCoin,
        onWatchAd:
        _watchAdToUnlock,
        onSignIn:
        _goToSignIn,
      );
    }

    // ========================================================================
    // UNLOCKED
    // ========================================================================

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          tooltip: 'Back',
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context)
                .pop();
          },
        ),

        title: const Text(
          'Recipe',
          style: TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),

        actions: [
          // ================================================================
          // SAVE BUTTON
          // ================================================================

          Padding(
            padding:
            const EdgeInsets.only(
              right: 8,
            ),
            child: IconButton(
              tooltip: _isSaved
                  ? 'Remove from cookbook'
                  : 'Save recipe',
              onPressed:
              _isSaving
                  ? null
                  : _toggleSave,
              style:
              IconButton.styleFrom(
                backgroundColor:
                primary.withValues(
                  alpha: 0.07,
                ),
              ),
              icon: _isSaving
                  ? SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  primary,
                ),
              )
                  : AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds: 180,
                ),
                child: Icon(
                  _isSaved
                      ? Icons
                      .bookmark_rounded
                      : Icons
                      .bookmark_border_rounded,
                  key: ValueKey(
                    _isSaved,
                  ),
                  color:
                  _isSaved
                      ? primary
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child:
        SingleChildScrollView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            40,
          ),
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              // ==============================================================
              // SAVED STATUS
              // ==============================================================

              if (_isSaved)
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration:
                  BoxDecoration(
                    color: primary
                        .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .bookmark_rounded,
                        size: 14,
                        color: primary,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Saved to your cookbook',
                        style:
                        TextStyle(
                          color:
                          primary,
                          fontSize: 9.5,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isSaved)
                const SizedBox(
                  height: 15,
                ),

              // ==============================================================
              // HEADER
              // ==============================================================

              Text(
                'YOUR RECIPE',
                style:
                TextStyle(
                  color:
                  primary,
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing:
                  1.3,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                recipe.name,
                style:
                TextStyle(
                  color:
                  textPrimary,
                  fontSize: 31,
                  height: 1.05,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing:
                  -0.9,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                recipe.description,
                style:
                TextStyle(
                  color:
                  textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==============================================================
              // META
              // ==============================================================

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailMeta(
                    icon:
                    Icons.timer_outlined,
                    label:
                    '${recipe.timeMinutes} min',
                    primary:
                    primary,
                    surface:
                    surface,
                  ),
                  _DetailMeta(
                    icon:
                    Icons.people_outline_rounded,
                    label:
                    '${recipe.servings} servings',
                    primary:
                    primary,
                    surface:
                    surface,
                  ),
                  _DetailMeta(
                    icon:
                    Icons.currency_rupee_rounded,
                    label:
                    '₹${recipe.estimatedCost}',
                    primary:
                    primary,
                    surface:
                    surface,
                  ),
                  _DetailMeta(
                    icon:
                    Icons.signal_cellular_alt_rounded,
                    label:
                    recipe.difficulty,
                    primary:
                    primary,
                    surface:
                    surface,
                  ),
                ],
              ),

              const SizedBox(
                height: 30,
              ),

              // ==============================================================
              // WHY THIS RECIPE
              // ==============================================================

              _SectionHeading(
                title:
                'Why this recipe',
                subtitle:
                'TADKA picked it based on your ingredients.',
                textPrimary:
                textPrimary,
                textSecondary:
                textSecondary,
              ),

              const SizedBox(
                height: 13,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  primary.withValues(
                    alpha:
                    isDark
                        ? 0.08
                        : 0.05,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    17,
                  ),
                  border:
                  Border.all(
                    color:
                    primary.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child:
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons
                              .check_circle_rounded,
                          color:
                          primary,
                          size: 18,
                        ),

                        const SizedBox(
                          width: 9,
                        ),

                        Expanded(
                          child:
                          Text(
                            '$match% of the recipe matches your ingredients',
                            style:
                            TextStyle(
                              color:
                              textPrimary,
                              fontSize:
                              12,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                      child:
                      LinearProgressIndicator(
                        value:
                        match / 100,
                        minHeight:
                        5,
                        backgroundColor:
                        primary
                            .withValues(
                          alpha:
                          0.08,
                        ),
                        valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                          primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==============================================================
              // INGREDIENTS
              // ==============================================================

              _SectionHeading(
                title:
                'Ingredients',
                subtitle:
                'Everything you need to make it.',
                textPrimary:
                textPrimary,
                textSecondary:
                textSecondary,
              ),

              const SizedBox(
                height: 15,
              ),

              if (recipe.ingredients
                  .isEmpty)
                Text(
                  'No ingredient details were returned.',
                  style:
                  TextStyle(
                    color:
                    textSecondary,
                    fontSize:
                    12.5,
                  ),
                )
              else
                ...recipe.ingredients.map(
                      (ingredient) {
                    return Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 29,
                            height: 29,
                            decoration:
                            BoxDecoration(
                              color: ingredient
                                  .available
                                  ? const Color(
                                0xFFE8F5E9,
                              )
                                  : const Color(
                                0xFFFFE8E5,
                              ),
                              shape:
                              BoxShape
                                  .circle,
                            ),
                            child:
                            Icon(
                              ingredient
                                  .available
                                  ? Icons
                                  .check_rounded
                                  : Icons
                                  .add_rounded,
                              size: 16,
                              color: ingredient
                                  .available
                                  ? const Color(
                                0xFF388E3C,
                              )
                                  : const Color(
                                0xFFE85D04,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 11,
                          ),

                          Expanded(
                            child:
                            Text(
                              ingredient
                                  .name,
                              style:
                              TextStyle(
                                color:
                                textPrimary,
                                fontSize:
                                13.5,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Flexible(
                            child:
                            Text(
                              ingredient
                                  .quantity,
                              textAlign:
                              TextAlign
                                  .right,
                              style:
                              TextStyle(
                                color:
                                textSecondary,
                                fontSize:
                                11,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // ==============================================================
              // MISSING
              // ==============================================================

              if (recipe
                  .missingIngredients
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 14,
                ),

                _SectionHeading(
                  title:
                  'You may need',
                  subtitle:
                  "A few things that aren't in your kitchen list.",
                  textPrimary:
                  textPrimary,
                  textSecondary:
                  textSecondary,
                ),

                const SizedBox(
                  height: 13,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  recipe
                      .missingIngredients
                      .map(
                        (item) =>
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            isDark
                                ? Colors
                                .white
                                .withValues(
                              alpha:
                              0.05,
                            )
                                : const Color(
                              0xFFF7F3EE,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                          ),
                          child:
                          Text(
                            item,
                            style:
                            TextStyle(
                              color:
                              textSecondary,
                              fontSize:
                              11,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ),
                  ).toList(),
                ),
              ],

              // ==============================================================
              // SUBSTITUTIONS
              // ==============================================================

              if (recipe
                  .substitutions
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 30,
                ),

                _SectionHeading(
                  title:
                  'Easy substitutions',
                  subtitle:
                  'Alternatives you can use if needed.',
                  textPrimary:
                  textPrimary,
                  textSecondary:
                  textSecondary,
                ),

                const SizedBox(
                  height: 13,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .all(
                    15,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    isDark
                        ? Colors.white
                        .withValues(
                      alpha:
                      0.04,
                    )
                        : const Color(
                      0xFFF9F6F1,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      17,
                    ),
                  ),
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children:
                    recipe
                        .substitutions
                        .map(
                          (item) =>
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              bottom: 9,
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Icon(
                                  Icons
                                      .swap_horiz_rounded,
                                  size: 17,
                                  color:
                                  primary,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child:
                                  Text(
                                    item,
                                    style:
                                    TextStyle(
                                      color:
                                      textPrimary,
                                      fontSize:
                                      12.5,
                                      height:
                                      1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ).toList(),
                  ),
                ),
              ],

              // ==============================================================
              // EQUIPMENT
              // ==============================================================

              if (recipe
                  .equipment
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 30,
                ),

                _SectionHeading(
                  title:
                  'Equipment',
                  subtitle:
                  'Keep these things ready.',
                  textPrimary:
                  textPrimary,
                  textSecondary:
                  textSecondary,
                ),

                const SizedBox(
                  height: 13,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  recipe
                      .equipment
                      .map(
                        (item) =>
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            surface,
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                            border:
                            Border.all(
                              color: theme
                                  .colorScheme
                                  .outline
                                  .withValues(
                                alpha:
                                0.10,
                              ),
                            ),
                          ),
                          child:
                          Text(
                            item,
                            style:
                            TextStyle(
                              color:
                              textSecondary,
                              fontSize:
                              11,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ),
                  ).toList(),
                ),
              ],

              const SizedBox(
                height: 32,
              ),

              // ==============================================================
              // STEPS
              // ==============================================================

              _SectionHeading(
                title:
                'How to cook',
                subtitle:
                'Follow these steps from start to finish.',
                textPrimary:
                textPrimary,
                textSecondary:
                textSecondary,
              ),

              const SizedBox(
                height: 17,
              ),

              if (recipe.steps.isEmpty)
                Text(
                  'No cooking steps were returned.',
                  style:
                  TextStyle(
                    color:
                    textSecondary,
                    fontSize:
                    12.5,
                  ),
                )
              else
                ...List.generate(
                  recipe.steps.length,
                      (index) {
                    final isLast =
                        index ==
                            recipe.steps
                                .length -
                                1;

                    return Padding(
                      padding:
                      EdgeInsets.only(
                        bottom:
                        isLast
                            ? 0
                            : 19,
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                decoration:
                                BoxDecoration(
                                  color:
                                  primary,
                                  shape:
                                  BoxShape
                                      .circle,
                                ),
                                child:
                                Center(
                                  child:
                                  Text(
                                    '${index + 1}',
                                    style:
                                    const TextStyle(
                                      color:
                                      Colors.white,
                                      fontSize:
                                      11,
                                      fontWeight:
                                      FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),

                              if (!isLast)
                                Container(
                                  width:
                                  1,
                                  height:
                                  22,
                                  margin:
                                  const EdgeInsets
                                      .only(
                                    top: 5,
                                  ),
                                  color:
                                  primary
                                      .withValues(
                                    alpha:
                                    0.15,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(
                            width: 13,
                          ),

                          Expanded(
                            child:
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                top: 5,
                              ),
                              child:
                              Text(
                                recipe.steps[
                                index],
                                style:
                                TextStyle(
                                  color:
                                  textPrimary,
                                  fontSize:
                                  13.5,
                                  height:
                                  1.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // ==============================================================
              // TIPS
              // ==============================================================

              if (recipe.tips
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 32,
                ),

                _SectionHeading(
                  title:
                  'Chef tips',
                  subtitle:
                  'Small details that can make a difference.',
                  textPrimary:
                  textPrimary,
                  textSecondary:
                  textSecondary,
                ),

                const SizedBox(
                  height: 13,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .all(
                    16,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    isDark
                        ? Colors.white
                        .withValues(
                      alpha:
                      0.04,
                    )
                        : const Color(
                      0xFFF9F6F1,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      17,
                    ),
                  ),
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children:
                    recipe.tips
                        .map(
                          (tip) =>
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              bottom: 10,
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  '•',
                                  style:
                                  TextStyle(
                                    color:
                                    primary,
                                    fontSize:
                                    16,
                                    fontWeight:
                                    FontWeight
                                        .w900,
                                  ),
                                ),
                                const SizedBox(
                                  width: 9,
                                ),
                                Expanded(
                                  child:
                                  Text(
                                    tip,
                                    style:
                                    TextStyle(
                                      color:
                                      textPrimary,
                                      fontSize:
                                      12.5,
                                      height:
                                      1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ).toList(),
                  ),
                ),
              ],

              // ==============================================================
              // WARNINGS
              // ==============================================================

              if (recipe.warnings
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 22,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .all(
                    15,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    isDark
                        ? const Color(
                      0xFF3A241A,
                    )
                        : const Color(
                      0xFFFFF4EA,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons
                                .info_outline_rounded,
                            size: 18,
                            color:
                            primary,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Good to know',
                            style:
                            TextStyle(
                              color:
                              textPrimary,
                              fontWeight:
                              FontWeight
                                  .w800,
                              fontSize:
                              13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      ...recipe
                          .warnings
                          .map(
                            (warning) =>
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                bottom: 5,
                              ),
                              child:
                              Text(
                                '• $warning',
                                style:
                                TextStyle(
                                  color:
                                  textSecondary,
                                  fontSize:
                                  11.5,
                                  height:
                                  1.4,
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(
                height: 30,
              ),

              // ==============================================================
              // START COOKING CTA
              // ==============================================================

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      primary.withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StartCookingScreen(
                            recipe: recipe,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 13),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready to cook?',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Start Cooking',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // SAVE CTA
              // ==============================================================

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  primary.withValues(
                    alpha:
                    isDark
                        ? 0.08
                        : 0.055,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  border:
                  Border.all(
                    color:
                    primary.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child:
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration:
                      BoxDecoration(
                        color:
                        primary
                            .withValues(
                          alpha:
                          0.11,
                        ),
                        shape:
                        BoxShape
                            .circle,
                      ),
                      child:
                      Icon(
                        _isSaved
                            ? Icons
                            .bookmark_rounded
                            : Icons
                            .bookmark_border_rounded,
                        color:
                        primary,
                        size: 22,
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
                            _isSaved
                                ? 'Saved in your cookbook'
                                : 'Love this recipe?',
                            style:
                            TextStyle(
                              color:
                              textPrimary,
                              fontSize:
                              12.5,
                              fontWeight:
                              FontWeight
                                  .w900,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            _isSaved
                                ? 'You can find it anytime in Cookbook.'
                                : 'Save it for the next time you cook.',
                            style:
                            TextStyle(
                              color:
                              textSecondary,
                              fontSize:
                              9.5,
                              height:
                              1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    FilledButton(
                      onPressed:
                      _isSaving
                          ? null
                          : _toggleSave,
                      style:
                      FilledButton
                          .styleFrom(
                        minimumSize:
                        const Size(
                          0,
                          42,
                        ),
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 15,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                      child:
                      _isSaving
                          ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          Colors.white,
                        ),
                      )
                          : Text(
                        _isSaved
                            ? 'Saved'
                            : 'Save',
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
// LOCKED RECIPE
// ============================================================================

class _LockedRecipeView
    extends StatelessWidget {
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
    final theme =
    Theme.of(context);
    final colors =
        theme.colorScheme;

    final signedIn =
        AuthService.instance
            .isSignedIn;

    return Scaffold(
      appBar: AppBar(
        leading:
        IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () =>
              Navigator.of(context)
                  .pop(),
        ),
        title:
        const Text(
          'Recipe',
          style:
          TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child:
        SingleChildScrollView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            36,
          ),
          child:
          Column(
            children: [
              if (recipe.imageUrl
                  .trim()
                  .isNotEmpty)
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    24,
                  ),
                  child:
                  Image.network(
                    recipe.imageUrl,
                    width:
                    double.infinity,
                    height:
                    220,
                    fit:
                    BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                    const SizedBox(
                      height: 0,
                    ),
                  ),
                ),

              const SizedBox(
                height: 22,
              ),

              Container(
                width: 76,
                height: 76,
                decoration:
                BoxDecoration(
                  color: colors
                      .primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                Icon(
                  Icons.lock_rounded,
                  color:
                  colors.primary,
                  size: 34,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Text(
                recipe.name,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 25,
                  height: 1.1,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing:
                  -0.5,
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              Text(
                'Your recipe is ready. Unlock it to see the complete ingredients and cooking steps.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color: colors
                      .onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              StreamBuilder<int>(
                stream: signedIn
                    ? CoinService
                    .instance
                    .watchCoins()
                    : Stream<int>.value(
                  0,
                ),
                builder:
                    (
                    context,
                    snapshot,
                    ) {
                  final coins =
                      snapshot.data ??
                          0;

                  return Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets
                        .all(
                      16,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      colors.surface,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                      border:
                      Border.all(
                        color: colors
                            .outline
                            .withValues(
                          alpha:
                          0.10,
                        ),
                      ),
                    ),
                    child:
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFFFB300,
                            ).withValues(
                              alpha:
                              0.14,
                            ),
                            shape:
                            BoxShape
                                .circle,
                          ),
                          child:
                          const Icon(
                            Icons
                                .monetization_on_rounded,
                            color:
                            Color(
                              0xFFE49A00,
                            ),
                            size:
                            22,
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
                              const Text(
                                'TADKA Coins',
                                style:
                                TextStyle(
                                  fontSize:
                                  12,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                signedIn
                                    ? '$coins ${coins == 1 ? 'coin' : 'coins'} available'
                                    : 'Sign in to get your welcome coins',
                                style:
                                TextStyle(
                                  color: colors
                                      .onSurfaceVariant,
                                  fontSize:
                                  10,
                                  fontWeight:
                                  FontWeight
                                      .w500,
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

              const SizedBox(
                height: 14,
              ),

              if (!signedIn)
                _SignInUnlockCard(
                  onTap:
                  onSignIn,
                )
              else ...[
                SizedBox(
                  width:
                  double.infinity,
                  height: 54,
                  child:
                  FilledButton.icon(
                    onPressed:
                    isUnlocking
                        ? null
                        : onUseCoin,
                    icon:
                    const Icon(
                      Icons
                          .monetization_on_rounded,
                      size: 20,
                    ),
                    label:
                    Text(
                      isUnlocking
                          ? 'Unlocking...'
                          : 'Use 1 Coin to Unlock',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                    style:
                    FilledButton
                        .styleFrom(
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 11,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  height: 54,
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    isUnlocking
                        ? null
                        : onWatchAd,
                    icon:
                    const Icon(
                      Icons
                          .play_circle_outline_rounded,
                      size: 21,
                    ),
                    label:
                    Text(
                      isUnlocking
                          ? 'Preparing reward...'
                          : 'Watch Ad to Unlock',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                    style:
                    OutlinedButton
                        .styleFrom(
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 9,
                ),

                Text(
                  'Watching a rewarded ad earns 1 coin and uses it to unlock this recipe.',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 9.5,
                    height: 1.4,
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

class _SignInUnlockCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _SignInUnlockCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color: colors
            .primary
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color: colors
              .primary
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child:
      Column(
        children: [
          const Text(
            'Sign in required',
            style:
            TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Create your TADKA wallet and receive 10 welcome coins.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color: colors
                  .onSurfaceVariant,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width:
            double.infinity,
            height: 46,
            child:
            FilledButton(
              onPressed:
              onTap,
              child:
              const Text(
                'Sign in with Google',
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
    );
  }
}

// ============================================================================
// DETAIL META
// ============================================================================

class _DetailMeta
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final Color surface;

  const _DetailMeta({
    required this.icon,
    required this.label,
    required this.primary,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final border =
    Theme.of(context)
        .colorScheme
        .outline
        .withValues(
      alpha: 0.10,
    );

    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration:
      BoxDecoration(
        color:
        surface,
        borderRadius:
        BorderRadius.circular(
          11,
        ),
        border:
        Border.all(
          color:
          border,
        ),
      ),
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
            primary,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,
            style:
            const TextStyle(
              fontSize: 10.5,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION HEADING
// ============================================================================

class _SectionHeading
    extends StatelessWidget {
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
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          TextStyle(
            color:
            textPrimary,
            fontSize:
            19,
            fontWeight:
            FontWeight.w900,
            letterSpacing:
            -0.35,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          subtitle,
          style:
          TextStyle(
            color:
            textSecondary,
            fontSize:
            11,
            height:
            1.35,
          ),
        ),
      ],
    );
  }
}