import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/home/home_screen.dart';
import '../features/ingredients/ingredients_screen.dart';
import '../features/cookbook/cookbook_screen.dart';

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
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MoreTile(
            icon: Icons.tune_rounded,
            title: 'Cooking preferences',
            subtitle:
            'Manage your default cooking preferences',
            color: colors.primary,
            onTap: () {
              _showComingSoon(
                context,
                'Cooking preferences',
              );
            },
          ),

          const SizedBox(height: 10),

          _MoreTile(
            icon: Icons.info_outline_rounded,
            title: 'About TADKA',
            subtitle:
            'Learn more about TADKA AI',
            color: colors.primary,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'TADKA AI',
                applicationVersion: '1.0.0',
                applicationLegalese:
                'Your personal AI cooking assistant.',
              );
            },
          ),

          const SizedBox(height: 10),

          _MoreTile(
            icon: Icons.feedback_outlined,
            title: 'Send feedback',
            subtitle:
            'Help us improve TADKA',
            color: colors.primary,
            onTap: () {
              _showComingSoon(
                context,
                'Feedback',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(
      BuildContext context,
      String feature,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature is coming soon.',
          ),
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.all(16),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
      );
  }
}

// ============================================================================
// MORE TILE
// ============================================================================

class _MoreTile extends StatelessWidget {
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
                ),
              ),

              const SizedBox(width: 13),

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
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors
                            .onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 14,
                color: colors
                    .onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}