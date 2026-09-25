// lib/features/recipes/recipe_results_screen.dart

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ads/banner_ad_widget.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/ai/recipe_ai_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/coins/coin_service.dart';
import '../auth/auth_screen.dart';
import '../cooking/start_cooking_screen.dart';
import '../preferences/cooking_preferences.dart';
import 'recipe.dart';

// ============================================================================
// ENUMS & PREMIUM PALETTE
// ============================================================================

enum _FeedbackType { success, info, error }

class _Palette {
  final bool isDark;
  final Color primary;

  const _Palette({required this.isDark, required this.primary});

  Color get background =>
      isDark ? const Color(0xFF090A10) : const Color(0xFFF7F5F0);

  Color get surface =>
      isDark ? const Color(0xFF131622) : const Color(0xFFFFFFFF);

  Color get surfaceAlt =>
      isDark ? const Color(0xFF1A1E2D) : const Color(0xFFEFECE6);

  Color get border => isDark
      ? const Color(0xFF282F44)
      : const Color(0xFFE2DDD4);

  Color get textPrimary =>
      isDark ? const Color(0xFFFAFBFD) : const Color(0xFF121826);

  Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF526071);

  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFEF4444);
  Color get cyanAccent => const Color(0xFF06B6D4);
  Color get orangeAccent => const Color(0xFFFF5722);
}

// ============================================================================
// RECIPE RESULTS SCREEN
// ============================================================================

class RecipeResultsScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final List<String>? ingredients;
  final CookingPreferences? preferences;
  final String? dishRequest;

  const RecipeResultsScreen({
    super.key,
    required this.recipes,
    this.ingredients,
    this.preferences,
    this.dishRequest,
  });

  @override
  State<RecipeResultsScreen> createState() => _RecipeResultsScreenState();
}

class _RecipeResultsScreenState extends State<RecipeResultsScreen> {
  static const int _maxGenerateMore = 5;

  late List<Recipe> _recipes;

  int _generateMoreUsed = 0;
  bool _isGenerating = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _recipes = List<Recipe>.from(widget.recipes);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasIngredientContext =>
      widget.ingredients != null &&
          widget.ingredients!.isNotEmpty &&
          widget.preferences != null;

  bool get _hasRequestContext =>
      widget.dishRequest != null && widget.dishRequest!.trim().isNotEmpty;

  bool get _canGenerateMore => _hasIngredientContext || _hasRequestContext;

  int get _remainingGenerations => _maxGenerateMore - _generateMoreUsed;

  bool get _limitReached => _remainingGenerations <= 0;

