import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../features/home/home_screen.dart';
import '../features/ingredients/ingredients_screen.dart';
import '../features/cookbook/cookbook_screen.dart';
import '../features/legal/legal_screens.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    _CreatePlaceholder(),
    _SavedScreen(),
    _MoreScreen(),
  ];

  void _onNavigationChanged(int index) {
    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected:
        _onNavigationChanged,
        backgroundColor:
        theme.scaffoldBackgroundColor,
        indicatorColor:
        colors.primary.withValues(
          alpha: 0.12,
        ),
        height: 70,
        labelBehavior:
        NavigationDestinationLabelBehavior
            .onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.auto_awesome_outlined,
            ),
            selectedIcon: Icon(
              Icons.auto_awesome_rounded,
            ),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bookmark_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.bookmark_rounded,
            ),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.more_horiz_rounded,
            ),
            selectedIcon: Icon(
              Icons.more_horiz_rounded,
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CREATE
// ============================================================================

class _CreatePlaceholder extends StatelessWidget {
  const _CreatePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const IngredientsScreen();
  }
}

// ============================================================================
// SAVED
// ============================================================================

class _SavedScreen extends StatelessWidget {
  const _SavedScreen();

  @override
  Widget build(BuildContext context) {
    return const CookbookScreen();
  }
}

