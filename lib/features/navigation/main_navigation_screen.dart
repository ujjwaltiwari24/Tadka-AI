import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/home_screen.dart';
import '../ingredients/ingredients_screen.dart';
import '../profile/profile_screen.dart';
import '../cookbook/cookbook_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    IngredientsScreen(),
    CookbookScreen(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.outline.withValues(
                alpha: isDark ? 0.24 : 0.10,
              ),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.22 : 0.055,
              ),
              blurRadius: 24,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            10,
            8,
            10,
            8,
          ),
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: _currentIndex == 0,
                primary: colors.primary,
                secondary: colors.onSurfaceVariant,
                onTap: () => _onTabSelected(0),
              ),
              _NavItem(
                label: 'Ingredients',
                icon: Icons.kitchen_outlined,
                selectedIcon: Icons.kitchen_rounded,
                selected: _currentIndex == 1,
                primary: colors.primary,
                secondary: colors.onSurfaceVariant,
                onTap: () => _onTabSelected(1),
              ),
              _NavItem(
                label: 'Cookbook',
                icon: Icons.bookmark_border_rounded,
                selectedIcon: Icons.bookmark_rounded,
                selected: _currentIndex == 2,
                primary: colors.primary,
                secondary: colors.onSurfaceVariant,
                onTap: () => _onTabSelected(2),
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                selected: _currentIndex == 3,
                primary: colors.primary,
                secondary: colors.onSurfaceVariant,
                onTap: () => _onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Color primary;
  final Color secondary;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.primary,
    required this.secondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: primary.withValues(alpha: 0.08),
          highlightColor: primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 58 : 42,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.11)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 21,
                    color: selected ? primary : secondary,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: selected ? primary : secondary,
                    fontSize: selected ? 9.5 : 9,
                    fontWeight: selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
