import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ai/recipe_ai_service.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_results_screen.dart';
import 'cooking_preferences.dart';

class CookingPreferencesScreen
    extends StatefulWidget {
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
  State<CookingPreferencesScreen>
  createState() =>
      _CookingPreferencesScreenState();
}

class _CookingPreferencesScreenState
    extends State<CookingPreferencesScreen>
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
  // LOADING
  // --------------------------------------------------------------------------

  bool loading = false;

  Timer? _messageTimer;
  int _messageIndex = 0;

  late final AnimationController
  _animationController;

  late final Animation<double>
  _scaleAnimation;

  late final Animation<double>
  _rotationAnimation;

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

    // Apply Quick Pick values.

    if (widget.initialTime != null &&
        times.contains(widget.initialTime)) {
      time = widget.initialTime!;
    }

    if (widget.initialDiet != null &&
        diets.contains(widget.initialDiet)) {
      diet = widget.initialDiet!;
    }

    if (widget.initialSpice != null &&
        spices.contains(widget.initialSpice)) {
      spice = widget.initialSpice!;
    }

    if (widget.initialSkill != null &&
        skills.contains(widget.initialSkill)) {
      skill = widget.initialSkill!;
    }

    _animationController =
    AnimationController(
      vsync: this,
      duration:
      const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(
          begin: 0.94,
          end: 1.06,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _rotationAnimation =
        Tween<double>(
          begin: -0.055,
          end: 0.055,
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
          _messageIndex =
              (_messageIndex + 1) %
                  _loadingMessages.length;
        });
      },
    );
  }

  void _stopLoadingExperience() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  // --------------------------------------------------------------------------
  // GENERATE
  // --------------------------------------------------------------------------

  Future<void> generateRecipes() async {
    if (loading) return;

    HapticFeedback.mediumImpact();

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
    });

    _startLoadingExperience();

    final preferences =
    CookingPreferences(
      time: time,
      budget: budget,
      servings: servings,
      diet: diet,
      avoid: avoid.toList(),
      spiceLevel: spice,
      skill: skill,
    );

    try {
      final List<Recipe> recipes =
      await RecipeAIService.instance
          .generateRecipes(
        ingredients:
        widget.ingredients,
        preferences: preferences,
      );

      if (!mounted) return;

      _stopLoadingExperience();

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

      _stopLoadingExperience();

      setState(() {
        loading = false;
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
            margin:
            const EdgeInsets.all(16),
            duration:
            const Duration(seconds: 4),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),
            action:
            SnackBarAction(
              label: 'RETRY',
              onPressed:
              generateRecipes,
            ),
          ),
        );
    }
  }

  // --------------------------------------------------------------------------
  // BACK
  // --------------------------------------------------------------------------

  Future<bool> _showLeaveGenerationDialog() async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Stop generating recipes?',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: const Text(
            'TADKA is still working on your '
                'recipes. If you leave now, the '
                'current generation will be discarded.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child:
              const Text('KEEP COOKING'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              child: const Text('LEAVE'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // --------------------------------------------------------------------------
  // SELECTION
  // --------------------------------------------------------------------------

  Widget selection(
      List<String> items,
      String selected,
      ValueChanged<String> onChanged,
      ) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: items.map((item) {
        final isSelected =
            item == selected;

        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            onChanged(item);
          },
          selectedColor:
          const Color(0xFFE85D04),
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context)
                .colorScheme
                .onSurface,
            fontWeight:
            FontWeight.w700,
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
      onPopInvokedWithResult:
          (didPop, result) async {
        if (didPop) return;

        if (loading) {
          final shouldLeave =
          await _showLeaveGenerationDialog();

          if (shouldLeave &&
              mounted) {
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

  Widget _buildLoadingScreen(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final primary =
        theme.colorScheme.primary;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
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
                  Material(
                    color:
                    theme.colorScheme.surface,
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      onTap: () async {
                        final shouldLeave =
                        await _showLeaveGenerationDialog();

                        if (shouldLeave &&
                            mounted) {
                          _stopLoadingExperience();

                          setState(() {
                            loading = false;
                          });

                          Navigator.of(
                            context,
                          ).pop();
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius
                              .circular(
                            14,
                          ),
                          border:
                          Border.all(
                            color: theme
                                .colorScheme
                                .outline
                                .withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .arrow_back_rounded,
                          size: 21,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Text(
                      'Creating your recipes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      primary.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .auto_awesome_rounded,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .w900,
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
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    24,
                    20,
                    24,
                    30,
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation:
                        _animationController,
                        builder:
                            (context, child) {
                          return Transform.rotate(
                            angle:
                            _rotationAnimation
                                .value,
                            child:
                            Transform.scale(
                              scale:
                              _scaleAnimation
                                  .value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 118,
                          height: 118,
                          decoration:
                          BoxDecoration(
                            gradient:
                            const LinearGradient(
                              colors: [
                                Color(
                                  0xFFE85D04,
                                ),
                                Color(
                                  0xFFDC2F02,
                                ),
                              ],
                              begin:
                              Alignment
                                  .topLeft,
                              end:
                              Alignment
                                  .bottomRight,
                            ),
                            shape:
                            BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                primary.withValues(
                                  alpha:
                                  0.28,
                                ),
                                blurRadius:
                                35,
                                spreadRadius:
                                3,
                              ),
                            ],
                          ),
                          child:
                          const Icon(
                            Icons
                                .local_fire_department_rounded,
                            color:
                            Colors.white,
                            size: 57,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      Text(
                        'TADKA AI',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(
                            0xFF211D19,
                          ),
                          fontSize: 27,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        'Turning your ingredients into ideas',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? const Color(
                            0xFF9CA3AF,
                          )
                              : const Color(
                            0xFF77716A,
                          ),
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      AnimatedSwitcher(
                        duration:
                        const Duration(
                          milliseconds: 450,
                        ),
                        child: Container(
                          key: ValueKey(
                            _messageIndex,
                          ),
                          width:
                          double.infinity,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            primary.withValues(
                              alpha:
                              isDark
                                  ? 0.10
                                  : 0.06,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              18,
                            ),
                            border:
                            Border.all(
                              color:
                              primary.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration:
                                BoxDecoration(
                                  color:
                                  primary
                                      .withValues(
                                    alpha:
                                    0.12,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),
                                ),
                                child: Icon(
                                  _loadingIcons[
                                  _messageIndex],
                                  color:
                                  primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Text(
                                  _loadingMessages[
                                  _messageIndex],
                                  style:
                                  TextStyle(
                                    color: isDark
                                        ? Colors
                                        .white
                                        : const Color(
                                      0xFF211D19,
                                    ),
                                    fontSize:
                                    13.5,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          'Working with your ingredients',
                          style: TextStyle(
                            color: isDark
                                ? const Color(
                              0xFFD1D5DB,
                            )
                                : const Color(
                              0xFF5F5851,
                            ),
                            fontSize: 11.5,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: widget
                              .ingredients
                              .take(8)
                              .map(
                                (ingredient) {
                              return Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  10,
                                  vertical: 7,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surface,
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    20,
                                  ),
                                  border:
                                  Border.all(
                                    color: theme
                                        .colorScheme
                                        .outline
                                        .withValues(
                                      alpha:
                                      0.12,
                                    ),
                                  ),
                                ),
                                child:
                                Text(
                                  ingredient,
                                  style:
                                  TextStyle(
                                    color: isDark
                                        ? Colors
                                        .white
                                        : const Color(
                                      0xFF403A35,
                                    ),
                                    fontSize:
                                    10.5,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                  ),
                                ),
                              );
                            },
                          )
                              .toList(),
                        ),
                      ),

                      const SizedBox(
                        height: 27,
                      ),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          _AnimatedDot(
                            controller:
                            _animationController,
                            delay: 0,
                            color: primary,
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          _AnimatedDot(
                            controller:
                            _animationController,
                            delay: 150,
                            color: primary,
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          _AnimatedDot(
                            controller:
                            _animationController,
                            delay: 300,
                            color: primary,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      Text(
                        'Please wait a few seconds',
                        style: TextStyle(
                          color: isDark
                              ? const Color(
                            0xFF6B7280,
                          )
                              : const Color(
                            0xFF9A938C,
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

  // --------------------------------------------------------------------------
  // PREFERENCES SCREEN
  // --------------------------------------------------------------------------

  Widget _buildPreferencesScreen(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final textPrimary =
        colors.onSurface;

    final textSecondary =
        colors.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Cooking preferences',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
              SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Progress
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration:
                            BoxDecoration(
                              color:
                              colors.primary,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration:
                            BoxDecoration(
                              color:
                              colors.primary,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration:
                            BoxDecoration(
                              color: colors
                                  .outline
                                  .withValues(
                                alpha: 0.15,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    Text(
                      'Let’s make it personal.',
                      style: TextStyle(
                        color:
                        textPrimary,
                        fontSize: 29,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Tell TADKA AI what kind of meal '
                          'works for you.',
                      style: TextStyle(
                        color:
                        textSecondary,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // TIME
                    _Title(
                      icon:
                      Icons.timer_outlined,
                      text:
                      'How much time do you have?',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    selection(
                      times,
                      time,
                          (value) {
                        setState(() {
                          time = value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // BUDGET
                    _Title(
                      icon: Icons
                          .account_balance_wallet_outlined,
                      text:
                      'What’s your budget?',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    selection(
                      budgets,
                      budget,
                          (value) {
                        setState(() {
                          budget = value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // SERVINGS
                    _Title(
                      icon: Icons.people_outline,
                      text:
                      'How many people?',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Container(
                      padding:
                      const EdgeInsets.all(
                        14,
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
                        border: Border.all(
                          color: colors
                              .outline
                              .withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Servings',
                              style:
                              TextStyle(
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                            servings > 1
                                ? () {
                              setState(
                                    () {
                                  servings--;
                                },
                              );
                            }
                                : null,
                            icon: const Icon(
                              Icons
                                  .remove_circle_outline,
                            ),
                          ),
                          Text(
                            '$servings',
                            style:
                            const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          IconButton(
                            onPressed:
                            servings < 10
                                ? () {
                              setState(
                                    () {
                                  servings++;
                                },
                              );
                            }
                                : null,
                            icon: const Icon(
                              Icons
                                  .add_circle_outline,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // DIET
                    _Title(
                      icon:
                      Icons.restaurant_outlined,
                      text: 'Diet',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    selection(
                      diets,
                      diet,
                          (value) {
                        setState(() {
                          diet = value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // AVOID
                    _Title(
                      icon: Icons
                          .remove_circle_outline,
                      text:
                      'Anything to avoid?',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        'No onion',
                        'No garlic',
                        'Gluten free',
                        'Dairy free',
                      ].map(
                            (item) {
                          final selected =
                          avoid.contains(
                            item,
                          );

                          return FilterChip(
                            label:
                            Text(item),
                            selected:
                            selected,
                            onSelected:
                                (value) {
                              setState(() {
                                if (value) {
                                  avoid.add(
                                    item,
                                  );
                                } else {
                                  avoid.remove(
                                    item,
                                  );
                                }
                              });
                            },
                            selectedColor:
                            const Color(
                              0xFFFFE1CC,
                            ),
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // SPICE
                    _Title(
                      icon: Icons
                          .local_fire_department_outlined,
                      text:
                      'How spicy?',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    selection(
                      spices,
                      spice,
                          (value) {
                        setState(() {
                          spice = value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // SKILL
                    _Title(
                      icon:
                      Icons.school_outlined,
                      text:
                      'Your cooking skill',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    selection(
                      skills,
                      skill,
                          (value) {
                        setState(() {
                          skill = value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    Container(
                      padding:
                      const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                      BoxDecoration(
                        color: colors
                            .primary
                            .withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          18,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .auto_awesome_rounded,
                            color:
                            colors.primary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'Gemini will use your ingredients '
                                  'and preferences to generate '
                                  'personalized recipes.',
                              style: TextStyle(
                                color:
                                textSecondary,
                                fontSize: 13,
                                height: 1.4,
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

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                18,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                  generateRecipes,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    colors.primary,
                    foregroundColor:
                    Colors.white,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(
                        Icons
                            .auto_awesome_rounded,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'GENERATE WITH AI',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w800,
                          letterSpacing: 0.3,
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
// ANIMATED DOT
// ============================================================================

class _AnimatedDot
    extends StatelessWidget {
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
        final value =
            (controller.value +
                delay / 1800) %
                1.0;

        final opacity = 0.35 +
            (value < 0.5
                ? value
                : 1 - value);

        return Container(
          width: 8,
          height: 8,
          decoration:
          BoxDecoration(
            color: color.withValues(
              alpha:
              opacity.clamp(
                0.35,
                1.0,
              ),
            ),
            shape:
            BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ============================================================================
// TITLE
// ============================================================================

class _Title
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Title({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final primary =
        Theme.of(context)
            .colorScheme
            .primary;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: primary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ],
    );
  }
}