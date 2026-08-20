import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_results_screen.dart';

class StartCookingScreen extends StatefulWidget {
  final Recipe recipe;

  const StartCookingScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<StartCookingScreen> createState() => _StartCookingScreenState();
}

class _StartCookingScreenState extends State<StartCookingScreen> {
  int _currentStep = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerRunning = false;
  bool _stepCompleted = false;

  Recipe get recipe => widget.recipe;

  List<String> get steps =>
      recipe.steps.isEmpty ? ['Your recipe is ready. Enjoy cooking!'] : recipe.steps;

  String get currentInstruction => steps[_currentStep];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();

    if (_currentStep < steps.length - 1) {
      setState(() {
        _currentStep++;
        _stepCompleted = false;
        _stopTimer();
        _remainingSeconds = 0;
      });
    } else {
      _showCompletion();
    }
  }

  void _previousStep() {
    if (_currentStep == 0) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentStep--;
      _stepCompleted = false;
      _stopTimer();
      _remainingSeconds = 0;
    });
  }

  void _toggleStepComplete() {
    HapticFeedback.mediumImpact();

    setState(() {
      _stepCompleted = !_stepCompleted;
    });
  }

  void _startTimer(int seconds) {
    if (seconds <= 0) return;

    _timer?.cancel();

    setState(() {
      _remainingSeconds = seconds;
      _timerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
          _timerRunning = false;
        });

        HapticFeedback.heavyImpact();
        _showTimerFinished();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;

    if (mounted) {
      setState(() {
        _timerRunning = false;
      });
    }
  }

  void _showTimerFinished() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Timer finished',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Your cooking timer has finished. Check your food and continue when ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Continue Cooking',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIngredients() {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.42,
          maxChildSize: 0.88,
          expand: false,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              children: [
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${recipe.ingredients.length} ingredients • ${recipe.servings} servings',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                ...recipe.ingredients.map(
                      (ingredient) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: ingredient.available
                                ? Colors.green.withValues(alpha: 0.10)
                                : colors.error.withValues(alpha: 0.09),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            ingredient.available
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                            size: 18,
                            color: ingredient.available
                                ? Colors.green
                                : colors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          ingredient.quantity,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Restart recipe',
                  subtitle: 'Go back to the first step',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentStep = 0;
                      _stepCompleted = false;
                      _stopTimer();
                      _remainingSeconds = 0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'View ingredients',
                  subtitle: 'Check quantities while cooking',
                  onTap: () {
                    Navigator.pop(context);
                    _showIngredients();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletion() {
    HapticFeedback.heavyImpact();

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return PopScope(
          canPop: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.72),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'You’re done! 🎉',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${recipe.name} is ready to enjoy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Finish Cooking',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = (_currentStep + 1) / steps.length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        titleSpacing: 4,
        leading: IconButton(
          tooltip: 'Exit cooking',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'START COOKING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              recipe.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ingredients',
            onPressed: _showIngredients,
            icon: const Icon(Icons.shopping_basket_outlined),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'STEP ${_currentStep + 1}',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentStep + 1} / ${steps.length}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                    colors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.imageUrl.trim().isNotEmpty)
                    _HeroImage(
                      imageUrl: recipe.imageUrl,
                      name: recipe.name,
                    ),

                  const SizedBox(height: 22),

                  Text(
                    currentInstruction,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 26,
                      height: 1.22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 22),

                  _GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                            colors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TADKA TIP',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.tips.isNotEmpty
                                    ? recipe.tips[
                                _currentStep %
                                    recipe.tips.length]
                                    : 'Keep your ingredients ready and cook at a comfortable pace.',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (recipe.warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _GlassCard(
                      accent: colors.error,
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colors.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recipe.warnings[
                              _currentStep %
                                  recipe.warnings.length],
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  _TimerCard(
                    remainingSeconds: _remainingSeconds,
                    running: _timerRunning,
                    onStart: () => _showTimerPicker(),
                    onStop: _stopTimer,
                  ),

                  const SizedBox(height: 18),

                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _toggleStepComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _stepCompleted
                            ? colors.primary.withValues(alpha: 0.10)
                            : colors.surfaceContainerHighest
                            .withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _stepCompleted
                              ? colors.primary.withValues(alpha: 0.30)
                              : colors.outline.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _stepCompleted
                                  ? colors.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _stepCompleted
                                    ? colors.primary
                                    : colors.onSurfaceVariant
                                    .withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: _stepCompleted
                                ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Mark this step complete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.touch_app_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================================================================
          // BOTTOM COOKING CONTROLS
          // ================================================================

          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(
                  color: colors.outline.withValues(alpha: 0.08),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark
                        ? 0.18
                        : 0.04,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: OutlinedButton(
                      onPressed:
                      _currentStep == 0 ? null : _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _nextStep,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == steps.length - 1
                                  ? 'Finish Cooking'
                                  : 'Next Step',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentStep == steps.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimerPicker() {
    final controller = TextEditingController(text: '5');

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set a cooking timer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how many minutes you need for this step.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Minutes',
                    prefixIcon:
                    const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [1, 3, 5, 10, 15, 20]
                      .map(
                        (minutes) => ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () {
                        controller.text =
                            minutes.toString();
                      },
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      final minutes =
                          int.tryParse(controller.text) ?? 0;

                      if (minutes <= 0) return;

                      Navigator.pop(context);
                      _startTimer(minutes * 60);
                    },
                    child: const Text(
                      'Start Timer',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final String name;

  const _HeroImage({
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 54,
                ),
              ),
              loadingBuilder: (
                  context,
                  child,
                  progress,
                  ) {
                if (progress == null) return child;

                return Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.30),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accent;

  const _GlassCard({
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent?.withValues(alpha: 0.18) ??
              colors.outline.withValues(alpha: 0.09),
        ),
      ),
      child: child,
    );
  }
}

class _TimerCard extends StatelessWidget {
  final int remainingSeconds;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _TimerCard({
    required this.remainingSeconds,
    required this.running,
    required this.onStart,
    required this.onStop,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.10),
            colors.primary.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.timer_rounded,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  running ? 'Timer running' : 'Cooking timer',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remainingSeconds > 0
                      ? _formatTime(remainingSeconds)
                      : 'Need a reminder for this step?',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (running)
            IconButton(
              tooltip: 'Stop timer',
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded),
            )
          else
            FilledButton.tonal(
              onPressed: onStart,
              child: const Text(
                'Set timer',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
