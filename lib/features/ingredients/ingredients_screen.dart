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
  void dispose() {
    controller.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  void addIngredient(String value) {
    final ingredient = value.trim();

    if (ingredient.isEmpty) {
      inputFocusNode.requestFocus();
      return;
    }

    final exists = ingredients.any(
          (item) =>
      item.toLowerCase() ==
          ingredient.toLowerCase(),
    );

    if (exists) {
      controller.clear();
      inputFocusNode.requestFocus();
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      ingredients.add(ingredient);
    });

    controller.clear();
    inputFocusNode.requestFocus();
  }

  void removeIngredient(String ingredient) {
    HapticFeedback.selectionClick();

    setState(() {
      ingredients.remove(ingredient);
    });
  }

  void continueToPreferences() {
    if (ingredients.isEmpty) return;

    HapticFeedback.mediumImpact();

    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CookingPreferencesScreen(
              ingredients:
              List<String>.from(ingredients),
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

  bool containsIngredient(String value) {
    return ingredients.any(
          (ingredient) =>
      ingredient.toLowerCase() ==
          value.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final textPrimary = colors.onSurface;
    final textSecondary =
        colors.onSurfaceVariant;

    final borderColor =
    colors.outline.withValues(
      alpha: theme.brightness ==
          Brightness.dark
          ? 0.35
          : 0.18,
    );

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
          'Ingredients',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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

                    const SizedBox(height: 28),

                    Text(
                      'What do you have?',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 30,
                        height: 1.08,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      'Tell us what is available in '
                          'your kitchen. TADKA will build '
                          'recipes around it.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _IngredientInput(
                      controller: controller,
                      focusNode:
                      inputFocusNode,
                      onSubmitted:
                      addIngredient,
                      onAdd: () => addIngredient(
                        controller.text,
                      ),
                      borderColor:
                      borderColor,
                    ),

                    const SizedBox(height: 26),

                    if (ingredients.isNotEmpty)
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

                    if (ingredients.isNotEmpty)
                      const SizedBox(height: 28),

                    _SectionTitle(
                      title: 'Quick add',
                      subtitle:
                      'Tap an ingredient to add it',
                      textPrimary:
                      textPrimary,
                      textSecondary:
                      textSecondary,
                    ),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children:
                      suggestions.map(
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
                            onTap: exists
                                ? null
                                : () =>
                                addIngredient(
                                  item,
                                ),
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(height: 30),

                    _TipCard(
                      primary:
                      colors.primary,
                      textSecondary:
                      textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            _BottomAction(
              enabled:
              ingredients.isNotEmpty,
              count: ingredients.length,
              primary: colors.primary,
              onPressed:
              continueToPreferences,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STEP INDICATOR
// ============================================================================

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: List.generate(
        totalSteps,
            (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index ==
                    totalSteps - 1
                    ? 0
                    : 6,
              ),
              height: 4,
              decoration: BoxDecoration(
                color: index < currentStep
                    ? colors.primary
                    : colors.outline
                    .withValues(
                  alpha: 0.15,
                ),
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// INPUT
// ============================================================================

class _IngredientInput
    extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
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
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction:
      TextInputAction.done,
      textCapitalization:
      TextCapitalization.words,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText:
        'e.g. Potato, paneer, rice...',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        suffixIcon: IconButton(
          tooltip: 'Add ingredient',
          onPressed: onAdd,
          icon: Icon(
            Icons.add_circle_rounded,
            color: colors.primary,
            size: 27,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide:
          BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide:
          BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.7,
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
  final ValueChanged<String> onRemove;

  const _AddedIngredientsSection({
    required this.ingredients,
    required this.textPrimary,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your ingredients',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight:
                FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color:
                primary.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Text(
                '${ingredients.length}',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ingredients.map(
                (ingredient) {
              return _IngredientChip(
                label: ingredient,
                primary: primary,
                onRemove: () =>
                    onRemove(ingredient),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// CHIP
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
  Widget build(BuildContext context) {
    return Material(
      color:
      primary.withValues(alpha: 0.10),
      borderRadius:
      BorderRadius.circular(13),
      child: InkWell(
        onTap: onRemove,
        borderRadius:
        BorderRadius.circular(13),
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            11,
            9,
            8,
            9,
          ),
          child: Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.check_rounded,
                color: primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.close_rounded,
                color:
                primary.withValues(
                  alpha: 0.7,
                ),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight:
            FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
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
// SUGGESTION
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
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.09)
          : surface,
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(14),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary.withValues(
                alpha: 0.4,
              )
                  : border,
            ),
          ),
          child: Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_rounded
                    : Icons.add_rounded,
                size: 16,
                color: selected
                    ? primary
                    : textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
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
// TIP
// ============================================================================

class _TipCard
    extends StatelessWidget {
  final Color primary;
  final Color textSecondary;

  const _TipCard({
    required this.primary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
        primary.withValues(alpha: 0.06),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add whatever you have. Even a few '
                  'ingredients can be enough for TADKA '
                  'to find something useful.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                height: 1.45,
                fontWeight:
                FontWeight.w500,
              ),
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
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        18,
      ),
      decoration: BoxDecoration(
        color:
        theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme
                .colorScheme
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
        child: ElevatedButton(
          onPressed:
          enabled ? onPressed : null,
          style:
          ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor:
            Colors.white,
            disabledBackgroundColor:
            theme
                .colorScheme
                .outline
                .withValues(
              alpha: 0.14,
            ),
            elevation: 0,
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(17),
            ),
          ),
          child: enabled
              ? Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Text(
                'CONTINUE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style:
                const TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 19,
              ),
            ],
          )
              : const Text(
            'ADD AN INGREDIENT TO CONTINUE',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}