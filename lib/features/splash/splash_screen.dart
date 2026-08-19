import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final AnimationController _particleController;
  late final AnimationController _loaderController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlide;

  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    // ================================================================
    // MAIN ENTRANCE ANIMATION
    // ================================================================

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.0,
        0.38,
        curve: Curves.easeOut,
      ),
    );

    _logoScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.0,
          0.62,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _logoSlide = Tween<double>(
      begin: 18,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.0,
          0.58,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.38,
        0.72,
        curve: Curves.easeOut,
      ),
    );

    _contentSlide = Tween<double>(
      begin: 10,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.38,
          0.78,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ================================================================
    // AMBIENT BACKGROUND MOTION
    // ================================================================

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    // ================================================================
    // FLOATING FOOD / SPICE MOTION
    // ================================================================

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    // ================================================================
    // PAN LOADER
    // ================================================================

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(
      const Duration(milliseconds: 120),
    );

    if (!mounted) return;

    _entranceController.forward();

    await Future.delayed(
      const Duration(milliseconds: 2450),
    );

    if (!mounted) return;

    _openApp();
  }

  void _openApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 550,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) {
          return const MainNavigationScreen();
        },
        transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _particleController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFA),
      body: Stack(
        children: [
          // ============================================================
          // SUBTLE ORANGE + GREEN AMBIENT GLOW
          // ============================================================

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PremiumGlowPainter(
                    progress: _ambientController.value,
                  ),
                );
              },
            ),
          ),

          // ============================================================
          // FLOATING FOOD / SPICE DECORATIONS
          // ============================================================

          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FoodDecorationPainter(
                      progress: _particleController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // LOGO
                        // ==================================================

                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _entranceController,
                            _ambientController,
                          ]),
                          builder: (context, child) {
                            final float =
                                math.sin(
                                  _ambientController.value *
                                      math.pi *
                                      2,
                                ) *
                                    2.0;

                            return Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  _logoSlide.value + float,
                                ),
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: _LogoHero(
                            width: math.min(
                              size.width * 0.80,
                              315,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // TAGLINE
                        // ==================================================

                        AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _contentOpacity.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  _contentSlide.value,
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: const Column(
                            children: [
                              Text(
                                'YOUR PERSONAL AI',
                                style: TextStyle(
                                  color: Color(0xFF73736D),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.6,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'COOKING ASSISTANT',
                                style: TextStyle(
                                  color: Color(0xFF252522),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 34),

                        // ==================================================
                        // PAN LOADER
                        // ==================================================

                        FadeTransition(
                          opacity: _contentOpacity,
                          child: _CookingLoader(
                            controller: _loaderController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================================================
                // FOOTER
                // ==========================================================

                FadeTransition(
                  opacity: _contentOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 22,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF7A00),
                                Color(0xFF4CAF50),
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'MADE FOR EVERY KITCHEN',
                          style: TextStyle(
                            color: Color(0xFF898983),
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.7,
                          ),
                        ),
                      ],
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

// ============================================================================
// LOGO HERO
// ============================================================================

class _LogoHero extends StatelessWidget {
  final double width;

  const _LogoHero({
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft orange/green glow.
          Container(
            width: width * 0.78,
            height: width * 0.42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF8A00).withValues(
                    alpha: 0.12,
                  ),
                  const Color(0xFF4CAF50).withValues(
                    alpha: 0.055,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ==============================================================
          // GLASS LOGO PANEL
          // ==============================================================

          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.58,
                  ),
                  borderRadius:
                  BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.90,
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.035,
                      ),
                      blurRadius: 25,
                      offset: const Offset(
                        0,
                        10,
                      ),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/tadka_text_logo.png',
                  width: width * 0.88,
                  fit: BoxFit.contain,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return const Text(
                      'TADKA AI',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF7A00),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REAL FRYING PAN LOADER
// ============================================================================

class _CookingLoader extends StatelessWidget {
  final AnimationController controller;

  const _CookingLoader({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;

        // Gentle pan rocking.
        final panRotation =
            math.sin(
              progress * math.pi * 2,
            ) *
                0.035;

        // Three independent ingredient movements.
        final ingredientOne =
        math.sin(
          progress * math.pi * 2,
        );

        final ingredientTwo =
        math.sin(
          progress * math.pi * 2 +
              2.1,
        );

        final ingredientThree =
        math.sin(
          progress * math.pi * 2 +
              4.2,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 135,
              height: 68,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // ========================================================
                  // STEAM
                  // ========================================================

                  Positioned(
                    top: 0,
                    left: 51,
                    child: Row(
                      children: [
                        _Steam(
                          progress: progress,
                          phase: 0.0,
                        ),
                        const SizedBox(width: 9),
                        _Steam(
                          progress: progress,
                          phase: 0.33,
                        ),
                        const SizedBox(width: 9),
                        _Steam(
                          progress: progress,
                          phase: 0.66,
                        ),
                      ],
                    ),
                  ),

                  // ========================================================
                  // BOUNCING INGREDIENTS
                  // ========================================================

                  Positioned(
                    bottom:
                    24 +
                        (ingredientOne.clamp(0.0, 1.0) *
                            10),
                    left: 51,
                    child: const _FoodPiece(
                      type: 0,
                      size: 7,
                    ),
                  ),

                  Positioned(
                    bottom:
                    25 +
                        (ingredientTwo.clamp(0.0, 1.0) *
                            8),
                    left: 67,
                    child: const _FoodPiece(
                      type: 1,
                      size: 6,
                    ),
                  ),

                  Positioned(
                    bottom:
                    24 +
                        (ingredientThree.clamp(0.0, 1.0) *
                            9),
                    left: 82,
                    child: const _FoodPiece(
                      type: 2,
                      size: 6,
                    ),
                  ),

                  // ========================================================
                  // PAN + HANDLE
                  // ========================================================

                  Positioned(
                    bottom: 6,
                    left: 27,
                    child: Transform.rotate(
                      angle: panRotation,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                          // Pan body.
                          Container(
                            width: 70,
                            height: 23,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF282824,
                              ),
                              borderRadius:
                              const BorderRadius.only(
                                topLeft:
                                Radius.circular(19),
                                topRight:
                                Radius.circular(19),
                                bottomLeft:
                                Radius.circular(25),
                                bottomRight:
                                Radius.circular(25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                    alpha: 0.14,
                                  ),
                                  blurRadius: 9,
                                  offset:
                                  const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 55,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF44443F,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    20,
                                  ),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(
                                      alpha: 0.07,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 3),

                          // Pan handle.
                          Container(
                            width: 30,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF282824,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ========================================================
                  // SUBTLE HEAT GLOW
                  // ========================================================

                  Positioned(
                    bottom: 1,
                    left: 44,
                    child: Opacity(
                      opacity:
                      0.16 +
                          ((math.sin(
                            progress *
                                math.pi *
                                2,
                          ) +
                              1) /
                              2) *
                              0.12,
                      child: Container(
                        width: 53,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF7A00,
                              ),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'COOKING UP SOMETHING DELICIOUS',
              style: TextStyle(
                color: Color(0xFF85857F),
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// STEAM
// ============================================================================

class _Steam extends StatelessWidget {
  final double progress;
  final double phase;

  const _Steam({
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final value =
        (progress + phase) % 1.0;

    final opacity =
    math.sin(value * math.pi);

    return Transform.translate(
      offset: Offset(
        math.sin(
          value * math.pi * 2,
        ) *
            3,
        -value * 6,
      ),
      child: Opacity(
        opacity: opacity.clamp(
          0.0,
          0.7,
        ),
        child: Container(
          width: 3,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(
              0xFFB3B3AD,
            ),
            borderRadius:
            BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FOOD PIECE
// ============================================================================

class _FoodPiece extends StatelessWidget {
  final int type;
  final double size;

  const _FoodPiece({
    required this.type,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFE53935), // Tomato
      const Color(0xFFFFB300), // Spice
      const Color(0xFF4CAF50), // Herb
    ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[type],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors[type].withValues(
              alpha: 0.25,
            ),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PREMIUM AMBIENT GLOW
// ============================================================================

class _PremiumGlowPainter
    extends CustomPainter {
  final double progress;

  _PremiumGlowPainter({
    required this.progress,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final movement =
        math.sin(
          progress * math.pi * 2,
        ) *
            25;

    final orangePaint = Paint()
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        70,
      )
      ..color = const Color(
        0xFFFF7A00,
      ).withValues(
        alpha: 0.075,
      );

    final greenPaint = Paint()
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        75,
      )
      ..color = const Color(
        0xFF4CAF50,
      ).withValues(
        alpha: 0.055,
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.08 + movement,
        size.height * 0.18,
      ),
      115,
      orangePaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.92 - movement,
        size.height * 0.78,
      ),
      130,
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _PremiumGlowPainter oldDelegate,
      ) {
    return oldDelegate.progress !=
        progress;
  }
}

// ============================================================================
// FLOATING FOOD / SPICE DECORATIONS
// ============================================================================

class _FoodDecorationPainter
    extends CustomPainter {
  final double progress;

  _FoodDecorationPainter({
    required this.progress,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final items = [
      const _FoodItem(
        x: 0.10,
        y: 0.18,
        type: 0,
        size: 25,
        phase: 0.0,
      ),
      const _FoodItem(
        x: 0.89,
        y: 0.22,
        type: 1,
        size: 23,
        phase: 0.23,
      ),
      const _FoodItem(
        x: 0.07,
        y: 0.70,
        type: 2,
        size: 23,
        phase: 0.47,
      ),
      const _FoodItem(
        x: 0.93,
        y: 0.67,
        type: 3,
        size: 27,
        phase: 0.68,
      ),
      const _FoodItem(
        x: 0.17,
        y: 0.46,
        type: 4,
        size: 10,
        phase: 0.82,
      ),
      const _FoodItem(
        x: 0.84,
        y: 0.49,
        type: 5,
        size: 11,
        phase: 0.36,
      ),
    ];

    for (final item in items) {
      final wave =
          math.sin(
            (progress + item.phase) *
                math.pi *
                2,
          ) *
              7;

      final rotation =
          math.sin(
            (progress + item.phase) *
                math.pi *
                2,
          ) *
              0.10;

      canvas.save();

      canvas.translate(
        size.width * item.x,
        size.height * item.y + wave,
      );

      canvas.rotate(rotation);

      _drawFood(
        canvas,
        item,
      );

      canvas.restore();
    }
  }

  void _drawFood(
      Canvas canvas,
      _FoodItem item,
      ) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final opacity =
        0.22 +
            ((math.sin(
              (progress + item.phase) *
                  math.pi *
                  2,
            ) +
                1) /
                2) *
                0.12;

    // ==============================================================
    // CHILLI
    // ==============================================================

    if (item.type == 0) {
      paint.color =
          const Color(
            0xFFE53935,
          ).withValues(
            alpha: opacity,
          );

      final path = Path();

      path.moveTo(
        -item.size * 0.5,
        0,
      );

      path.quadraticBezierTo(
        0,
        -item.size * 0.55,
        item.size * 0.52,
        -item.size * 0.03,
      );

      path.quadraticBezierTo(
        0,
        item.size * 0.45,
        -item.size * 0.5,
        0,
      );

      canvas.drawPath(
        path,
        paint,
      );

      paint.color =
          const Color(
            0xFF4CAF50,
          ).withValues(
            alpha: opacity,
          );

      canvas.drawCircle(
        Offset(
          -item.size * 0.25,
          -item.size * 0.28,
        ),
        item.size * 0.12,
        paint,
      );
    }

    // ==============================================================
    // TOMATO
    // ==============================================================

    else if (item.type == 1) {
      paint.color =
          const Color(
            0xFFE9543D,
          ).withValues(
            alpha: opacity,
          );

      canvas.drawCircle(
        Offset.zero,
        item.size * 0.40,
        paint,
      );

      paint.color =
          const Color(
            0xFF4CAF50,
          ).withValues(
            alpha: opacity,
          );

      final leaf = Path();

      leaf.moveTo(
        0,
        -item.size * 0.30,
      );

      leaf.lineTo(
        item.size * 0.16,
        -item.size * 0.52,
      );

      leaf.lineTo(
        item.size * 0.32,
        -item.size * 0.35,
      );

      leaf.lineTo(
        0,
        -item.size * 0.22,
      );

      leaf.close();

      canvas.drawPath(
        leaf,
        paint,
      );
    }

    // ==============================================================
    // LEMON
    // ==============================================================

    else if (item.type == 2) {
      paint.color =
          const Color(
            0xFFFFC107,
          ).withValues(
            alpha: opacity,
          );

      canvas.drawCircle(
        Offset.zero,
        item.size * 0.40,
        paint,
      );

      paint.color =
          Colors.white.withValues(
            alpha: opacity * 0.55,
          );

      canvas.drawCircle(
        Offset.zero,
        item.size * 0.16,
        paint,
      );
    }

    // ==============================================================
    // LEAF
    // ==============================================================

    else if (item.type == 3) {
      paint.color =
          const Color(
            0xFF4CAF50,
          ).withValues(
            alpha: opacity,
          );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: item.size * 0.75,
          height: item.size * 0.38,
        ),
        paint,
      );

      canvas.save();

      canvas.rotate(
        math.pi / 3,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: item.size * 0.70,
          height: item.size * 0.35,
        ),
        paint,
      );

      canvas.restore();
    }

    // ==============================================================
    // SPICE PARTICLES
    // ==============================================================

    else {
      paint.color =
          (item.type == 4
              ? const Color(
            0xFFFFB300,
          )
              : const Color(
            0xFFFF7A00,
          ))
              .withValues(
            alpha: opacity,
          );

      canvas.drawCircle(
        Offset.zero,
        item.size * 0.32,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _FoodDecorationPainter oldDelegate,
      ) {
    return oldDelegate.progress !=
        progress;
  }
}

// ============================================================================
// FOOD ITEM MODEL
// ============================================================================

class _FoodItem {
  final double x;
  final double y;
  final int type;
  final double size;
  final double phase;

  const _FoodItem({
    required this.x,
    required this.y,
    required this.type,
    required this.size,
    required this.phase,
  });
}