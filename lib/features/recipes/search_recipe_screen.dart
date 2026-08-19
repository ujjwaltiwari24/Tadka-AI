import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ai/recipe_ai_service.dart';
import 'recipe_results_screen.dart';

class SearchRecipeScreen extends StatefulWidget {
  /// If provided, the recipe screen will automatically
  /// generate a recipe for this dish.
  ///
  /// Example:
  /// SearchRecipeScreen(
  ///   initialDish: 'Paneer Butter Masala',
  /// )
  final String? initialDish;

  const SearchRecipeScreen({
    super.key,
    this.initialDish,
  });

  @override
  State<SearchRecipeScreen> createState() =>
      _SearchRecipeScreenState();
}

class _SearchRecipeScreenState
    extends State<SearchRecipeScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================================
  // CONTROLLERS
  // ==========================================================================

  final TextEditingController _controller =
  TextEditingController();

  final FocusNode _focusNode =
  FocusNode();

  // ==========================================================================
  // STATE
  // ==========================================================================

  bool _loading = false;

  int _messageIndex = 0;

  late final AnimationController
  _animationController;

  // ==========================================================================
  // LOADING MESSAGES
  // ==========================================================================

  final List<String> _loadingMessages = [
    'Understanding what you want to cook...',
    'Building the perfect ingredient list...',
    'Balancing flavors and spices...',
    'Writing your recipe...',
    'Adding the finishing tadka...',
  ];

  // ==========================================================================
  // EXAMPLES
  // ==========================================================================

  final List<String> _examples = [
    'Paneer Butter Masala',
    'Aloo Paratha',
    'Restaurant style biryani',
    'Easy pasta for dinner',
    'Something spicy with paneer',
    'Quick breakfast',
  ];

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _animationController =
    AnimationController(
      vsync: this,
      duration:
      const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      final initialDish =
      widget.initialDish?.trim();

      // ================================================================
      // OPENED FROM RECENTLY ADDED
      // ================================================================

      if (initialDish != null &&
          initialDish.isNotEmpty) {
        _controller.text = initialDish;

        _controller.selection =
            TextSelection.fromPosition(
              TextPosition(
                offset: initialDish.length,
              ),
            );

        // Automatically generate the recipe.
        _generateRecipe();

        return;
      }

      // ================================================================
      // NORMAL SEARCH SCREEN
      // ================================================================

      _focusNode.requestFocus();
    });
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // GENERATE RECIPE
  // ==========================================================================

  Future<void> _generateRecipe() async {
    if (_loading) return;

    final query =
    _controller.text.trim();

    if (query.isEmpty) {
      _focusNode.requestFocus();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Tell me what you want to cook.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      return;
    }

    HapticFeedback.mediumImpact();

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _messageIndex = 0;
    });

    _startLoadingMessages();

    try {
      // ================================================================
      // AI RECIPE GENERATION
      // ================================================================

      final recipes =
      await RecipeAIService.instance
          .generateRecipeByName(query);

      if (!mounted) return;

      _stopLoadingMessages();

      // ================================================================
      // OPEN RESULTS
      // ================================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RecipeResultsScreen(
                recipes: recipes,
              ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _stopLoadingMessages();

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error
                  .toString()
                  .replaceFirst(
                'RecipeAIException: ',
                '',
              ),
            ),
            behavior:
            SnackBarBehavior.floating,
            duration:
            const Duration(seconds: 4),
            margin:
            const EdgeInsets.all(16),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),
            action:
            SnackBarAction(
              label: 'RETRY',
              onPressed:
              _generateRecipe,
            ),
          ),
        );
    }
  }

  // ==========================================================================
  // LOADING MESSAGES
  // ==========================================================================

  void _startLoadingMessages() {
    Future.doWhile(() async {
      await Future.delayed(
        const Duration(
          milliseconds: 2200,
        ),
      );

      if (!mounted || !_loading) {
        return false;
      }

      setState(() {
        _messageIndex =
            (_messageIndex + 1) %
                _loadingMessages.length;
      });

      return _loading;
    });
  }

  void _stopLoadingMessages() {
    // The loading loop automatically
    // stops when _loading becomes false.
  }

  // ==========================================================================
  // EXAMPLE SELECTION
  // ==========================================================================

  void _selectExample(String value) {
    HapticFeedback.selectionClick();

    setState(() {
      _controller.text = value;

      _controller.selection =
          TextSelection.fromPosition(
            TextPosition(
              offset: value.length,
            ),
          );
    });

    _focusNode.requestFocus();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult:
          (didPop, result) {
        if (didPop) return;

        if (_loading) {
          setState(() {
            _loading = false;
          });
        }
      },
      child: _loading
          ? _buildLoadingScreen(context)
          : _buildSearchScreen(context),
    );
  }

  // ==========================================================================
  // SEARCH SCREEN
  // ==========================================================================

  Widget _buildSearchScreen(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();

            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create a recipe',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ============================================================
              // TITLE
              // ============================================================

              Text(
                'What do you want\nto cook?',
                style: TextStyle(
                  color:
                  colors.onSurface,
                  fontSize: 31,
                  height: 1.08,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Name a dish, describe a craving, '
                    'or simply tell TADKA what you are '
                    'in the mood for.',
                style: TextStyle(
                  color:
                  colors.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 26),

              // ============================================================
              // SEARCH INPUT
              // ============================================================

              _SearchInput(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: (_) =>
                    _generateRecipe(),
                onGenerate:
                _generateRecipe,
              ),

              const SizedBox(height: 28),

              // ============================================================
              // EXAMPLES
              // ============================================================

              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color:
                    colors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Try asking for',
                    style: TextStyle(
                      color:
                      colors.onSurface,
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Wrap(
                spacing: 9,
                runSpacing: 9,
                children:
                _examples.map(
                      (example) {
                    return _ExampleChip(
                      text: example,
                      onTap: () =>
                          _selectExample(
                            example,
                          ),
                    );
                  },
                ).toList(),
              ),

              const SizedBox(height: 30),

              // ============================================================
              // TIP
              // ============================================================

              Container(
                padding:
                const EdgeInsets.all(16),
                decoration:
                BoxDecoration(
                  color:
                  colors.primary
                      .withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons
                          .lightbulb_outline_rounded,
                      color:
                      colors.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You don't need to know the exact "
                            'recipe name. Try something like '
                            '"something quick with paneer".',
                        style: TextStyle(
                          color: colors
                              .onSurfaceVariant,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight:
                          FontWeight.w500,
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

  // ==========================================================================
  // LOADING SCREEN
  // ==========================================================================

  Widget _buildLoadingScreen(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ================================================================
            // HEADER
            // ================================================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                14,
                10,
                20,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _loading = false;
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      'Creating your recipe',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.auto_awesome_rounded,
                    color:
                    colors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),

            // ================================================================
            // LOADING CONTENT
            // ================================================================

            Expanded(
              child: Center(
                child: Padding(
                  padding:
                  const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation:
                        _animationController,
                        builder:
                            (context, child) {
                          final scale =
                              0.94 +
                                  (_animationController
                                      .value *
                                      0.10);

                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration:
                          BoxDecoration(
                            color:
                            colors.primary,
                            shape:
                            BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors
                                    .primary
                                    .withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 35,
                              ),
                            ],
                          ),
                          child:
                          const Icon(
                            Icons
                                .local_fire_department_rounded,
                            color:
                            Colors.white,
                            size: 55,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      const Text(
                        'TADKA AI',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AnimatedSwitcher(
                        duration:
                        const Duration(
                          milliseconds: 300,
                        ),
                        child: Text(
                          _loadingMessages[
                          _messageIndex],
                          key: ValueKey(
                            _messageIndex,
                          ),
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            color: colors
                                .onSurfaceVariant,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      SizedBox(
                        width: 160,
                        child:
                        LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                          color:
                          colors.primary,
                          backgroundColor:
                          colors.primary
                              .withValues(
                            alpha: 0.10,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      Text(
                        'Almost there...',
                        style: TextStyle(
                          color: colors
                              .onSurfaceVariant
                              .withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
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

// ============================================================================
// SEARCH INPUT
// ============================================================================

class _SearchInput
    extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onGenerate;

  const _SearchInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 20,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction:
        TextInputAction.done,
        textCapitalization:
        TextCapitalization.sentences,
        minLines: 1,
        maxLines: 3,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText:
          'e.g. Paneer Butter Masala',
          prefixIcon: const Padding(
            padding:
            EdgeInsets.only(
              left: 4,
              right: 2,
            ),
            child: Icon(
              Icons.search_rounded,
            ),
          ),
          suffixIcon: Padding(
            padding:
            const EdgeInsets.only(
              right: 6,
              top: 6,
              bottom: 6,
            ),
            child: Material(
              color: colors.primary,
              borderRadius:
              BorderRadius.circular(
                13,
              ),
              child: InkWell(
                onTap: onGenerate,
                borderRadius:
                BorderRadius.circular(
                  13,
                ),
                child: const SizedBox(
                  width: 45,
                  child: Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                    Colors.white,
                  ),
                ),
              ),
            ),
          ),
          filled: true,
          fillColor:
          colors.surface,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(19),
            borderSide: BorderSide(
              color: colors.outline
                  .withValues(
                alpha: 0.15,
              ),
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(19),
            borderSide: BorderSide(
              color: colors.outline
                  .withValues(
                alpha: 0.15,
              ),
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(19),
            borderSide: BorderSide(
              color: colors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE CHIP
// ============================================================================

class _ExampleChip
    extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius:
      BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(13),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(13),
            border: Border.all(
              color: colors.outline
                  .withValues(
                alpha: 0.14,
              ),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color:
              colors.onSurface,
              fontSize: 11.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}