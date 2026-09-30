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
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController controller = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();

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
          (item) => item.toLowerCase() == ingredient.toLowerCase(),
    );

    if (exists) {
      controller.clear();
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

    if (keepKeyboard) {
      inputFocusNode.requestFocus();
    }
  }

  // --------------------------------------------------------------------------
  // ADD FROM QUICK SUGGESTION
  // --------------------------------------------------------------------------

  void addSuggestion(String ingredient) {
    FocusManager.instance.primaryFocus?.unfocus();

    addIngredient(
      ingredient,
      keepKeyboard: false,
    );
  }

  // --------------------------------------------------------------------------
  // REMOVE INGREDIENT
  // --------------------------------------------------------------------------

  void removeIngredient(String ingredient) {
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
        builder: (_) => CookingPreferencesScreen(
          ingredients: List<String>.from(ingredients),
          initialTime: widget.initialTime,
          initialDiet: widget.initialDiet,
          initialSpice: widget.initialSpice,
          initialSkill: widget.initialSkill,
        ),
      ),
    );
  }

  bool containsIngredient(String value) {
    return ingredients.any(
          (ingredient) => ingredient.toLowerCase() == value.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = colors.onSurface;
    final textSecondary = colors.onSurfaceVariant;

    final borderColor = colors.outline.withValues(
      alpha: isDark ? 0.22 : 0.10,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a recipe',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'STEP 1 OF 3',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _StepIndicator(
                        currentStep: 1,
                        totalSteps: 3,
                      ),

                      const SizedBox(height: 28),

                      // ======================================================
                      // HERO
                      // ======================================================
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.kitchen_rounded,
                                  size: 13,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'PANTRY BUILDER',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'What do you have\nin your kitchen?',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Add available pantry ingredients. TADKA AI will construct step-by-step custom meal recipes.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ======================================================
                      // SEARCH INPUT
                      // ======================================================

                      _IngredientInput(
                        controller: controller,
                        focusNode: inputFocusNode,
                        onSubmitted: (value) {
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
                        borderColor: borderColor,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Type any custom ingredient or pick from quick items below.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ======================================================
                      // YOUR INGREDIENTS
                      // ======================================================

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: ingredients.isEmpty
                            ? const SizedBox(key: ValueKey('empty'))
                            : Padding(
                          key: const ValueKey('ingredients'),
                          padding: const EdgeInsets.only(top: 26),
                          child: _AddedIngredientsSection(
                            ingredients: ingredients,
                            textPrimary: textPrimary,
                            primary: colors.primary,
                            onRemove: removeIngredient,
                          ),
                        ),
                      ),

                      SizedBox(height: ingredients.isEmpty ? 28 : 30),

                      // ======================================================
                      // QUICK ADD
                      // ======================================================

                      _SectionTitle(
                        title: 'Quick Add Suggestions',
                        subtitle: 'Tap common staples to add them instantly',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: suggestions.map((item) {
                          final exists = containsIngredient(item);

                          return _IngredientSuggestion(
                            label: item,
                            selected: exists,
                            primary: colors.primary,
                            surface: colors.surface,
                            border: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: exists
                                ? null
                                : () {
                              addSuggestion(item);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // ======================================================
                      // TIP
                      // ======================================================

                      _TipCard(
                        primary: colors.primary,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // =============================================================
              // BOTTOM ACTION
              // =============================================================

              _BottomAction(
                enabled: ingredients.isNotEmpty,
                count: ingredients.length,
                primary: colors.primary,
                onPressed: continueToPreferences,
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

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(
        totalSteps,
            (index) {
          final active = index < currentStep;

          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(
                right: index == totalSteps - 1 ? 0 : 8,
              ),
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? colors.primary
                    : colors.outline.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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

class _IngredientInput extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: false,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        onSubmitted: onSubmitted,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Search or enter an ingredient...',
          hintStyle: TextStyle(
            color: colors.onSurfaceVariant.withValues(alpha: 0.65),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              Icons.search_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary,
                        colors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: colors.primary,
              width: 1.8,
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

class _AddedIngredientsSection extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Your Pantry Items',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ingredients.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Tap chip to remove',
                style: TextStyle(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredients.map((ingredient) {
              return _IngredientChip(
                label: ingredient,
                primary: primary,
                onRemove: () => onRemove(ingredient),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INGREDIENT CHIP
// ============================================================================

class _IngredientChip extends StatelessWidget {
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
      color: primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 11,
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
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ADD SUGGESTION
// ============================================================================

class _IngredientSuggestion extends StatelessWidget {
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
      color: selected ? primary.withValues(alpha: 0.1) : surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 17,
                color: selected ? primary : textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
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

class _TipCard extends StatelessWidget {
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const _TipCard({
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TADKA PRO TIP',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Even with just 2–3 pantry staples, TADKA AI can unlock delicious custom combinations.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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

class _BottomAction extends StatelessWidget {
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
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
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colors.outline.withValues(alpha: 0.12),
            disabledForegroundColor: colors.onSurfaceVariant.withValues(alpha: 0.5),
            elevation: enabled ? 4 : 0,
            shadowColor: primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: enabled
                ? Row(
              key: const ValueKey('enabled'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CONTINUE TO PREFERENCES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                ),
              ],
            )
                : const Text(
              'ADD AN INGREDIENT TO CONTINUE',
              key: ValueKey('disabled'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}