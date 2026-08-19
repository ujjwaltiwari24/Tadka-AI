import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/home/home_screen.dart';
import '../features/ingredients/ingredients_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = const [
      HomeScreen(),
      _CreateScreen(),
      _SavedScreen(),
      _MoreScreen(),
    ];
  }

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

      // ================================================================
      // BOTTOM NAVIGATION
      // ================================================================

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
          // HOME
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),

          // CREATE
          NavigationDestination(
            icon: Icon(
              Icons.auto_awesome_outlined,
            ),
            selectedIcon: Icon(
              Icons.auto_awesome_rounded,
            ),
            label: 'Create',
          ),

          // SAVED
          NavigationDestination(
            icon: Icon(
              Icons.bookmark_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.bookmark_rounded,
            ),
            label: 'Saved',
          ),

          // MORE
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

class _CreateScreen extends StatelessWidget {
  const _CreateScreen();

  @override
  Widget build(BuildContext context) {
    return const IngredientsScreen();
  }
}

// ============================================================================
// SAVED RECIPES
// ============================================================================

class _SavedScreen extends StatelessWidget {
  const _SavedScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved recipes',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ICON
              Container(
                width: 82,
                height: 82,

                decoration: BoxDecoration(
                  color:
                  colors.primary.withValues(
                    alpha: 0.09,
                  ),

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.bookmark_outline_rounded,
                  color: colors.primary,
                  size: 38,
                ),
              ),

              const SizedBox(height: 22),

              // TITLE
              const Text(
                'Your cookbook is coming soon',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 9),

