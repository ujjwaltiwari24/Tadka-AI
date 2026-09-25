import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../preferences/cooking_preferences_screen.dart';

class IngredientsScreen extends StatefulWidget {
  final String? initialTime;
  final String? initialDiet;
  final String? initialSpice;
  final String? initialSkill;

  const IngredientsScreen({
    super.key,
    this.initialTime,
    this.initialDiet,
    this.initialSpice,
    this.initialSkill,
  });

  @override
  State<IngredientsScreen> createState() =>
      _IngredientsScreenState();
}

class _IngredientsScreenState
    extends State<IngredientsScreen> {
  final TextEditingController controller =
  TextEditingController();

  final FocusNode inputFocusNode =
  FocusNode();

  final List<String> ingredients = [];

  final List<String> suggestions = [
    'Potato',
    'Tomato',
    'Paneer',
    'Rice',
    'Onion',
    'Capsicum',
    'Carrot',
    'Peas',
  ];

  @override
  void initState() {
    super.initState();

    // Make absolutely sure the field doesn't
    // automatically open the keyboard when
    // this screen first appears.
    inputFocusNode.addListener(() {
      if (!inputFocusNode.hasFocus) {
        return;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // ADD INGREDIENT
  // --------------------------------------------------------------------------

  void addIngredient(
      String value, {
        bool keepKeyboard = false,
      }) {
    final ingredient = value.trim();

    if (ingredient.isEmpty) {
      if (keepKeyboard) {
        inputFocusNode.requestFocus();
      }
      return;
    }

    final exists = ingredients.any(
          (item) =>
      item.toLowerCase() ==
          ingredient.toLowerCase(),
    );

    if (exists) {
      controller.clear();

      // Only restore focus if the user was
      // already intentionally typing.
      if (keepKeyboard) {
        inputFocusNode.requestFocus();
      }

      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      ingredients.add(ingredient);
    });

    controller.clear();

    // IMPORTANT:
    //
    // We DO NOT request focus here by default.
    //
    // This prevents the keyboard from popping up
    // when the user selects Quick Add ingredients.
    //
    // If the user is manually typing and presses
    // the keyboard's "done" button, the keyboard
    // behavior is still controlled naturally by
    // Flutter.
    if (keepKeyboard) {
      inputFocusNode.requestFocus();
    }
  }

  // --------------------------------------------------------------------------
  // ADD FROM QUICK SUGGESTION
  // --------------------------------------------------------------------------

  void addSuggestion(String ingredient) {
    // Explicitly dismiss keyboard before adding
    // a quick suggestion.
    //
    // This guarantees that selecting:
    //
    // Potato → Tomato → Paneer
    //
    // will NOT keep reopening the keyboard.
    FocusManager.instance.primaryFocus?.unfocus();

    addIngredient(
      ingredient,
      keepKeyboard: false,
    );
  }

  // --------------------------------------------------------------------------
  // REMOVE INGREDIENT
  // --------------------------------------------------------------------------

  void removeIngredient(
      String ingredient,
      ) {
    HapticFeedback.selectionClick();

    setState(() {
      ingredients.remove(ingredient);
    });
  }

  // --------------------------------------------------------------------------
  // CONTINUE
  // --------------------------------------------------------------------------

  void continueToPreferences() {
    if (ingredients.isEmpty) return;

    HapticFeedback.mediumImpact();

    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CookingPreferencesScreen(
              ingredients:
              List<String>.from(
                ingredients,
              ),
              initialTime:
              widget.initialTime,
              initialDiet:
              widget.initialDiet,
              initialSpice:
              widget.initialSpice,
              initialSkill:
              widget.initialSkill,
            ),
      ),
    );
  }

  bool containsIngredient(
      String value,
      ) {
    return ingredients.any(
          (ingredient) =>
      ingredient.toLowerCase() ==
          value.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final textPrimary =
        colors.onSurface;

    final textSecondary =
        colors.onSurfaceVariant;

    final borderColor =
    colors.outline.withValues(
      alpha:
      isDark ? 0.30 : 0.16,
    );

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,

      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
        theme.scaffoldBackgroundColor,
        surfaceTintColor:
        Colors.transparent,

        leading: Padding(
          padding:
          const EdgeInsets.only(
            left: 12,
          ),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () {
              HapticFeedback
                  .selectionClick();

              FocusManager.instance
                  .primaryFocus
                  ?.unfocus();

              Navigator.pop(context);
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration:
              BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: const Icon(
                Icons
                    .arrow_back_rounded,
                size: 20,
              ),
            ),
          ),
        ),

        titleSpacing: 8,

        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Create a recipe',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight:
                FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Step 1 of 3',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      body: GestureDetector(
        behavior:
        HitTestBehavior.translucent,

        onTap: () {
          FocusManager.instance
              .primaryFocus
              ?.unfocus();
        },

        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child:
                SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,

                  physics:
                  const BouncingScrollPhysics(),

                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const _StepIndicator(
                        currentStep: 1,
                        totalSteps: 3,
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      // ======================================================
                      // HERO
                      // ======================================================

                      Text(
                        'What do you have?',
                        style: TextStyle(
                          color:
                          textPrimary,
                          fontSize: 31,
                          height: 1.05,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing:
                          -1.1,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        'Add the ingredients available '
                            'in your kitchen. TADKA will turn '
                            'them into recipe ideas.',
                        style: TextStyle(
                          color:
                          textSecondary,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ======================================================
                      // SEARCH INPUT
                      // ======================================================

                      _IngredientInput(
                        controller:
                        controller,
                        focusNode:
                        inputFocusNode,
                        onSubmitted:
                            (value) {
                          addIngredient(
                            value,
                            keepKeyboard: true,
                          );
                        },
                        onAdd: () {
                          addIngredient(
                            controller.text,
                            keepKeyboard: true,
                          );
                        },
                        borderColor:
                        borderColor,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [
                          Icon(
                            Icons
                                .auto_awesome_rounded,
                            size: 14,
                            color:
                            colors.primary,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Expanded(
                            child: Text(
                              'Tap the search bar to start '
                                  'adding ingredients.',
                              style: TextStyle(
                                color:
                                textSecondary,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ======================================================
                      // YOUR INGREDIENTS
                      // ======================================================

                      AnimatedSwitcher(
                        duration:
                        const Duration(
                          milliseconds: 250,
                        ),

                        child:
                        ingredients.isEmpty
                            ? const SizedBox(
                          key: ValueKey(
                            'empty',
                          ),
                        )
                            : Padding(
                          key:
                          const ValueKey(
                            'ingredients',
                          ),
                          padding:
                          const EdgeInsets
                              .only(
                            top: 28,
                          ),
                          child:
                          _AddedIngredientsSection(
                            ingredients:
                            ingredients,
                            textPrimary:
                            textPrimary,
                            primary:
                            colors.primary,
                            onRemove:
                            removeIngredient,
                          ),
                        ),
                      ),

                      SizedBox(
                        height:
                        ingredients.isEmpty
                            ? 30
                            : 32,
                      ),

                      // ======================================================
                      // QUICK ADD
                      // ======================================================

                      _SectionTitle(
                        title:
                        'Quick add',
                        subtitle:
                        'Common ingredients you can add instantly',
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children:
                        suggestions
                            .map(
                              (item) {
                            final exists =
                            containsIngredient(
                              item,
                            );

                            return _IngredientSuggestion(
                              label: item,
                              selected:
                              exists,
                              primary:
                              colors.primary,
                              surface:
                              colors.surface,
                              border:
                              borderColor,
                              textPrimary:
                              textPrimary,
                              textSecondary:
                              textSecondary,
                              onTap:
                              exists
                                  ? null
                                  : () {
                                addSuggestion(
                                  item,
                                );
                              },
                            );
                          },
                        ).toList(),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // ======================================================
                      // TIP
                      // ======================================================

                      _TipCard(
                        primary:
                        colors.primary,
                        textPrimary:
                        textPrimary,
                        textSecondary:
                        textSecondary,
                      ),

                      const SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // =============================================================
              // BOTTOM ACTION
              // =============================================================

              _BottomAction(
                enabled:
                ingredients.isNotEmpty,
                count:
                ingredients.length,
                primary:
                colors.primary,
                onPressed:
                continueToPreferences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STEP INDICATOR
// ============================================================================

class _StepIndicator
    extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Row(
      children: List.generate(
        totalSteps,
            (index) {
          final active =
              index < currentStep;

          return Expanded(
            child:
            AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 250,
              ),

              margin:
              EdgeInsets.only(
                right:
                index ==
                    totalSteps -
                        1
                    ? 0
                    : 7,
              ),

              height: 5,

              decoration:
              BoxDecoration(
                color: active
                    ? colors.primary
                    : colors.outline
                    .withValues(
                  alpha: 0.14,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  20,
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
// INGREDIENT INPUT
// ============================================================================

class _IngredientInput
    extends StatelessWidget {
  final TextEditingController
  controller;

  final FocusNode focusNode;

  final ValueChanged<String>
  onSubmitted;

  final VoidCallback onAdd;

  final Color borderColor;

  const _IngredientInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onAdd,
    required this.borderColor,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Container(
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          19,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow
                .withValues(
              alpha: 0.05,
            ),
            blurRadius: 18,
            offset:
            const Offset(0, 6),
          ),
        ],
      ),

      child: TextField(
        controller:
        controller,

        focusNode:
        focusNode,

        // IMPORTANT:
        // The keyboard ONLY opens when
        // the user taps this field.
        autofocus: false,

        textInputAction:
        TextInputAction.done,

        textCapitalization:
        TextCapitalization.words,

        onSubmitted:
        onSubmitted,

        style: TextStyle(
          color:
          colors.onSurface,
          fontSize: 14,
          fontWeight:
          FontWeight.w600,
        ),

        decoration:
        InputDecoration(
          hintText:
          'Search or type an ingredient...',

          hintStyle:
          TextStyle(
            color: colors
                .onSurfaceVariant
                .withValues(
              alpha: 0.70,
            ),
            fontSize: 13,
            fontWeight:
            FontWeight.w500,
          ),

          prefixIcon:
          Padding(
            padding:
            const EdgeInsets.only(
              left: 15,
              right: 8,
            ),
            child: Icon(
              Icons
                  .search_rounded,
              color: colors
                  .onSurfaceVariant,
              size: 22,
            ),
          ),

          prefixIconConstraints:
          const BoxConstraints(
            minWidth: 45,
          ),

          suffixIcon:
          Padding(
            padding:
            const EdgeInsets.only(
              right: 7,
            ),
            child:
            IconButton(
              tooltip:
              'Add ingredient',

              onPressed:
              onAdd,

              icon:
              Container(
                width: 38,
                height: 38,

                decoration:
                BoxDecoration(
                  color:
                  colors.primary,
                  shape:
                  BoxShape.circle,
                ),

                child:
                const Icon(
                  Icons
                      .add_rounded,
                  color:
                  Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          filled: true,

          fillColor:
          colors.surface,

          contentPadding:
          const EdgeInsets
              .symmetric(
            horizontal: 14,
            vertical: 17,
          ),

          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              19,
            ),
            borderSide:
            BorderSide(
              color:
              borderColor,
            ),
          ),

          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              19,
            ),
            borderSide:
            BorderSide(
              color:
              borderColor,
            ),
          ),

          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              19,
            ),
            borderSide:
            BorderSide(
              color:
              colors.primary,
              width: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADDED INGREDIENTS
// ============================================================================

class _AddedIngredientsSection
    extends StatelessWidget {
  final List<String> ingredients;
  final Color textPrimary;
  final Color primary;
  final ValueChanged<String>
  onRemove;

  const _AddedIngredientsSection({
    required this.ingredients,
    required this.textPrimary,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Your ingredients',
                    style:
                    TextStyle(
                      color:
                      textPrimary,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing:
                      -0.2,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      primary.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),
                    ),
                    child:
                    Text(
                      '${ingredients.length}',
                      style:
                      TextStyle(
                        color:
                        primary,
                        fontSize:
                        10,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'Tap to remove',
              style:
              TextStyle(
                color: colors
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.65,
                ),
                fontSize: 10,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
          ingredients.map(
                (ingredient) {
              return _IngredientChip(
                label:
                ingredient,
                primary:
                primary,
                onRemove:
                    () {
                  onRemove(
                    ingredient,
                  );
                },
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// INGREDIENT CHIP
// ============================================================================

class _IngredientChip
    extends StatelessWidget {
  final String label;
  final Color primary;
  final VoidCallback onRemove;

  const _IngredientChip({
    required this.label,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
      primary.withValues(
        alpha: 0.09,
      ),

      borderRadius:
      BorderRadius.circular(
        14,
      ),

      child: InkWell(
        onTap:
        onRemove,

        borderRadius:
        BorderRadius.circular(
          14,
        ),

        child: Container(
          padding:
          const EdgeInsets
              .fromLTRB(
            11,
            9,
            8,
            9,
          ),

          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              14,
            ),

            border:
            Border.all(
              color:
              primary.withValues(
                alpha: 0.16,
              ),
            ),
          ),

          child: Row(
            mainAxisSize:
            MainAxisSize.min,

            children: [
              Container(
                width: 21,
                height: 21,

                decoration:
                BoxDecoration(
                  color:
                  primary.withValues(
                    alpha: 0.14,
                  ),
                  shape:
                  BoxShape.circle,
                ),

                child:
                Icon(
                  Icons
                      .check_rounded,
                  color:
                  primary,
                  size: 14,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                label,
                style:
                TextStyle(
                  color:
                  primary,
                  fontSize:
                  12.5,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              Icon(
                Icons
                    .close_rounded,
                color: colors
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.65,
                ),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
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
            fontSize: 16,
            fontWeight:
            FontWeight.w900,
            letterSpacing:
            -0.2,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,
          style:
          TextStyle(
            color:
            textSecondary,
            fontSize: 11,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ADD SUGGESTION
// ============================================================================

class _IngredientSuggestion
    extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;

  const _IngredientSuggestion({
    required this.label,
    required this.selected,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: selected
          ? primary.withValues(
        alpha: 0.08,
      )
          : surface,

      borderRadius:
      BorderRadius.circular(
        14,
      ),

      child: InkWell(
        onTap:
        onTap,

        borderRadius:
        BorderRadius.circular(
          14,
        ),

        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),

          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 13,
            vertical: 10,
          ),

          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              14,
            ),

            border:
            Border.all(
              color: selected
                  ? primary.withValues(
                alpha: 0.30,
              )
                  : border,
            ),
          ),

          child: Row(
            mainAxisSize:
            MainAxisSize.min,

            children: [
              AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds: 180,
                ),

                child:
                Icon(
                  selected
                      ? Icons
                      .check_circle_rounded
                      : Icons
                      .add_circle_outline_rounded,

                  key:
                  ValueKey(
                    selected,
                  ),

                  size: 17,

                  color: selected
                      ? primary
                      : textSecondary,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                label,
                style:
                TextStyle(
                  color: selected
                      ? primary
                      : textPrimary,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w700,
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
// TIP CARD
// ============================================================================

class _TipCard
    extends StatelessWidget {
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const _TipCard({
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(
        15,
      ),

      decoration:
      BoxDecoration(
        color:
        primary.withValues(
          alpha: 0.065,
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

      child: Row(
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
                alpha: 0.12,
              ),
              shape:
              BoxShape.circle,
            ),

            child:
            Icon(
              Icons
                  .auto_awesome_rounded,
              color:
              primary,
              size: 18,
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
                  'TADKA tip',
                  style:
                  TextStyle(
                    color:
                    textPrimary,
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
                  'Don’t worry if you only have a few '
                      'ingredients. TADKA can still find '
                      'something useful to make.',
                  style:
                  TextStyle(
                    color:
                    textSecondary,
                    fontSize:
                    11,
                    height:
                    1.45,
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
  }
}

// ============================================================================
// BOTTOM ACTION
// ============================================================================

class _BottomAction
    extends StatelessWidget {
  final bool enabled;
  final int count;
  final Color primary;
  final VoidCallback onPressed;

  const _BottomAction({
    required this.enabled,
    required this.count,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        18,
      ),

      decoration:
      BoxDecoration(
        color:
        theme.scaffoldBackgroundColor,

        border:
        Border(
          top:
          BorderSide(
            color: colors
                .outline
                .withValues(
              alpha: 0.08,
            ),
          ),
        ),
      ),

      child: SizedBox(
        width: double.infinity,
        height: 56,

        child:
        ElevatedButton(
          onPressed:
          enabled
              ? onPressed
              : null,

          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            primary,

            foregroundColor:
            Colors.white,

            disabledBackgroundColor:
            colors.outline
                .withValues(
              alpha: 0.13,
            ),

            disabledForegroundColor:
            colors
                .onSurfaceVariant
                .withValues(
              alpha: 0.65,
            ),

            elevation:
            enabled ? 2 : 0,

            shadowColor:
            primary.withValues(
              alpha: 0.25,
            ),

            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                17,
              ),
            ),
          ),

          child:
          AnimatedSwitcher(
            duration:
            const Duration(
              milliseconds: 180,
            ),

            child:
            enabled
                ? Row(
              key:
              const ValueKey(
                'enabled',
              ),

              mainAxisAlignment:
              MainAxisAlignment
                  .center,

              children: [
                const Text(
                  'CONTINUE',
                  style:
                  TextStyle(
                    fontSize:
                    13,
                    fontWeight:
                    FontWeight
                        .w900,
                    letterSpacing:
                    0.4,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal:
                    7,
                    vertical:
                    3,
                  ),

                  decoration:
                  BoxDecoration(
                    color: Colors
                        .white
                        .withValues(
                      alpha:
                      0.18,
                    ),

                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),

                  child:
                  Text(
                    '$count',
                    style:
                    const TextStyle(
                      fontSize:
                      11,
                      fontWeight:
                      FontWeight
                          .w900,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                const Icon(
                  Icons
                      .arrow_forward_rounded,
                  size: 19,
                ),
              ],
            )
                : const Text(
              'ADD AN INGREDIENT TO CONTINUE',
              key:
              ValueKey(
                'disabled',
              ),
              style:
              TextStyle(
                fontSize:
                11,
                fontWeight:
                FontWeight
                    .w800,
                letterSpacing:
                0.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}