  Future<void> _generateMore() async {
    if (_isGenerating || _limitReached || !_canGenerateMore) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isGenerating = true;
    });

    try {
      final existingNames = _recipes.map((recipe) => recipe.name).toList();

      List<Recipe> fresh;

      if (_hasIngredientContext) {
        fresh = await RecipeAIService.instance.generateRecipes(
          ingredients: widget.ingredients!,
          preferences: widget.preferences!,
          excludeNames: existingNames,
        );
      } else {
        fresh = await RecipeAIService.instance.generateRecipeByName(
          widget.dishRequest!,
          excludeNames: existingNames,
          recipeCount: 3,
        );
      }

      if (!mounted) return;

      final seen = existingNames
          .map(_normalizeName)
          .where((name) => name.isNotEmpty)
          .toSet();

      final unique = <Recipe>[];

      for (final recipe in fresh) {
        final key = _normalizeName(recipe.name);
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        unique.add(recipe);
      }

      if (unique.isEmpty) {
        setState(() {
          _isGenerating = false;
          _generateMoreUsed++;
        });

        _showMessage(
          context,
          'TADKA could not find new ideas this time. Try again.',
          type: _FeedbackType.info,
        );
        return;
      }

      setState(() {
        _recipes.addAll(unique);
        _generateMoreUsed++;
        _isGenerating = false;
      });

      HapticFeedback.lightImpact();

      _showMessage(
        context,
        unique.length == 1
            ? '1 new recipe added.'
            : '${unique.length} new recipes added.',
        type: _FeedbackType.success,
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));

      if (!mounted || !_scrollController.hasClients) return;

      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } on RecipeAIException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      _showMessage(context, e.message, type: _FeedbackType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      _showMessage(
        context,
        'Could not generate more recipes. Please try again.',
        type: _FeedbackType.error,
      );
    }
  }

  String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _showMessage(
      BuildContext context,
      String message, {
        _FeedbackType type = _FeedbackType.info,
      }) {
    if (!mounted) return;

    final IconData icon;
    final Color backgroundColor;

    switch (type) {
      case _FeedbackType.success:
        icon = Icons.check_circle_rounded;
        backgroundColor = const Color(0xFF10B981);
        break;
      case _FeedbackType.error:
        icon = Icons.error_outline_rounded;
        backgroundColor = const Color(0xFFEF4444);
        break;
      case _FeedbackType.info:
        icon = Icons.info_outline_rounded;
        backgroundColor = const Color(0xFF1E293B);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          elevation: 10,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final palette = _Palette(
      isDark: theme.brightness == Brightness.dark,
      primary: primary,
    );

    return Scaffold(
      backgroundColor: palette.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: palette.background.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          child: _TopIconButton(
            icon: Icons.arrow_back_rounded,
            palette: palette,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 5),
                Text(
                  'TADKA AI',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              'Your Kitchen Creations',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _recipes.isEmpty
                  ? _EmptyState(
                textPrimary: palette.textPrimary,
                textSecondary: palette.textSecondary,
                primary: primary,
              )
                  : ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                children: [
                  _HeroBanner(
                    count: _recipes.length,
                    palette: palette,
                    hasIngredientContext: _hasIngredientContext,
                    dishRequest: widget.dishRequest,
                  ),
                  const SizedBox(height: 14),
                  if (_hasIngredientContext)
                    _ContextStrip(
                      ingredients: widget.ingredients!,
                      palette: palette,
                    ),
                  if (_hasIngredientContext) const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Curated For You',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap any dish to open step-by-step instructions.',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.12),
                              primary.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AI MATCHED',
                              style: TextStyle(
                                color: primary,
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
                  const SizedBox(height: 16),
                  ...List.generate(
                    _recipes.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _RecipeCard(
                        recipe: _recipes[index],
                        index: index,
                        isTopMatch: index == 0,
                        palette: palette,
                      ),
                    ),
                  ),
                  if (_canGenerateMore) ...[
                    const SizedBox(height: 6),
                    _GenerateMorePanel(
                      palette: palette,
                      isGenerating: _isGenerating,
                      used: _generateMoreUsed,
                      total: _maxGenerateMore,
                      onGenerate: _generateMore,
                    ),
                  ],
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
// HERO BANNER
// ============================================================================

class _HeroBanner extends StatelessWidget {
  final int count;
  final _Palette palette;
  final bool hasIngredientContext;
  final String? dishRequest;

  const _HeroBanner({
    required this.count,
    required this.palette,
    required this.hasIngredientContext,
    required this.dishRequest,
  });

  @override
  Widget build(BuildContext context) {
    final title = hasIngredientContext
        ? 'Dinner Starts\nRight Here.'
        : 'Something Special\nIs Ready.';

    final subtitle = hasIngredientContext
        ? 'Smart recipes designed around what you have.'
        : (dishRequest != null && dishRequest!.trim().isNotEmpty
        ? 'Fresh culinary ideas tailored to your craving.'
        : 'Freshly prepared recipe creations by TADKA AI.');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [
            const Color(0xFF2C1810),
            const Color(0xFF1B1218),
            palette.surface,
          ]
              : [
            const Color(0xFFFFECE0),
            const Color(0xFFFFF7ED),
            palette.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(
              alpha: palette.isDark ? 0.20 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.primary.withValues(alpha: 0.18),
                    palette.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 18, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$count ${count == 1 ? 'RECIPE CREATED' : 'RECIPES CREATED'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: palette.primary,
                      size: 34,
                    ),
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

class _ContextStrip extends StatelessWidget {
  final List<String> ingredients;
  final _Palette palette;

  const _ContextStrip({
    required this.ingredients,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final visible = ingredients
        .where((item) => item.trim().isNotEmpty)
        .take(5)
        .toList();
    final remaining = ingredients.length - visible.length;

    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.kitchen_rounded,
                size: 14,
                color: palette.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'COOKING WITH INGREDIENTS',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...visible.map(
                    (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (remaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$remaining more',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
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
// RECIPE CARD (ADAPTIVE LAYOUT FOR IMAGE VS NO-IMAGE)
// ============================================================================

class _RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final int index;
  final bool isTopMatch;
  final _Palette palette;

  const _RecipeCard({
    required this.recipe,
    required this.index,
    required this.isTopMatch,
    required this.palette,
  });

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  bool _isPressed = false;
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final match = widget.recipe.ingredientMatch.clamp(0, 100);
    final hasValidImage =
        widget.recipe.imageUrl.trim().isNotEmpty && !_imageError;
    final missingCount = widget.recipe.missingIngredients.length;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: widget.isTopMatch
                ? palette.primary.withValues(alpha: 0.5)
                : palette.border,
            width: widget.isTopMatch ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isTopMatch
                  ? palette.primary.withValues(
                alpha: palette.isDark ? 0.20 : 0.08,
              )
                  : Colors.black.withValues(
                alpha: palette.isDark ? 0.25 : 0.04,
              ),
              blurRadius: widget.isTopMatch ? 24 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onHighlightChanged: (highlighted) {
                if (mounted) {
                  setState(() => _isPressed = highlighted);
                }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CONDITIONAL IMAGE BANNER
                  if (hasValidImage)
                    SizedBox(
                      height: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            widget.recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() => _imageError = true);
                                }
                              });
                              return const SizedBox.shrink();
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: palette.surfaceAlt,
                                child: Center(
                                  child: SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: palette.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.82),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _GlassBadge(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'RECIPE #${widget.index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: _GlassBadge(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.recipe.timeMinutes} MINS',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.success,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$match% Match',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.isTopMatch)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'TOP PICK',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // DETAILS CARD CONTENT (CLEAN INTEGRATED BADGES WHEN NO IMAGE)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasValidImage) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'RECIPE #${widget.index + 1}',
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$match% Match',
                                  style: TextStyle(
                                    color: palette.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (widget.isTopMatch) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.warning.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: palette.warning,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'TOP PICK',
                                        style: TextStyle(
                                          color: palette.warning,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.recipe.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: palette.primary,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.recipe.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricBadge(
                                icon: Icons.timer_outlined,
                                accentColor: palette.primary,
                                label: 'Prep Time',
                                value: '${widget.recipe.timeMinutes}m',
                                palette: palette,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricBadge(
                                icon: Icons.currency_rupee_rounded,
                                accentColor: palette.success,
                                label: 'Est. Cost',
                                value: '₹${widget.recipe.estimatedCost}',
                                palette: palette,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricBadge(
                                icon: Icons.people_outline_rounded,
                                accentColor: palette.cyanAccent,
                                label: 'Servings',
                                value: '${widget.recipe.servings}',
                                palette: palette,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              missingCount == 0
                                  ? Icons.check_circle_rounded
                                  : Icons.shopping_basket_outlined,
                              size: 15,
                              color: missingCount == 0
                                  ? palette.success
                                  : palette.orangeAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                missingCount == 0
                                    ? 'You have all ingredients ready'
                                    : '$missingCount ${missingCount == 1 ? 'ingredient' : 'ingredients'} missing',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: missingCount == 0
                                      ? palette.success
                                      : palette.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'EXPLORE',
                              style: TextStyle(
                                color: palette.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
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
      ),
    );
  }
}

// ============================================================================
// METRIC BADGE
// ============================================================================

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String label;
  final String value;
  final _Palette palette;

  const _MetricBadge({
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GLASS BADGE
// ============================================================================

class _GlassBadge extends StatelessWidget {
  final Widget child;

  const _GlassBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.black.withValues(alpha: 0.45),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================================
// GENERATE MORE PANEL
// ============================================================================

class _GenerateMorePanel extends StatelessWidget {
  final _Palette palette;
  final bool isGenerating;
  final int used;
  final int total;
  final VoidCallback onGenerate;

  const _GenerateMorePanel({
    required this.palette,
    required this.isGenerating,
    required this.used,
    required this.total,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final limitReached = remaining <= 0;
    final progress = total == 0 ? 1.0 : (used / total).clamp(0.0, 1.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [const Color(0xFF2C1E18), palette.surface]
              : [const Color(0xFFFFF1E6), palette.surface],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(
              alpha: palette.isDark ? 0.12 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.primary,
                        palette.primary.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limitReached
                            ? 'Explored All Ideas'
                            : 'Want More Ideas?',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        limitReached
                            ? 'Daily generation limit reached for this session.'
                            : 'Let TADKA AI generate 3 more recipes.',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: palette.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (isGenerating || limitReached) ? null : onGenerate,
                icon: isGenerating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                ),
                label: Text(
                  isGenerating
                      ? 'Generating Fresh Recipes...'
                      : limitReached
                      ? 'Refresh Limit Reached'
                      : 'Generate 3 More Recipes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final _Palette palette;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, color: palette.textPrimary, size: 19),
        ),
      ),
    );
  }
}

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
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Recipes Generated',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your selected ingredients and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
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
      _showMessage('Please sign in to save recipes.', type: _FeedbackType.info);
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
        _showMessage('Removed from your cookbook.', type: _FeedbackType.info);
        return;
      }

      final data = _recipeToMap();
      data['savedAt'] = FieldValue.serverTimestamp();
      data['savedBy'] = user.uid;

      final document = await collection.add(data);

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _savedDocumentId = document.id;
        _isSaving = false;
      });

      HapticFeedback.mediumImpact();
      _showMessage('Saved to your cookbook!', type: _FeedbackType.success);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showMessage('Could not save recipe. Please try again.', type: _FeedbackType.error);
    }
  }

  Future<void> _unlockWithCoin() async {
    if (_isUnlocking) return;

    if (!AuthService.instance.isSignedIn) {
      _showMessage('Sign in to use TADKA Coins.', type: _FeedbackType.info);
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      await CoinService.instance.ensureWallet();
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
      _showMessage('Could not unlock recipe. Please try again.', type: _FeedbackType.error);
    }
  }

  Future<void> _watchAdToUnlock() async {
    if (_isUnlocking) return;

    if (!AuthService.instance.isSignedIn) {
      _showMessage('Sign in to earn TADKA Coins.', type: _FeedbackType.info);
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      await CoinService.instance.ensureWallet();
      final rewarded = await RewardedAdService.instance.showRewardedAd();

      if (!rewarded) {
        if (!mounted) return;
        setState(() {
          _isUnlocking = false;
        });
        _showMessage('The reward ad is not ready. Please try again.', type: _FeedbackType.error);
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
      _showMessage('Could not unlock recipe.', type: _FeedbackType.error);
    }
  }

  void _showMessage(String message, { _FeedbackType type = _FeedbackType.info }) {
    if (!mounted) return;

    final IconData icon = type == _FeedbackType.success
        ? Icons.check_circle_rounded
        : (type == _FeedbackType.error
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded);

    final Color backgroundColor = type == _FeedbackType.success
        ? const Color(0xFF10B981)
        : (type == _FeedbackType.error
        ? const Color(0xFFEF4444)
        : const Color(0xFF1E293B));

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
    final primary = theme.colorScheme.primary;
    final palette = _Palette(
      isDark: theme.brightness == Brightness.dark,
      primary: primary,
    );

    final match = recipe.ingredientMatch.clamp(0, 100);
    final hasImage = recipe.imageUrl.trim().isNotEmpty;

    if (!_isUnlocked) {
      return _LockedRecipeView(
        recipe: recipe,
        isUnlocking: _isUnlocking,
        onUseCoin: _unlockWithCoin,
        onWatchAd: _watchAdToUnlock,
        onSignIn: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
          if (mounted) setState(() {});
        },
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: hasImage ? 290 : 120,
            backgroundColor: palette.background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
              child: _GlassCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 6, bottom: 6),
                child: _GlassCircleIconButton(
                  icon: _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  busy: _isSaving,
                  onTap: _toggleSave,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(recipe.imageUrl, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  : Container(color: palette.surface),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isSaved) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          'SAVED IN YOUR COOKBOOK',
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
                  const SizedBox(height: 14),
                ],
                Text(
                  recipe.name,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  recipe.description,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBadge(
                        icon: Icons.timer_outlined,
                        accentColor: primary,
                        label: 'Time',
                        value: '${recipe.timeMinutes}m',
                        palette: palette,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricBadge(
                        icon: Icons.currency_rupee_rounded,
                        accentColor: palette.success,
                        label: 'Est. Cost',
                        value: '₹${recipe.estimatedCost}',
                        palette: palette,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricBadge(
                        icon: Icons.people_outline_rounded,
                        accentColor: palette.cyanAccent,
                        label: 'Servings',
                        value: '${recipe.servings}',
                        palette: palette,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricBadge(
                        icon: Icons.bar_chart_rounded,
                        accentColor: palette.orangeAccent,
                        label: 'Skill',
                        value: recipe.difficulty,
                        palette: palette,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
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
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$match% Ingredient Match Rate',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 13.5,
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
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Ingredients Required',
                  subtitle: 'Everything needed for this recipe.',
                  palette: palette,
                ),
                const SizedBox(height: 12),
                ...recipe.ingredients.map((ingredient) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ingredient.available
                            ? palette.primary.withValues(alpha: 0.3)
                            : palette.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ingredient.available
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 18,
                          color: ingredient.available
                              ? primary
                              : palette.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient.name,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          ingredient.quantity,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (recipe.missingIngredients.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Missing Ingredients',
                    subtitle: 'Items you might need to pick up.',
                    palette: palette,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.missingIngredients.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: palette.orangeAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (recipe.substitutions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Easy Substitutions',
                    subtitle: 'Alternative ingredients you can swap in.',
                    palette: palette,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.border),
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
                                    color: palette.textPrimary,
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
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
                if (recipe.equipment.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Required Equipment',
                    subtitle: 'Kitchen cookware to have ready.',
                    palette: palette,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.equipment.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Step-by-Step Instructions',
                  subtitle: 'Follow along from start to finish.',
                  palette: palette,
                ),
                const SizedBox(height: 12),
                ...List.generate(recipe.steps.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            recipe.steps[index],
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 13.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (recipe.tips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'Chef Tips',
                    subtitle: 'Pro suggestions to enhance flavour.',
                    palette: palette,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.15),
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
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
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
                if (recipe.warnings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: palette.warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Good to know',
                              style: TextStyle(
                                color: palette.warning,
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
                                color: palette.textSecondary,
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _toggleSave,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Icon(
                      _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartCookingScreen(recipe: recipe),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Start Interactive Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final _Palette palette;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlassCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;

  const _GlassCircleIconButton({
    required this.icon,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: busy
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

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
    final primary = theme.colorScheme.primary;
    final palette = _Palette(
      isDark: theme.brightness == Brightness.dark,
      primary: primary,
    );
    final signedIn = AuthService.instance.isSignedIn;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: palette.textPrimary,
              size: 19,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Unlock Recipe',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: palette.textPrimary,
          ),
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                recipe.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your recipe is ready. Unlock it to view complete ingredients and step-by-step instructions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<int>(
                stream: signedIn
                    ? CoinService.instance.watchCoins()
                    : Stream<int>.value(0),
                builder: (context, snapshot) {
                  final coins = snapshot.data ?? 0;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.monetization_on_rounded,
                            color: primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TADKA Coins',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                signedIn
                                    ? '$coins ${coins == 1 ? 'coin' : 'coins'} available in your wallet'
                                    : 'Sign in to claim welcome coins',
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 11,
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
              const SizedBox(height: 18),
              if (!signedIn)
                _SignInUnlockCard(onTap: onSignIn)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isUnlocking ? null : onUseCoin,
                    icon: const Icon(Icons.monetization_on_rounded, size: 19),
                    label: Text(
                      isUnlocking ? 'Unlocking...' : 'Use 1 Coin to Unlock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                      size: 19,
                    ),
                    label: Text(
                      isUnlocking
                          ? 'Preparing Reward...'
                          : 'Watch Ad to Unlock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

class _SignInUnlockCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SignInUnlockCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Text(
            'Sign In Required',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your TADKA wallet to receive welcome coins and unlock custom recipes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue with Google',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}