// ============================================================================
// MORE
// ============================================================================

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
        theme.scaffoldBackgroundColor,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'More',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Everything TADKA AI has to offer',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: ListView(
          physics:
          const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),
          children: [
            // ================================================================
            // TADKA AI
            // ================================================================

            _MoreSectionTitle(
              title: 'TADKA AI',
              colors: colors,
            ),

            const SizedBox(height: 9),

            _MoreTile(
              icon:
              Icons.bookmark_outline_rounded,
              title: 'Saved recipes',
              subtitle:
              'View your personal cookbook',
              color: colors.primary,
              onTap: () {
                HapticFeedback.selectionClick();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const CookbookScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ================================================================
            // LEGAL & PRIVACY
            // ================================================================

            _MoreSectionTitle(
              title: 'LEGAL & PRIVACY',
              colors: colors,
            ),

            const SizedBox(height: 9),

            _MoreTile(
              icon: Icons.gavel_rounded,
              title: 'Legal',
              subtitle:
              'Privacy, terms and account policies',
              color: colors.primary,
              onTap: () {
                HapticFeedback.selectionClick();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const LegalPagesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ================================================================
            // ABOUT
            // ================================================================

            _MoreSectionTitle(
              title: 'ABOUT',
              colors: colors,
            ),

            const SizedBox(height: 9),

            _MoreTile(
              icon:
              Icons.info_outline_rounded,
              title: 'About TADKA',
              subtitle:
              'Discover what TADKA AI is all about',
              color: colors.primary,
              onTap: () {
                HapticFeedback.selectionClick();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const AboutTadkaScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            _MoreTile(
              icon:
              Icons.feedback_outlined,
              title: 'Send feedback',
              subtitle:
              'Tell us what we can improve',
              color: colors.primary,
              onTap: () {
                HapticFeedback.selectionClick();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const FeedbackScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // ================================================================
            // FOOTER
            // ================================================================

            Center(
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      gradient:
                      LinearGradient(
                        begin:
                        Alignment.topLeft,
                        end:
                        Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          colors.primary
                              .withValues(
                            alpha: 0.72,
                          ),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary
                              .withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 16,
                          offset:
                          const Offset(
                            0,
                            6,
                          ),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons
                          .restaurant_menu_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),

                  const SizedBox(height: 11),

                  Text(
                    'TADKA AI',
                    style: TextStyle(
                      color:
                      colors.onSurface,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Your personal AI cooking assistant',
                    style: TextStyle(
                      color: colors
                          .onSurfaceVariant,
                      fontSize: 8.5,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: colors
                          .onSurfaceVariant
                          .withValues(
                        alpha: 0.60,
                      ),
                      fontSize: 8,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ABOUT TADKA
// ============================================================================

class AboutTadkaScreen extends StatelessWidget {
  const AboutTadkaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'About TADKA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        physics:
        const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          35,
        ),
        children: [
          // HERO
          Container(
            padding: const EdgeInsets.fromLTRB(
              22,
              26,
              22,
              24,
            ),
            decoration:
            BoxDecoration(
              gradient: LinearGradient(
                begin:
                Alignment.topLeft,
                end:
                Alignment.bottomRight,
                colors: [
                  colors.primary,
                  colors.primary.withValues(
                    alpha: 0.72,
                  ),
                ],
              ),
              borderRadius:
              BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.primary
                      .withValues(
                    alpha: 0.16,
                  ),
                  blurRadius: 30,
                  offset:
                  const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration:
                  BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.14,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color: Colors.white
                          .withValues(
                        alpha: 0.18,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .restaurant_menu_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 17),

                const Text(
                  'TADKA AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Your personal AI cooking companion',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.85,
                    ),
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 17),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: const Text(
                    'VERSION 1.0.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const _AboutCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Our idea',
            text:
            'TADKA AI is built to solve one simple problem: '
                '“I have ingredients, but I do not know what to cook.” '
                'Instead of endlessly searching for recipes, TADKA helps '
                'turn what you already have into something worth cooking.',
          ),

          const SizedBox(height: 10),

          const _AboutCard(
            icon: Icons.auto_awesome_rounded,
            title: 'AI-powered cooking',
            text:
            'TADKA uses artificial intelligence to understand '
                'ingredients, preferences and cooking requirements '
                'and turn them into structured recipe suggestions.',
          ),

          const SizedBox(height: 10),

          const _AboutCard(
            icon: Icons.restaurant_menu_rounded,
            title: 'Built for real cooking',
            text:
            'Recipes are designed around practical information '
                'such as ingredients, quantities, cooking time, '
                'difficulty, substitutions, equipment and step-by-step '
                'instructions.',
          ),

          const SizedBox(height: 10),

          const _AboutCard(
            icon: Icons.monetization_on_outlined,
            title: 'TADKA Coins',
            text:
            'TADKA includes a reward system that lets users earn '
                'Coins through daily rewards and optional rewarded ads. '
                'Coins can be used to unlock additional recipes.',
          ),

          const SizedBox(height: 20),

          Container(
            padding:
            const EdgeInsets.all(18),
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.055,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: colors.primary
                    .withValues(
                  alpha: 0.09,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color:
                  colors.primary,
                  size: 22,
                ),
                const SizedBox(
                  height: 9,
                ),
                const Text(
                  'Made to make cooking easier.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Less searching. Less guessing. More cooking.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight.w600,
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
// ABOUT CARD
// ============================================================================

class _AboutCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
      const EdgeInsets.all(17),
      decoration:
      BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(19),
        border: Border.all(
          color: colors.outline
              .withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
              colors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  text,
                  style:
                  TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 9.5,
                    height: 1.5,
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
// FEEDBACK SCREEN
// ============================================================================

class FeedbackScreen
    extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() =>
      _FeedbackScreenState();
}

class _FeedbackScreenState
    extends State<FeedbackScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final _subjectController =
  TextEditingController();

  final _messageController =
  TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_sending) return;

    if (!(_formKey.currentState
        ?.validate() ??
        false)) {
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _sending = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('feedback')
          .add({
        'uid': user?.uid,
        'name': user?.displayName,
        'email': user?.email ?? '',
        'Subject':
        _subjectController.text.trim(),
        'Message':
        _messageController.text.trim(),
        'subject':
        _subjectController.text.trim(),
        'message':
        _messageController.text.trim(),
        'status': 'new',
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      _subjectController.clear();
      _messageController.clear();

      await showDialog(
        context: context,
        builder: (context) {
          final colors =
              Theme.of(context)
                  .colorScheme;

          return AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                24,
              ),
            ),
            contentPadding:
            const EdgeInsets.fromLTRB(
              24,
              26,
              24,
              12,
            ),
            content: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration:
                  BoxDecoration(
                    color: colors.primary
                        .withValues(
                      alpha: 0.09,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child: Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                    colors.primary,
                    size: 35,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                const Text(
                  'Feedback sent',
                  style:
                  TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  'Thanks for helping us make TADKA AI better.',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                    ),
                child: Text(
                  'DONE',
                  style:
                  TextStyle(
                    color:
                    colors.primary,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Feedback error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Could not send feedback. Please try again.',
            ),
            behavior:
            SnackBarBehavior.floating,
            margin:
            const EdgeInsets.all(16),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.colorScheme;

    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Send Feedback',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),
          children: [
            Container(
              padding:
              const EdgeInsets.all(20),
              decoration:
              BoxDecoration(
                gradient:
                LinearGradient(
                  begin:
                  Alignment.topLeft,
                  end:
                  Alignment.bottomRight,
                  colors: [
                    colors.primary
                        .withValues(
                      alpha: 0.12,
                    ),
                    colors.primary
                        .withValues(
                      alpha: 0.035,
                    ),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(
                  23,
                ),
                border: Border.all(
                  color: colors.primary
                      .withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                    BoxDecoration(
                      color: colors.primary
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      Icons
                          .feedback_outlined,
                      color:
                      colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Help us improve TADKA',
                          style:
                          TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Found a bug? Have an idea? We want to hear it.',
                          style:
                          TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                            FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            _FeedbackLabel(
              text: 'SUBJECT',
              colors: colors,
            ),

            const SizedBox(height: 7),

            TextFormField(
              controller:
              _subjectController,
              textInputAction:
              TextInputAction.next,
              maxLength: 80,
              decoration:
              _feedbackDecoration(
                context,
                hint:
                'Feature suggestion, bug report...',
                icon:
                Icons.subject_rounded,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter a subject.';
                }

                if (value.trim().length <
                    3) {
                  return 'Subject is too short.';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 8,
            ),

            _FeedbackLabel(
              text: 'MESSAGE',
              colors: colors,
            ),

            const SizedBox(height: 7),

            TextFormField(
              controller:
              _messageController,
              minLines: 6,
              maxLines: 10,
              maxLength: 1000,
              textInputAction:
              TextInputAction.newline,
              decoration:
              _feedbackDecoration(
                context,
                hint:
                'Tell us what happened or what you would like to see...',
                icon:
                Icons.chat_bubble_outline_rounded,
                alignIconTop: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter your feedback.';
                }

                if (value.trim().length <
                    10) {
                  return 'Please provide a little more detail.';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 8,
            ),

            if (user != null)
              Container(
                padding:
                const EdgeInsets.all(13),
                decoration:
                BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: colors.outline
                        .withValues(
                      alpha: 0.07,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .account_circle_outlined,
                      color:
                      colors.primary,
                      size: 18,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        'Sending as ${user.email ?? 'your TADKA account'}',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        TextStyle(
                          color: colors
                              .onSurfaceVariant,
                          fontSize: 9,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              width:
              double.infinity,
              height: 52,
              child: FilledButton(
                onPressed:
                _sending
                    ? null
                    : _sendFeedback,
                style:
                FilledButton
                    .styleFrom(
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                  'SEND FEEDBACK',
                  style:
                  TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing:
                    0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              'Your feedback is stored securely in TADKA AI.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                colors.onSurfaceVariant,
                fontSize: 8.5,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _feedbackDecoration(
      BuildContext context, {
        required String hint,
        required IconData icon,
        bool alignIconTop = false,
      }) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color:
        colors.onSurfaceVariant
            .withValues(
          alpha: 0.65,
        ),
        fontSize: 10.5,
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(
          top: alignIconTop ? 15 : 0,
        ),
        child: Icon(
          icon,
          size: 19,
          color:
          colors.onSurfaceVariant,
        ),
      ),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.outline
              .withValues(
            alpha: 0.08,
          ),
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.outline
              .withValues(
            alpha: 0.08,
          ),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.primary
              .withValues(
            alpha: 0.55,
          ),
          width: 1.3,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.error
              .withValues(
            alpha: 0.55,
          ),
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.error,
          width: 1.3,
        ),
      ),
      counterStyle: TextStyle(
        color:
        colors.onSurfaceVariant,
        fontSize: 8,
      ),
    );
  }
}

// ============================================================================
// FEEDBACK LABEL
// ============================================================================

class _FeedbackLabel
    extends StatelessWidget {
  final String text;
  final ColorScheme colors;

  const _FeedbackLabel({
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color:
        colors.onSurfaceVariant,
        fontSize: 8,
        fontWeight:
        FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _MoreSectionTitle
    extends StatelessWidget {
  final String title;
  final ColorScheme colors;

  const _MoreSectionTitle({
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        left: 3,
      ),
      child: Text(
        title,
        style: TextStyle(
          color:
          colors.onSurfaceVariant,
          fontSize: 8,
          fontWeight:
          FontWeight.w900,
          letterSpacing: 1.15,
        ),
      ),
    );
  }
}

// ============================================================================
// MORE TILE
// ============================================================================

class _MoreTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Material(
      color: colors.surface,
      borderRadius:
      BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        splashColor:
        color.withValues(
          alpha: 0.06,
        ),
        highlightColor:
        color.withValues(
          alpha: 0.025,
        ),
        child: Container(
          padding:
          const EdgeInsets.all(15),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: colors.outline
                  .withValues(
                alpha: 0.08,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.025,
                ),
                blurRadius: 12,
                offset:
                const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color:
                  color.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                        letterSpacing:
                        -0.1,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      TextStyle(
                        color: colors
                            .onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight:
                        FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Container(
                width: 30,
                height: 30,
                decoration:
                BoxDecoration(
                  color: color
                      .withValues(
                    alpha: 0.055,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 11,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}