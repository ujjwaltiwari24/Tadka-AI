import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';

// ============================================================================
// CURRENT APP VERSION
// ============================================================================

const int currentVersion = 1;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp();

  // Google Mobile Ads
  await MobileAds.instance.initialize();

  // ==========================================================================
  // CHECK FIREBASE VERSION
  // ==========================================================================

  bool updateRequired = false;
  int? latestVersion;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('appVersion')
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();

      final value = data['latestVersion'];

      latestVersion = int.tryParse(
        value.toString().trim(),
      );

      debugPrint('========== TADKA VERSION ==========');
      debugPrint('Current version: $currentVersion');
      debugPrint('Firebase version: $latestVersion');

      if (latestVersion != null &&
          latestVersion! > currentVersion) {
        updateRequired = true;
      }

      debugPrint('Update required: $updateRequired');
      debugPrint('===================================');
    }
  } catch (e) {
    debugPrint('VERSION CHECK ERROR: $e');
  }

  // ==========================================================================
  // START APP
  // ==========================================================================

  if (updateRequired) {
    runApp(
      UpdateRequiredApp(
        latestVersion: latestVersion,
      ),
    );
  } else {
    runApp(
      const TadkaAIApp(),
    );
  }
}

// ============================================================================
// UPDATE REQUIRED APP
// ============================================================================

class UpdateRequiredApp extends StatelessWidget {
  final int? latestVersion;

  const UpdateRequiredApp({
    super.key,
    this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tadka AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: UpdateRequiredScreen(
        latestVersion: latestVersion,
      ),
    );
  }
}

// ============================================================================
// UPDATE REQUIRED SCREEN
// ============================================================================

class UpdateRequiredScreen extends StatelessWidget {
  final int? latestVersion;

  const UpdateRequiredScreen({
    super.key,
    this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  // ========================================================
                  // ICON
                  // ========================================================

                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(28),
                      gradient:
                      const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF8A00),
                          Color(0xFFFF6500),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF7A00,
                          ).withValues(
                            alpha: 0.20,
                          ),
                          blurRadius: 30,
                          offset:
                          const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ========================================================
                  // TITLE
                  // ========================================================

                  const Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========================================================
                  // DESCRIPTION
                  // ========================================================

                  const Text(
                    'A newer version of TADKA AI '
                        'is available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF686862),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Please update the app to '
                        'continue using TADKA AI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF999993),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ========================================================
                  // VERSION CARD
                  // ========================================================

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.black
                            .withValues(
                          alpha: 0.06,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.035,
                          ),
                          blurRadius: 20,
                          offset:
                          const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _VersionItem(
                            title: 'Current',
                            value:
                            'v$currentVersion',
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.black
                              .withValues(
                            alpha: 0.07,
                          ),
                        ),

                        Expanded(
                          child: _VersionItem(
                            title: 'Latest',
                            value:
                            latestVersion != null
                                ? 'v$latestVersion'
                                : '—',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ========================================================
                  // UPDATE BUTTON
                  // ========================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        _showComingSoon(context);
                      },
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(
                          0xFFFF7A00,
                        ),
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            17,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Update TADKA AI',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'The latest version will be '
                        'available soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF999993),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TEMPORARY UPDATE MESSAGE
  // ==========================================================================

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFFFF7A00),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'TADKA AI is not available on '
                'the Play Store yet.\n\n'
                'The latest version will be '
                'available once the app is published.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// VERSION ITEM
// ============================================================================

class _VersionItem extends StatelessWidget {
  final String title;
  final String value;

  const _VersionItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF85857F),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}