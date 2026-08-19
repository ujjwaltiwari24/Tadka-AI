import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final bool fromSave;

  const AuthScreen({
    super.key,
    this.fromSave = false,
  });

  @override
  State<AuthScreen> createState() =>
      _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;

  // ==========================================================================
  // GOOGLE SIGN IN
  // ==========================================================================

  Future<void> _signInWithGoogle() async {
    if (_loading) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _loading = true;
    });

    try {
      final credential =
      await AuthService.instance.signInWithGoogle();

      if (!mounted) return;

      if (credential?.user != null) {
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Welcome to TADKA AI! 👨‍🍳',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

        Navigator.pop(
          context,
          true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'GOOGLE SIGN-IN ERROR: $error',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      if (!mounted) return;

      final errorText =
      error.toString().toLowerCase();

      String message =
          'Something went wrong. Please try again.';

      if (errorText.contains('cancel')) {
        message = 'Sign-in was cancelled.';
      } else if (errorText.contains('network')) {
        message =
        'Please check your internet connection.';
      } else if (errorText.contains(
        'developer_error',
      )) {
        message =
        'Google Sign-In is not configured correctly for this app.';
      } else if (errorText.contains(
        'configuration',
      )) {
        message =
        'Google Sign-In configuration is incomplete.';
      } else if (errorText.contains(
        'api_exception',
      )) {
        message =
        'Google Sign-In could not connect. Please try again.';
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(
              seconds: 5,
            ),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // =================================================================
            // CLOSE BUTTON
            // =================================================================

            Positioned(
              top: 8,
              left: 10,
              child: IconButton(
                onPressed: _loading
                    ? null
                    : () {
                  Navigator.pop(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
            ),

            // =================================================================
            // CONTENT
            // =================================================================

            Center(
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  28,
                  55,
                  28,
                  30,
                ),
                child: Column(
                  children: [
                    // =========================================================
                    // LOGO
                    // =========================================================

                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin:
                          Alignment.topLeft,
                          end:
                          Alignment.bottomRight,
                          colors: [
                            colors.primary,
                            Color.lerp(
                              colors.primary,
                              Colors.black,
                              0.18,
                            ) ??
                                colors.primary,
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          29,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary
                                .withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 28,
                            offset:
                            const Offset(
                              0,
                              10,
                            ),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons
                            .local_fire_department_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),

                    const SizedBox(
                      height: 27,
                    ),

                    // =========================================================
                    // TITLE
                    // =========================================================

                    Text(
                      widget.fromSave
                          ? 'Save your recipes'
                          : 'Welcome to TADKA',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color:
                        colors.onSurface,
                        fontSize: 28,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      widget.fromSave
                          ? 'Sign in to save this recipe '
                          'and build your personal cookbook.'
                          : 'Your AI cooking companion for '
                          'discovering and creating delicious recipes.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color: colors
                            .onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    // =========================================================
                    // BENEFIT 1
                    // =========================================================

                    _BenefitCard(
                      icon:
                      Icons.bookmark_rounded,
                      title: 'Save recipes',
                      subtitle:
                      'Keep your favourites in one place.',
                      color:
                      colors.primary,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // =========================================================
                    // BENEFIT 2
                    // =========================================================

                    _BenefitCard(
                      icon: Icons.sync_rounded,
                      title: 'Access anywhere',
                      subtitle:
                      'Your recipes stay synced across devices.',
                      color:
                      colors.primary,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // =========================================================
                    // BENEFIT 3
                    // =========================================================

                    _BenefitCard(
                      icon:
                      Icons.auto_awesome_rounded,
                      title: 'Personal cookbook',
                      subtitle:
                      'Build your own collection over time.',
                      color:
                      colors.primary,
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // =========================================================
                    // GOOGLE BUTTON
                    // =========================================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : _signInWithGoogle,
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          colors.surface,
                          foregroundColor:
                          colors.onSurface,
                          disabledBackgroundColor:
                          colors
                              .surfaceContainerHighest,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              17,
                            ),
                            side: BorderSide(
                              color: colors.outline
                                  .withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ),
                        child: _loading
                            ? SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color:
                            colors.primary,
                          ),
                        )
                            : Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            const _GoogleLogo(),

                            const SizedBox(
                              width: 12,
                            ),

                            const Text(
                              'Continue with Google',
                              style:
                              TextStyle(
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =========================================================
                    // PRIVACY
                    // =========================================================

                    Text(
                      'By continuing, you agree to use TADKA AI '
                          'with your Google account.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color: colors
                            .onSurfaceVariant
                            .withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 9.5,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =========================================================
                    // CONTINUE WITHOUT SIGN IN
                    // =========================================================

                    if (!widget.fromSave)
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child: Text(
                          'Continue without signing in',
                          style: TextStyle(
                            color:
                            colors.primary,
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
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
// BENEFIT CARD
// ============================================================================

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w500,
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
// GOOGLE LOGO
// ============================================================================

class _GoogleLogo
    extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 21,
      height: 21,
      child: CustomPaint(
        painter:
        _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter
    extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      2,
      2,
      size.width - 4,
      size.height - 4,
    );

    // Blue
    paint.color =
    const Color(0xFF4285F4);

    canvas.drawArc(
      rect,
      -0.65,
      1.65,
      false,
      paint,
    );

    // Green
    paint.color =
    const Color(0xFF34A853);

    canvas.drawArc(
      rect,
      1.0,
      1.25,
      false,
      paint,
    );

    // Yellow
    paint.color =
    const Color(0xFFFBBC05);

    canvas.drawArc(
      rect,
      2.25,
      1.0,
      false,
      paint,
    );

    // Red
    paint.color =
    const Color(0xFFEA4335);

    canvas.drawArc(
      rect,
      -2.78,
      1.15,
      false,
      paint,
    );

    // Google "G" horizontal
    paint.color =
    const Color(0xFF4285F4);

    canvas.drawLine(
      Offset(
        size.width * 0.48,
        size.height * 0.52,
      ),
      Offset(
        size.width * 0.90,
        size.height * 0.52,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}