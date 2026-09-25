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
  State<SearchRecipeScreen> createState() => _SearchRecipeScreenState();
}

class _SearchRecipeScreenState extends State<SearchRecipeScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================================
  // CONTROLLERS & FOCUS
  // ==========================================================================

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ==========================================================================
  // STATE & ANIMATION
  // ==========================================================================

  bool _loading = false;
  int _messageIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  // ==========================================================================
  // LOADING MESSAGES & ICONS
  // ==========================================================================

  final List<String> _loadingMessages = [
    'Understanding your culinary craving...',
    'Selecting authentic ingredients & spices...',
    'Balancing secret flavors and proportions...',
    'Formatting step-by-step cooking instructions...',
    'Adding the final golden TADKA touch...',
  ];

  final List<IconData> _loadingIcons = [
    Icons.auto_awesome_rounded,
    Icons.kitchen_rounded,
    Icons.local_fire_department_rounded,
    Icons.menu_book_rounded,
    Icons.whatshot_rounded,
  ];

  // ==========================================================================
  // EXAMPLES WITH CATEGORIES
  // ==========================================================================

  final List<Map<String, dynamic>> _examples = [
    {'title': 'Paneer Butter Masala', 'icon': Icons.restaurant_rounded},
    {'title': 'Aloo Paratha', 'icon': Icons.flatware_rounded},
    {'title': 'Restaurant Style Biryani', 'icon': Icons.local_fire_department_rounded},
    {'title': 'Easy Pasta for Dinner', 'icon': Icons.dinner_dining_rounded},
    {'title': 'Spicy Paneer Starter', 'icon': Icons.bolt_rounded},
    {'title': 'Quick Healthy Breakfast', 'icon': Icons.free_breakfast_rounded},
  ];

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final initialDish = widget.initialDish?.trim();

      if (initialDish != null && initialDish.isNotEmpty) {
        _controller.text = initialDish;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: initialDish.length),
        );

        _generateRecipe();
        return;
      }

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

    final query = _controller.text.trim();

    if (query.isEmpty) {
      _focusNode.requestFocus();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Please enter a dish or craving to cook.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
      final recipes = await RecipeAIService.instance.generateRecipeByName(query);

      if (!mounted) return;

      _stopLoadingMessages();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeResultsScreen(
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
              error.toString().replaceFirst('RecipeAIException: ', ''),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _generateRecipe,
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
      await Future.delayed(const Duration(milliseconds: 2400));

      if (!mounted || !_loading) {
        return false;
      }

      setState(() {
        _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
      });

      return _loading;
    });
  }

  void _stopLoadingMessages() {}

  // ==========================================================================
  // EXAMPLE SELECTION
  // ==========================================================================

  void _selectExample(String value) {
    HapticFeedback.selectionClick();

    setState(() {
      _controller.text = value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    });

    _focusNode.requestFocus();
  }

  // ==========================================================================
  // LEAVE DIALOG
  // ==========================================================================

  Future<bool> _showLeaveDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Stop recipe generation?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: const Text(
            'TADKA AI is crafting your recipe. If you go back now, this generation will be discarded.',
            style: TextStyle(fontSize: 13.5, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'KEEP WAITING',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_loading) {
          final leave = await _showLeaveDialog();
          if (leave && mounted) {
            setState(() {
              _loading = false;
            });
          }
        }
      },
      child: _loading ? _buildLoadingScreen(context) : _buildSearchScreen(context),
    );
  }

  // ==========================================================================
  // SEARCH SCREEN
  // ==========================================================================

  Widget _buildSearchScreen(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create a Recipe',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      'AI RECIPE STUDIO',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'What do you want\nto cook today?',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Name a dish, describe a craving, or simply tell TADKA AI what flavor profile you are in the mood for.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // Search Input Box
              _SearchInput(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: (_) => _generateRecipe(),
                onGenerate: _generateRecipe,
              ),

              const SizedBox(height: 26),

              // Try Asking Header
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.primary,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Popular Culinary Ideas',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Example Pills
              Wrap(
                spacing: 8,
                runSpacing: 9,
                children: _examples.map((example) {
                  return _ExampleChip(
                    text: example['title'] as String,
                    icon: example['icon'] as IconData,
                    onTap: () => _selectExample(example['title'] as String),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Colorful AI Feature Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary.withValues(alpha: 0.10),
                      colors.primary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHEF\'S TIP',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "You don't need exact recipe titles. Try searching natural prompts like \"something fast with paneer\" or \"creamy soup without dairy\".",
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11.5,
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
        ),
      ),
    );
  }

  // ==========================================================================
  // LOADING SCREEN
  // ==========================================================================

  Widget _buildLoadingScreen(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final primary = colors.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final leave = await _showLeaveDialog();
                        if (leave && mounted) {
                          setState(() {
                            _loading = false;
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outline.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Creating Recipe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading Body
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Flame Sphere
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                Color.lerp(primary, Colors.black, 0.22) ?? primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.32),
                                blurRadius: 32,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'TADKA AI',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Searching recipe for "${_controller.text.trim()}"',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Animated Status Card
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          key: ValueKey(_messageIndex),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _loadingIcons[_messageIndex],
                                  color: primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _loadingMessages[_messageIndex],
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 150,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(10),
                          color: primary,
                          backgroundColor: primary.withValues(alpha: 0.12),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Preparing step-by-step cooking timeline...',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
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

class _SearchInput extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.go,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'e.g. Paneer Butter Masala, Creamy Pasta...',
              hintStyle: TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.primary,
                size: 22,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: colors.onSurfaceVariant,
                      onPressed: () {
                        controller.clear();
                        focusNode.requestFocus();
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
                    child: Material(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onGenerate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EXAMPLE CHIP
// ============================================================================

class _ExampleChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.add_rounded,
                size: 14,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}