              // DESCRIPTION
              Text(
                'Save your favourite AI recipes '
                    'and access them anytime from '
                    'your personal cookbook.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color:
                  colors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // BUTTON
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Recipe saving is coming soon.',
                        ),
                        behavior:
                        SnackBarBehavior.floating,
                      ),
                    );
                },

                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                ),

                label: const Text(
                  'Create a recipe',
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
// MORE
// ============================================================================

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
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
          12,
          18,
          30,
        ),

        children: [
          // ==============================================================
          // TADKA AI
          // ==============================================================

          _MoreSectionTitle(
            title: 'TADKA AI',
            colors: colors,
          ),

          const SizedBox(height: 10),

          _MoreTile(
            icon:
            Icons.bookmark_outline_rounded,

            title: 'Saved recipes',

            subtitle:
            'View your personal cookbook',

            color: colors.primary,

            onTap: () {
              HapticFeedback.selectionClick();

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Saved recipes are coming soon.',
                    ),
                    behavior:
                    SnackBarBehavior.floating,
                  ),
                );
            },
          ),

          const SizedBox(height: 22),

          // ==============================================================
          // SUPPORT
          // ==============================================================

          _MoreSectionTitle(
            title: 'SUPPORT',
            colors: colors,
          ),

          const SizedBox(height: 10),

          _MoreTile(
            icon:
            Icons.info_outline_rounded,

            title: 'About TADKA',

            subtitle:
            'Learn more about TADKA AI',

            color: colors.primary,

            onTap: () {
              HapticFeedback.selectionClick();

              _showAboutDialog(context);
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

              _showFeedbackDialog(context);
            },
          ),

          const SizedBox(height: 22),

          // ==============================================================
          // ACCOUNT
          // ==============================================================

          _MoreSectionTitle(
            title: 'ACCOUNT',
            colors: colors,
          ),

          const SizedBox(height: 10),

          _MoreTile(
            icon:
            Icons.delete_outline_rounded,

            title: 'Delete account',

            subtitle:
            'Permanently delete your account',

            color: colors.error,

            onTap: () {
              HapticFeedback.selectionClick();

              _showDeleteAccountDialog(
                context,
              );
            },
          ),

          const SizedBox(height: 22),

          // ==============================================================
          // LEGAL
          // ==============================================================

          _MoreSectionTitle(
            title: 'LEGAL & PRIVACY',
            colors: colors,
          ),

          const SizedBox(height: 10),

          _MoreTile(
            icon:
            Icons.gavel_rounded,

            title: 'Legal',

            subtitle:
            'Privacy Policy, Terms & Disclaimer',

            color: colors.primary,

            onTap: () {
              HapticFeedback.selectionClick();

              _showLegalDialog(context);
            },
          ),

          const SizedBox(height: 34),

          // ==============================================================
          // FOOTER
          // ==============================================================

          Center(
            child: Column(
              children: [
                // LOGO
                Container(
                  width: 52,
                  height: 52,

                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius:
                    BorderRadius.circular(16),
                  ),

                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                const SizedBox(height: 11),

                const Text(
                  'TADKA AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Your personal AI cooking assistant',

                  style: TextStyle(
                    color:
                    colors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Version 1.0.0',

                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant
                        .withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // ABOUT
  // ========================================================================

  void _showAboutDialog(
      BuildContext context,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),

          title: const Text(
            'TADKA AI',

            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),

          content: const Text(
            'TADKA AI is your personal AI '
                'cooking companion.\n\n'
                'Turn the ingredients you already '
                'have into practical recipes you '
                'will actually want to cook.\n\n'
                'Discover recipes, explore dishes '
                'and make everyday cooking easier.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'CLOSE',
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // FEEDBACK
  // ========================================================================

  void _showFeedbackDialog(
      BuildContext context,
      ) {
    final controller =
    TextEditingController();

    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),

          title: const Text(
            'Send feedback',

            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),

          content: TextField(
            controller: controller,

            maxLines: 5,

            textCapitalization:
            TextCapitalization.sentences,

            decoration:
            InputDecoration(
              hintText:
              'Tell us what you think...',

              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child: const Text(
                'CANCEL',
              ),
            ),

            FilledButton(
              onPressed: () {
                final feedback =
                controller.text.trim();

                Navigator.pop(
                  dialogContext,
                );

                if (feedback.isEmpty) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                )
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thanks for your feedback! ❤️',
                      ),
                      behavior:
                      SnackBarBehavior
                          .floating,
                    ),
                  );
              },

              child: const Text(
                'SEND',
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // DELETE ACCOUNT
  // ========================================================================

  void _showDeleteAccountDialog(
      BuildContext context,
      ) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),

          icon: Icon(
            Icons.warning_amber_rounded,
            color:
            Theme.of(context)
                .colorScheme
                .error,
            size: 34,
          ),

          title: const Text(
            'Delete account?',

            textAlign: TextAlign.center,

            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),

          content: const Text(
            'This action permanently deletes '
                'your TADKA AI account and its '
                'associated data.\n\n'
                'This cannot be undone.',
            textAlign: TextAlign.center,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child: const Text(
                'CANCEL',
              ),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                Theme.of(context)
                    .colorScheme
                    .error,
                foregroundColor:
                Theme.of(context)
                    .colorScheme
                    .onError,
              ),

              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger.of(
                  context,
                )
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please use your account settings to continue account deletion.',
                      ),
                      behavior:
                      SnackBarBehavior
                          .floating,
                    ),
                  );
              },

              child: const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // LEGAL
  // ========================================================================

  void _showLegalDialog(
      BuildContext context,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),

          title: const Text(
            'Legal & Privacy',

            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),

          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  'Privacy Policy',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'TADKA AI may process information '
                      'required to provide its cooking '
                      'and account features.',
                ),

                SizedBox(height: 18),

                Text(
                  'Terms of Use',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Use TADKA AI responsibly. AI-generated '
                      'recipes should be reviewed before '
                      'cooking, especially when allergies '
                      'or dietary restrictions are involved.',
                ),

                SizedBox(height: 18),

                Text(
                  'Recipe Disclaimer',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'AI-generated recipes are suggestions '
                      'and may contain mistakes. Always verify '
                      'ingredients, quantities and cooking '
                      'instructions before use.',
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'CLOSE',
              ),
            ),
          ],
        );
      },
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
      const EdgeInsets.only(left: 3),

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
        Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,

      borderRadius:
      BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,

        borderRadius:
        BorderRadius.circular(18),

        child: Container(
          padding:
          const EdgeInsets.all(15),

          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(18),

            border: Border.all(
              color: colors.outline
                  .withValues(
                alpha: 0.12,
              ),
            ),
          ),

          child: Row(
            children: [
              // ============================================================
              // ICON
              // ============================================================

              Container(
                width: 46,
                height: 46,

                decoration:
                BoxDecoration(
                  color:
                  color.withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // ============================================================
              // TEXT
              // ============================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,

                      maxLines: 2,

                      overflow:
                      TextOverflow.ellipsis,

                      style: TextStyle(
                        color: colors
                            .onSurfaceVariant,

                        fontSize: 11,

                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ============================================================
              // ARROW
              // ============================================================

              Icon(
                Icons
                    .chevron_right_rounded,

                color: colors
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.65,
                ),

                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}