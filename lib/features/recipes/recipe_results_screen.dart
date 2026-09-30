// lib/features/recipes/recipe_results_screen.dart

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
// FEEDBACK TYPE
// ============================================================================

enum _FeedbackType { success, info, error }

// ============================================================================
// DESIGN SYSTEM PALETTE
// ============================================================================

class _Palette {
  final bool isDark;

  const _Palette(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF090A0F) : const Color(0xFFF3F5F9);

  Color get surface => isDark ? const Color(0xFF13151C) : Colors.white;

  Color get surfaceGlass =>
      isDark ? const Color(0xFF1B1E28) : const Color(0xFFFAFCFF);

  Color get surfaceAlt =>
      isDark ? const Color(0xFF222634) : const Color(0xFFEEF2F6);

  Color get border =>
      isDark ? const Color(0xFF2A2E3D) : const Color(0xFFE2E7F0);

  Color get textPrimary =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Color get success => const Color(0xFF10B981);

  Color get successBackground =>
      isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);

  Color get warning => const Color(0xFFF59E0B);

  Color get warningBackground =>
      isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);

  Color get error => const Color(0xFFEF4444);

  Color get errorBackground =>
      isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
}

// ============================================================================
// ENTRANCE ANIMATION
// ============================================================================

class _EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int delayMilliseconds;

  const _EntranceAnimation({
    required this.child,
    this.delayMilliseconds = 0,
  });

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future<void>.delayed(
      Duration(milliseconds: widget.delayMilliseconds),
          () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
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

  // ---------------------------------------------------------------------------
  // GENERATE MORE LOGIC
  // ---------------------------------------------------------------------------

  bool get _hasIngredientContext =>
      widget.ingredients != null && widget.ingredients!.isNotEmpty;

  bool get _hasRequestContext =>
      widget.dishRequest != null && widget.dishRequest!.trim().isNotEmpty;

  int get _remainingGenerations => _maxGenerateMore - _generateMoreUsed;

  bool get _limitReached => _remainingGenerations <= 0;

  Future<void> _generateMore() async {
    if (_isGenerating || _limitReached) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isGenerating = true;
    });

    try {
      final existingNames = _recipes.map((recipe) => recipe.name).toList();

      List<Recipe> fresh;

      if (_hasIngredientContext && widget.preferences != null) {
        fresh = await RecipeAIService.instance.generateRecipes(
          ingredients: widget.ingredients!,
          preferences: widget.preferences!,
          excludeNames: existingNames,
        );
      } else if (_hasRequestContext) {
        fresh = await RecipeAIService.instance.generateRecipeByName(
          widget.dishRequest!,
          excludeNames: existingNames,
          recipeCount: 3,
        );
      } else {
        // Fallback context from first recipe
        final baseName =
        _recipes.isNotEmpty ? _recipes.first.name : 'Delicious Dish';
        fresh = await RecipeAIService.instance.generateRecipeByName(
          baseName,
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
        duration: const Duration(milliseconds: 550),
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
        backgroundColor = const Color(0xFF3B82F6);
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
    final palette = _Palette(theme.brightness == Brightness.dark);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            palette: palette,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Text(
          'Your Kitchen Ideas',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
            color: palette.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _ResultsHeader(
                    count: _recipes.length,
                    palette: palette,
                    primary: primary,
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    _recipes.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _EntranceAnimation(
                        delayMilliseconds: index < 4 ? index * 75 : 0,
                        child: _RecipeCard(
                          recipe: _recipes[index],
                          index: index,
                          isTopMatch: index == 0,
                          palette: palette,
                        ),
                      ),
                    ),
                  ),
                  // 1. INLINE GENERATE MORE CARD
                  _GenerateMorePanel(
                    palette: palette,
                    primary: primary,
                    isGenerating: _isGenerating,
                    used: _generateMoreUsed,
                    total: _maxGenerateMore,
                    onGenerate: _generateMore,
                  ),
                ],
              ),
            ),
            const BannerAdWidget(),
            const SizedBox(height: 4),
          ],
        ),
      ),

      // 2. FIXED STICKY GENERATE MORE FOOTER
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(
            top: BorderSide(
              color: primary.withValues(alpha: 0.18),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.35 : 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
              (_isGenerating || _limitReached) ? null : _generateMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: palette.surfaceAlt,
                elevation: _limitReached ? 0 : 4,
                shadowColor: primary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isGenerating
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SEARCHING NEW DISHES...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
                  : _limitReached
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ALL REFRESH TOKENS USED',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'GENERATE MORE RECIPES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_remainingGenerations LEFT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
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
// HERO HEADER
// ============================================================================

class _ResultsHeader extends StatelessWidget {
  final int count;
  final _Palette palette;
  final Color primary;

  const _ResultsHeader({
    required this.count,
    required this.palette,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = palette.isDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF231E3D),
            const Color(0xFF141620),
          ]
              : [
            primary,
            primary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.25 : 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'AI GENERATED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$count ${count == 1 ? 'Recipe Ready' : 'Recipes Ready'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tailored precisely to your selected pantry ingredients and diet preferences.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

// ============================================================================
// GENERATE MORE PANEL
// ============================================================================

class _GenerateMorePanel extends StatelessWidget {
  final _Palette palette;
  final Color primary;
  final bool isGenerating;
  final int used;
  final int total;
  final VoidCallback onGenerate;

  const _GenerateMorePanel({
    required this.palette,
    required this.primary,
    required this.isGenerating,
    required this.used,
    required this.total,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final limitReached = remaining <= 0;

    return Column(
      children: [
        if (isGenerating) ...[
          const _GeneratingPlaceholder(),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: limitReached
                  ? palette.border
                  : primary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.isDark ? 0.3 : 0.04,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
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
                      color: limitReached
                          ? palette.surfaceAlt
                          : primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      limitReached
                          ? Icons.check_circle_outline_rounded
                          : Icons.auto_awesome_rounded,
                      color: limitReached ? palette.textSecondary : primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          limitReached
                              ? "That's all for now"
                              : 'Explore More Ideas',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          limitReached
                              ? 'You used all $total refresh tokens in this session.'
                              : 'Ask TADKA AI to search alternative dish combinations.',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: List.generate(total, (index) {
                  final consumed = index < used;

                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(
                        right: index == total - 1 ? 0 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: consumed
                            ? primary
                            : primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  limitReached ? 'Limit reached' : '$remaining of $total left',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: limitReached
                    ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text(
                    'No Refreshes Remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
                    : DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isGenerating
                        ? const []
                        : [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isGenerating
                              ? [
                            primary.withValues(alpha: 0.55),
                            primary.withValues(alpha: 0.45),
                          ]
                              : [
                            primary,
                            primary.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                      child: InkWell(
                        onTap: isGenerating ? null : onGenerate,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isGenerating)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                isGenerating
                                    ? 'Generating new ideas...'
                                    : 'Generate More Recipes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
// GENERATING PLACEHOLDER
// ============================================================================

class _GeneratingPlaceholder extends StatefulWidget {
  const _GeneratingPlaceholder();

  @override
  State<_GeneratingPlaceholder> createState() => _GeneratingPlaceholderState();
}

class _GeneratingPlaceholderState extends State<_GeneratingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette(Theme.of(context).brightness == Brightness.dark);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.3);

        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(palette, widthFactor: 0.55, height: 16),
                const SizedBox(height: 10),
                _bar(palette, widthFactor: 0.9, height: 10),
                const SizedBox(height: 6),
                _bar(palette, widthFactor: 0.75, height: 10),
                const SizedBox(height: 14),
                _bar(palette, widthFactor: 1, height: 38),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bar(
      _Palette palette, {
        required double widthFactor,
        required double height,
      }) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ============================================================================
// CIRCLE ICON BUTTON
// ============================================================================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final _Palette palette;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.25 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: palette.textPrimary),
        tooltip: tooltip,
        onPressed: onTap,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = widget.palette;
    final isDark = palette.isDark;
    final primary = theme.colorScheme.primary;

    final match = widget.recipe.ingredientMatch.clamp(0, 100);
    final hasImage = widget.recipe.imageUrl.trim().isNotEmpty;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
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
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: widget.isTopMatch ? primary : palette.border,
                width: widget.isTopMatch ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isTopMatch
                      ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                      : Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          widget.recipe.imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 180,
                              color: palette.surfaceAlt,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primary,
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
                                  Colors.black.withValues(alpha: 0.25),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.60),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
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
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.recipe.timeMinutes} MINS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasImage) ...[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.isTopMatch
                                    ? primary
                                    : primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.index + 1}',
                                  style: TextStyle(
                                    color: widget.isTopMatch
                                        ? Colors.white
                                        : primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                      color: palette.warningBackground,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: palette.warning
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: palette.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'TOP MATCH',
                                          style: TextStyle(
                                            color: palette.warning,
                                            fontSize: 9,
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
                                    color: palette.textPrimary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: primary,
                              size: 13,
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
                          color: palette.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: _Meta(
                                icon: Icons.timer_outlined,
                                iconColor: const Color(0xFF0288D1),
                                text: '${widget.recipe.timeMinutes}m',
                                textColor: palette.textPrimary,
                              ),
                            ),
                            _Dot(color: palette.textSecondary),
                            Flexible(
                              child: _Meta(
                                icon: Icons.currency_rupee_rounded,
                                iconColor: palette.success,
                                text: '₹${widget.recipe.estimatedCost}',
                                textColor: palette.textPrimary,
                              ),
                            ),
                            _Dot(color: palette.textSecondary),
                            Flexible(
                              child: _Meta(
                                icon: Icons.people_outline_rounded,
                                iconColor: palette.warning,
                                text: '${widget.recipe.servings} Serv',
                                textColor: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
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
                                    ? palette.success
                                    : palette.warning,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: match / 100),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: primary.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(primary),
                              ),
                        ),
                      ),
                      if (widget.recipe.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _IngredientPreview(
                          recipe: widget.recipe,
                          palette: palette,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'COOK THIS RECIPE',
                            style: TextStyle(
                              color: primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(width: 6),
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
  final _Palette palette;

  const _IngredientPreview({
    required this.recipe,
    required this.palette,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.successBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: palette.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available.map((ingredient) => ingredient.name).join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.success,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
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
              width: 88,
              height: 88,
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
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing to cook yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adding a few more ingredients and let TADKA find something for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
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
        backgroundColor = const Color(0xFF3B82F6);
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
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  void _startCooking() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartCookingScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _Palette(theme.brightness == Brightness.dark);
    final primary = theme.colorScheme.primary;

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
      backgroundColor: palette.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: hasImage ? 290 : 150,
            backgroundColor: palette.background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6),
              child: _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Back',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 6, bottom: 6),
                child: _GlassIconButton(
                  icon: _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  tooltip: _isSaved ? 'Remove from cookbook' : 'Save recipe',
                  busy: _isSaving,
                  onTap: _isSaving ? null : _toggleSave,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
              centerTitle: true,
              title: Text(
                recipe.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasImage ? Colors.white : palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              background: hasImage
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: palette.surfaceAlt,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ],
              )
                  : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.18),
                      palette.background,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isSaved) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_rounded,
                          size: 15,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SAVED TO COOKBOOK',
                          style: TextStyle(
                            color: primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Text(
                  'YOUR RECIPE',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.name,
                  style: TextStyle(
                    color: palette.textPrimary,
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
                    color: palette.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DetailMeta(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF0288D1),
                      label: '${recipe.timeMinutes} mins',
                      palette: palette,
                    ),
                    _DetailMeta(
                      icon: Icons.people_outline_rounded,
                      iconColor: palette.warning,
                      label: '${recipe.servings} Servings',
                      palette: palette,
                    ),
                    _DetailMeta(
                      icon: Icons.currency_rupee_rounded,
                      iconColor: palette.success,
                      label: '₹${recipe.estimatedCost}',
                      palette: palette,
                    ),
                    _DetailMeta(
                      icon: Icons.signal_cellular_alt_rounded,
                      iconColor: primary,
                      label: recipe.difficulty,
                      palette: palette,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _SectionHeading(
                  title: 'Why this recipe',
                  subtitle: 'TADKA picked it based on your ingredients.',
                  textPrimary: palette.textPrimary,
                  textSecondary: palette.textSecondary,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(
                          alpha: palette.isDark ? 0.12 : 0.05,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                              '$match% of the recipe matches your ingredients',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: match / 100),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 7,
                                backgroundColor: primary.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(primary),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _SectionHeading(
                  title: 'Ingredients',
                  subtitle: 'Everything you need to make it.',
                  textPrimary: palette.textPrimary,
                  textSecondary: palette.textSecondary,
                ),
                const SizedBox(height: 14),
                if (recipe.ingredients.isEmpty)
                  Text(
                    'No ingredient details were returned.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                    ),
                  )
                else
                  ...recipe.ingredients.map((ingredient) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: ingredient.available
                              ? palette.success.withValues(alpha: 0.35)
                              : palette.warning.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: ingredient.available
                                  ? palette.successBackground
                                  : palette.warningBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ingredient.available
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 16,
                              color: ingredient.available
                                  ? palette.success
                                  : palette.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              ingredient.name,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 5,
                            child: Text(
                              ingredient.quantity,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                if (recipe.missingIngredients.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: 'You may need',
                    subtitle: "A few things that aren't in your kitchen list.",
                    textPrimary: palette.textPrimary,
                    textSecondary: palette.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.missingIngredients.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.warningBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: palette.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: palette.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (recipe.substitutions.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionHeading(
                    title: 'Easy substitutions',
                    subtitle: 'Alternatives you can use if needed.',
                    textPrimary: palette.textPrimary,
                    textSecondary: palette.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
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
                                size: 18,
                                color: primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 13,
                                    height: 1.45,
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
                  const SizedBox(height: 28),
                  _SectionHeading(
                    title: 'Equipment',
                    subtitle: 'Keep these things ready.',
                    textPrimary: palette.textPrimary,
                    textSecondary: palette.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.equipment.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                _SectionHeading(
                  title: 'How to cook',
                  subtitle: 'Follow these steps from start to finish.',
                  textPrimary: palette.textPrimary,
                  textSecondary: palette.textSecondary,
                ),
                const SizedBox(height: 16),
                if (recipe.steps.isEmpty)
                  Text(
                    'No cooking steps were returned.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                    ),
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
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.35),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    color: primary.withValues(alpha: 0.25),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Text(
                                  recipe.steps[index],
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 13.5,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                if (recipe.tips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionHeading(
                    title: 'Chef tips',
                    subtitle: 'Small details that can make a difference.',
                    textPrimary: palette.textPrimary,
                    textSecondary: palette.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.warningBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: palette.warning.withValues(alpha: 0.4),
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
                                Icons.lightbulb_rounded,
                                size: 18,
                                color: palette.warning,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 13,
                                    height: 1.45,
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.errorBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: palette.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: palette.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Good to know',
                              style: TextStyle(
                                color: palette.error,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...recipe.warnings.map((warning) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $warning',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 12,
                                height: 1.4,
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
          border: Border(
            top: BorderSide(color: palette.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.25 : 0.06,
              ),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _toggleSave,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(
                        color: _isSaved ? primary : palette.border,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
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
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                primary,
                                primary.withValues(alpha: 0.82),
                              ],
                            ),
                          ),
                          child: InkWell(
                            onTap: _startCooking,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Start Cooking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

// ============================================================================
// GLASS ICON BUTTON
// ============================================================================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool busy;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
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
            : Icon(icon, size: 17, color: Colors.white),
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
    final palette = _Palette(theme.brightness == Brightness.dark);
    final signedIn = AuthService.instance.isSignedIn;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
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
                Stack(
                  children: [
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
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.38),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
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
                            color: const Color(0xFFFFB300)
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFE49A00),
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
                                  fontSize: 13,
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
              const SizedBox(height: 16),
              if (!signedIn)
                _SignInUnlockCard(onTap: onSignIn)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: isUnlocking ? null : onUseCoin,
                    icon: const Icon(Icons.monetization_on_rounded, size: 20),
                    label: Text(
                      isUnlocking ? 'Unlocking...' : 'Use 1 Coin to Unlock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: isUnlocking ? null : onWatchAd,
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isUnlocking
                          ? 'Preparing reward...'
                          : 'Watch Ad to Unlock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Watching a rewarded ad earns 1 coin and uses it to unlock this recipe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Text(
            'Sign in required',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your TADKA wallet and receive 10 welcome coins.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
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
  final _Palette palette;

  const _DetailMeta({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
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
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.5,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}