import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ai/recipe_ai_service.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_results_screen.dart';
import 'cooking_preferences.dart';

class CookingPreferencesScreen extends StatefulWidget {
  final List<String> ingredients;

  final String? initialTime;
  final String? initialDiet;
  final String? initialSpice;
  final String? initialSkill;

  const CookingPreferencesScreen({
    super.key,
    required this.ingredients,
    this.initialTime,
    this.initialDiet,
    this.initialSpice,
    this.initialSkill,
  });

  @override
  State<CookingPreferencesScreen> createState() =>
      _CookingPreferencesScreenState();
}

class _CookingPreferencesScreenState extends State<CookingPreferencesScreen>
    with SingleTickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // PREFERENCES
  // --------------------------------------------------------------------------

  String time = '20 min';
  String budget = '₹100';
  int servings = 2;
  String diet = 'Vegetarian';
  String spice = 'Medium';
  String skill = 'Beginner';

  final Set<String> avoid = {
    'No onion',
    'No garlic',
  };

  final List<String> times = [
    '10 min',
    '20 min',
    '30 min',
    '45 min',
    '60+ min',
  ];

  final List<String> budgets = [
    '₹50',
    '₹100',
    '₹200',
    'No limit',
  ];

  final List<String> diets = [
    'Vegetarian',
    'Vegan',
    'Eggless',
    'Jain',
  ];

  final List<String> spices = [
    'Mild',
    'Medium',
    'Spicy',
  ];

  final List<String> skills = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  // --------------------------------------------------------------------------
  // LOADING STATE
  // --------------------------------------------------------------------------

  bool loading = false;

  Timer? _messageTimer;
  int _messageIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  final List<String> _loadingMessages = [
    'Analyzing your ingredients...',
    'Finding delicious combinations...',
    'Balancing flavors and spices...',
    'Building the perfect recipe...',
    'Adding the finishing tadka...',
  ];

  final List<IconData> _loadingIcons = [
    Icons.search_rounded,
    Icons.auto_awesome_rounded,
    Icons.local_fire_department_rounded,
    Icons.restaurant_menu_rounded,
    Icons.whatshot_rounded,
  ];

  // --------------------------------------------------------------------------
  // INIT
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    if (widget.initialTime != null && times.contains(widget.initialTime)) {
      time = widget.initialTime!;
    }

    if (widget.initialDiet != null && diets.contains(widget.initialDiet)) {
      diet = widget.initialDiet!;
    }

    if (widget.initialSpice != null && spices.contains(widget.initialSpice)) {
      spice = widget.initialSpice!;
    }

    if (widget.initialSkill != null && skills.contains(widget.initialSkill)) {
      skill = widget.initialSkill!;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.04,
      end: 0.04,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOADING EXPERIENCE
  // --------------------------------------------------------------------------

  void _startLoadingExperience() {
    _messageIndex = 0;
    _messageTimer?.cancel();

    _messageTimer = Timer.periodic(
      const Duration(milliseconds: 2600),
          (_) {
        if (!mounted || !loading) return;

        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      },
    );
  }

  void _stopLoadingExperience() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  // --------------------------------------------------------------------------
  // GENERATE RECIPES
  // --------------------------------------------------------------------------

  Future<void> generateRecipes() async {
    if (loading) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
    });

    _startLoadingExperience();

    final preferences = CookingPreferences(
      time: time,
      budget: budget,
      servings: servings,
      diet: diet,
      avoid: avoid.toList(),
      spiceLevel: spice,
      skill: skill,
    );

    try {
      final List<Recipe> recipes = await RecipeAIService.instance.generateRecipes(
        ingredients: widget.ingredients,
        preferences: preferences,
      );

      if (!mounted) return;

      _stopLoadingExperience();

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

      _stopLoadingExperience();

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('RecipeAIException: ', ''),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: generateRecipes,
            ),
          ),
        );
    }
  }

  // --------------------------------------------------------------------------
  // LEAVE DIALOG
  // --------------------------------------------------------------------------

  Future<bool> _showLeaveGenerationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Stop generating recipes?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          content: const Text(
            'TADKA AI is currently crafting your recipes. If you leave now, progress will be lost.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'KEEP COOKING',
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'LEAVE',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // --------------------------------------------------------------------------
  // CUSTOM CHOICE SELECTOR
  // --------------------------------------------------------------------------

  Widget _buildChoiceSelector(
      List<String> items,
      String selected,
      ValueChanged<String> onChanged,
      ) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(item);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.12),
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : null,
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.onSurface,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (loading) {
          final shouldLeave = await _showLeaveGenerationDialog();

          if (shouldLeave && mounted) {
            _stopLoadingExperience();

            setState(() {
              loading = false;
            });

            Navigator.of(context).pop();
          }
        }
      },
      child: loading
          ? _buildLoadingScreen(context)
          : _buildPreferencesScreen(context),
    );
  }

  // --------------------------------------------------------------------------
  // LOADING SCREEN
  // --------------------------------------------------------------------------

  Widget _buildLoadingScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final colors = theme.colorScheme;

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
                        final shouldLeave = await _showLeaveGenerationDialog();

                        if (shouldLeave && mounted) {
                          _stopLoadingExperience();

                          setState(() {
                            loading = false;
                          });

                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outline.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Creating your recipes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
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

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    children: [
                      // Animated Flame Mascot
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
                                Color.lerp(primary, Colors.black, 0.2) ??
                                    primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.30),
                                blurRadius: 30,
                                spreadRadius: 2,
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
                          letterSpacing: 1.0,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Turning your ingredients into ideas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Animated Loading Message Box
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
                            color: primary.withValues(
                              alpha: isDark ? 0.10 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
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

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ingredients in use:',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.ingredients.take(8).map(
                                (ingredient) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                    colors.outline.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Text(
                                  ingredient,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedDot(
                            controller: _animationController,
                            delay: 0,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          _AnimatedDot(
                            controller: _animationController,
                            delay: 150,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          _AnimatedDot(
                            controller: _animationController,
                            delay: 300,
                            color: primary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Please wait a few seconds...',
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

  // --------------------------------------------------------------------------
  // PREFERENCES FORM SCREEN
  // --------------------------------------------------------------------------

  Widget _buildPreferencesScreen(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final textPrimary = colors.onSurface;
    final textSecondary = colors.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Cooking Preferences',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Progress Indicator Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.outline.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Let’s customize your recipe.',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Tailor the preparation to suit your time, diet, and taste.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // TIME
                    _SectionTitle(
                      icon: Icons.timer_outlined,
                      text: 'How much time do you have?',
                    ),
                    const SizedBox(height: 10),
                    _buildChoiceSelector(times, time, (value) {
                      setState(() => time = value);
                    }),

                    const SizedBox(height: 22),

                    // BUDGET
                    _SectionTitle(
                      icon: Icons.account_balance_wallet_outlined,
                      text: 'What’s your budget?',
                    ),
                    const SizedBox(height: 10),
                    _buildChoiceSelector(budgets, budget, (value) {
                      setState(() => budget = value);
                    }),

                    const SizedBox(height: 22),

                    // SERVINGS COUNTER
                    _SectionTitle(
                      icon: Icons.people_outline_rounded,
                      text: 'How many servings?',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outline.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servings Count',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Portions for your meal',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: IconButton(
                              onPressed: servings > 1
                                  ? () {
                                HapticFeedback.selectionClick();
                                setState(() => servings--);
                              }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline, size: 22),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$servings',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: IconButton(
                              onPressed: servings < 10
                                  ? () {
                                HapticFeedback.selectionClick();
                                setState(() => servings++);
                              }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // DIET
                    _SectionTitle(
                      icon: Icons.restaurant_outlined,
                      text: 'Dietary Preference',
                    ),
                    const SizedBox(height: 10),
                    _buildChoiceSelector(diets, diet, (value) {
                      setState(() => diet = value);
                    }),

                    const SizedBox(height: 22),

                    // AVOID / ALLERGIES
                    _SectionTitle(
                      icon: Icons.remove_circle_outline_rounded,
                      text: 'Anything to avoid?',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'No onion',
                        'No garlic',
                        'Gluten free',
                        'Dairy free',
                      ].map((item) {
                        final selected = avoid.contains(item);

                        return FilterChip(
                          label: Text(item),
                          selected: selected,
                          onSelected: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (value) {
                                avoid.add(item);
                              } else {
                                avoid.remove(item);
                              }
                            });
                          },
                          showCheckmark: false,
                          backgroundColor: colors.surface,
                          selectedColor: colors.primary.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: selected
                                ? colors.primary
                                : colors.outline.withValues(alpha: 0.10),
                          ),
                          labelStyle: TextStyle(
                            color: selected ? colors.primary : textPrimary,
                            fontSize: 12,
                            fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),

                    // SPICE LEVEL
                    _SectionTitle(
                      icon: Icons.local_fire_department_outlined,
                      text: 'Spice Preference',
                    ),
                    const SizedBox(height: 10),
                    _buildChoiceSelector(spices, spice, (value) {
                      setState(() => spice = value);
                    }),

                    const SizedBox(height: 22),

                    // SKILL LEVEL
                    _SectionTitle(
                      icon: Icons.school_outlined,
                      text: 'Cooking Skill Level',
                    ),
                    const SizedBox(height: 10),
                    _buildChoiceSelector(skills, skill, (value) {
                      setState(() => skill = value);
                    }),

                    const SizedBox(height: 24),

                    // AI SUMMARY CARD
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: colors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'TADKA AI will synthesize your chosen ingredients and preferences into personalized recipes.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11.5,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
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

            // Fixed Bottom CTA Container
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outline.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: generateRecipes,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'GENERATE WITH AI',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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
// ANIMATED DOT WIDGET
// ============================================================================

class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final int delay;
  final Color color;

  const _AnimatedDot({
    required this.controller,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value + delay / 1800) % 1.0;
        final opacity = 0.35 + (value < 0.5 ? value : 1 - value);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity.clamp(0.35, 1.0)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ============================================================================
// SECTION TITLE WIDGET
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}