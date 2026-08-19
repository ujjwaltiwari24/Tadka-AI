import 'package:flutter/material.dart';

import 'main_navigation_screen.dart';
import 'theme/app_theme.dart';

class TadkaAIApp extends StatelessWidget {
  const TadkaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TADKA AI',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const MainNavigationScreen(),
    );
  }
}