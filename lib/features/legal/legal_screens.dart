import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LegalPagesScreen extends StatelessWidget {
  const LegalPagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Legal',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            30,
          ),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(alpha: 0.12),
                    colors.primary.withValues(alpha: 0.035),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: colors.primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal & Privacy',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Everything you need to know about using TADKA AI.',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'POLICIES',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 9),

            _LegalMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How TADKA AI handles your information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),

            _LegalMenuTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Rules for using TADKA AI',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen(),
                  ),
                );
              },
            ),

            _LegalMenuTile(
              icon: Icons.warning_amber_rounded,
              title: 'Recipe Disclaimer',
              subtitle: 'Important food and AI information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecipeDisclaimerScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              'ACCOUNT',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 9),

            _LegalMenuTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your TADKA AI account',
              isDanger: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colors.primary,
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Please review these policies before using TADKA AI. '
                          'Some features use third-party services such as authentication, '
                          'AI services and advertising providers.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'TADKA AI',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _LegalMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final accent =
    isDanger ? colors.error : colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDanger
              ? colors.error.withValues(alpha: 0.10)
              : colors.outline.withValues(alpha: 0.07),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 8.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.onSurfaceVariant,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Privacy Policy',
      subtitle: 'How TADKA AI handles your information',
      icon: Icons.privacy_tip_outlined,
      sections: [
        _LegalSection(
          title: '1. Introduction',
          body:
          'TADKA AI ("TADKA", "we", "us", or "our") is an AI-powered cooking assistant that helps users discover and generate recipes based on ingredients, preferences, and searches.\n\n'
              'This Privacy Policy explains what information we collect, how we use it, how it may be shared, and the choices available to you.',
        ),
        _LegalSection(
          title: '2. Information We Collect',
          body:
          'Depending on how you use TADKA AI, we may process information such as:\n\n'
              '• Account information provided through supported sign-in methods, such as your name, email address, profile photo, and authentication identifier.\n'
              '• Recipe and cooking information you submit, including ingredients, preferences, searches, saved recipes, and generated recipe content.\n'
              '• App activity and technical information necessary to operate, secure, troubleshoot, and improve the service.\n'
              '• Advertising-related information processed by advertising providers when advertisements are displayed.\n'
              '• Information required to maintain your coin balance, daily rewards, recipe unlocks, and other app functionality.',
        ),
        _LegalSection(
          title: '3. How We Use Information',
          body:
          'We may use information to:\n\n'
              '• Provide and personalize TADKA AI features.\n'
              '• Generate and display recipes.\n'
              '• Maintain your account, cookbook, coins, rewards, and recipe unlocks.\n'
              '• Authenticate users and protect accounts.\n'
              '• Prevent abuse, fraud, or unauthorized activity.\n'
              '• Diagnose technical problems and improve app performance.\n'
              '• Display and measure advertisements where applicable.\n'
              '• Respond to support requests.',
        ),
        _LegalSection(
          title: '4. Google Sign-In and Firebase',
          body:
          'TADKA AI uses third-party services such as Firebase Authentication and Google Sign-In to provide account authentication and related functionality.\n\n'
              'Information processed by these services is handled according to their respective terms and privacy policies as well as the configuration of TADKA AI.',
        ),
        _LegalSection(
          title: '5. Advertising',
          body:
          'TADKA AI may display advertisements using third-party advertising services, including rewarded advertisements used to provide optional coin rewards.\n\n'
              'Advertising providers may process information such as advertising identifiers, device information, approximate location, ad interactions, and other information permitted by their services and applicable settings.\n\n'
              'You should review the privacy documentation of the advertising provider used by the app for additional information.',
        ),
        _LegalSection(
          title: '6. AI-Generated Content',
          body:
          'TADKA AI uses artificial intelligence to generate recipe-related content. AI-generated results may contain mistakes, omissions, or inaccurate information.\n\n'
              'Always independently verify ingredients, allergens, cooking temperatures, preparation methods, dietary requirements, and food-safety information before cooking or consuming a recipe.',
        ),
        _LegalSection(
          title: '7. Data Sharing',
          body:
          'We may share information with service providers that help us operate TADKA AI, such as authentication, cloud storage/database, analytics, AI, advertising, security, and infrastructure providers.\n\n'
              'We do not use this policy to authorize unrelated uses of your information. Information is handled for the purposes described in this policy and as required or permitted by applicable law.',
        ),
        _LegalSection(
          title: '8. Data Security',
          body:
          'We use reasonable technical and organizational measures designed to protect information against unauthorized access, alteration, disclosure, or destruction.\n\n'
              'However, no internet-based service can guarantee absolute security.',
        ),
        _LegalSection(
          title: '9. Data Retention',
          body:
          'We retain information for as long as reasonably necessary to provide the service, maintain security, comply with legal obligations, resolve disputes, and enforce our agreements.\n\n'
              'When account deletion is completed, associated account data will be deleted or otherwise handled according to our applicable retention obligations.',
        ),
        _LegalSection(
          title: '10. Account Deletion',
          body:
          'If you have an account, you may request deletion through the account-deletion option provided by TADKA AI.\n\n'
              'When an account deletion request is completed, associated account information and user data will be deleted, except where retention is required or permitted by applicable law or legitimate security obligations.',
        ),
        _LegalSection(
          title: '11. Children',
          body:
          'TADKA AI is not specifically directed toward children. We do not knowingly collect personal information from children in violation of applicable law.',
        ),
        _LegalSection(
          title: '12. Changes to This Policy',
          body:
          'We may update this Privacy Policy from time to time. When changes are made, the updated version will be made available through TADKA AI and the applicable public privacy-policy location.',
        ),
        _LegalSection(
          title: '13. Contact',
          body:
          'For privacy questions, data requests, or concerns, please contact the TADKA AI support/privacy contact published with the app and on its official privacy-policy page.\n\n'
              'IMPORTANT: Replace this section with your real legal/privacy contact email before publishing.',
        ),
      ],
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Terms of Service',
      subtitle: 'Rules for using TADKA AI',
      icon: Icons.description_outlined,
      sections: [
        _LegalSection(
          title: '1. Acceptance',
          body:
          'By using TADKA AI, you agree to these Terms of Service. If you do not agree with these terms, please do not use the service.',
        ),
        _LegalSection(
          title: '2. The TADKA AI Service',
          body:
          'TADKA AI provides AI-assisted cooking and recipe discovery features. Features may change, be improved, suspended, or discontinued as the service evolves.',
        ),
        _LegalSection(
          title: '3. Accounts',
          body:
          'Some features require an account. You are responsible for maintaining access to your account and for activity performed through your account.\n\n'
              "You must not use another person's account without authorization.",
        ),
        _LegalSection(
          title: '4. Recipes and AI Content',
          body:
          'Recipes generated or displayed by TADKA AI are provided for informational and culinary assistance purposes.\n\n'
              'AI-generated recipes may contain errors. You are responsible for checking ingredients, allergens, dietary suitability, quantities, cooking temperatures, and food-safety requirements before preparing food.',
        ),
        _LegalSection(
          title: '5. Coins and Rewards',
          body:
          'TADKA AI may provide coins through promotional mechanisms such as daily rewards or rewarded advertisements.\n\n'
              'Coins are virtual in-app credits. They have no cash value, cannot be exchanged for real-world currency, and cannot be transferred between users unless TADKA explicitly provides such functionality.\n\n'
              'Reward availability, amounts, eligibility, and limits may change.',
        ),
        _LegalSection(
          title: '6. Advertisements',
          body:
          'TADKA AI may display advertisements from third-party advertising providers. Some advertisements may provide optional in-app rewards when successfully completed.',
        ),
        _LegalSection(
          title: '7. Prohibited Use',
          body:
          'You must not misuse TADKA AI, interfere with its operation, attempt unauthorized access, abuse rewards, manipulate advertising systems, reverse engineer protected components, or use the service for unlawful purposes.',
        ),
        _LegalSection(
          title: '8. Intellectual Property',
          body:
          'TADKA AI and its branding, interface, software, design, and original content are protected by applicable intellectual-property laws.\n\n'
              'You may use the service for its intended personal purposes but may not reproduce or exploit protected portions of the service without authorization.',
        ),
        _LegalSection(
          title: '9. Third-Party Services',
          body:
          'TADKA AI relies on third-party services including authentication, cloud infrastructure, AI services, and advertising providers. Their availability and operation may be outside our control.',
        ),
        _LegalSection(
          title: '10. Disclaimer',
          body:
          'TADKA AI is provided on an "as available" basis. We do not guarantee that every generated recipe will be accurate, complete, suitable for a particular dietary requirement, or free from allergens.',
        ),
        _LegalSection(
          title: '11. Changes',
          body:
          'We may update these Terms as the service changes. Continued use of TADKA AI after an updated version becomes available may constitute acceptance of the revised terms where permitted by applicable law.',
        ),
        _LegalSection(
          title: '12. Contact',
          body:
          'For questions regarding these Terms, contact the official TADKA AI support contact published with the service.\n\n'
              'IMPORTANT: Replace this section with your real contact details before publication.',
        ),
      ],
    );
  }
}

class RecipeDisclaimerScreen extends StatelessWidget {
  const RecipeDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Recipe Disclaimer',
      subtitle: 'Important information before you cook',
      icon: Icons.warning_amber_rounded,
      sections: [
        _LegalSection(
          title: 'AI-Generated Recipes',
          body:
          'TADKA AI uses artificial intelligence to generate and recommend recipes. AI systems can make mistakes and may produce incomplete, inaccurate, or unsuitable instructions.',
        ),
        _LegalSection(
          title: 'Food Safety',
          body:
          'Always follow applicable food-safety practices. Verify cooking temperatures, preparation times, storage requirements, ingredient freshness, and safe handling procedures independently.',
        ),
        _LegalSection(
          title: 'Allergies',
          body:
          'Do not rely solely on TADKA AI to determine whether a recipe is safe for a food allergy or intolerance. Always check ingredient labels and cross-contact risks and consult an appropriate professional when necessary.',
        ),
        _LegalSection(
          title: 'Dietary Requirements',
          body:
          'Recipe recommendations may not always satisfy medical, religious, nutritional, or other specialized dietary requirements. Verify every ingredient and preparation method yourself.',
        ),
        _LegalSection(
          title: 'Nutrition',
          body:
          'Any estimated nutritional information shown by TADKA AI should be treated as an estimate and not as professional nutritional advice.',
        ),
        _LegalSection(
          title: 'Your Responsibility',
          body:
          'You are responsible for deciding whether a recipe, ingredient, quantity, substitution, or cooking method is appropriate and safe for you and anyone consuming the food.',
        ),
      ],
    );
  }
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState
    extends State<DeleteAccountScreen> {
  bool _confirmed = false;
  bool _deleting = false;

  Future<void> _deleteAccount() async {
    if (!_confirmed || _deleting) return;

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You are not signed in.',
      );
      return;
    }

    final shouldDelete =
    await showDialog<bool>(
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
          title: const Text(
            'Delete account?',
            style: TextStyle(
              fontWeight:
              FontWeight.w900,
            ),
          ),
          content: const Text(
            'This permanently removes your TADKA account and your account-linked data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                colors.error,
              ),
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _deleting = true;
    });

    try {
      /*
       * Google Sign-In users can require recent authentication
       * before Firebase allows account deletion.
       *
       * We re-authenticate BEFORE deleting Firestore data so that
       * we don't end up deleting the user's data and then failing
       * to delete the Firebase Auth account.
       */
      await _reauthenticateIfNeeded(user);

      final firestore =
          FirebaseFirestore.instance;

      final userRef = firestore
          .collection('users')
          .doc(user.uid);

      // ---------------------------------------------------------------
      // Delete saved recipes
      // ---------------------------------------------------------------

      final savedRecipes =
      await userRef
          .collection('savedRecipes')
          .get();

      if (savedRecipes.docs.isNotEmpty) {
        final batch =
        firestore.batch();

        for (final document
        in savedRecipes.docs) {
          batch.delete(
            document.reference,
          );
        }

        await batch.commit();
      }

      // ---------------------------------------------------------------
      // Delete main user document
      // ---------------------------------------------------------------

      await userRef.delete();

      // ---------------------------------------------------------------
      // Delete Firebase Authentication account
      // ---------------------------------------------------------------

      await user.delete();

      // ---------------------------------------------------------------
      // Google sign out
      // ---------------------------------------------------------------

      try {
        final googleSignIn =
            GoogleSignIn.instance;

        await googleSignIn.initialize();
        await googleSignIn.signOut();
      } catch (_) {
        // Firebase account has already been deleted.
      }

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                24,
              ),
            ),
            title: const Text(
              'Account deleted',
              style: TextStyle(
                fontWeight:
                FontWeight.w900,
              ),
            ),
            content: const Text(
              'Your TADKA account and account-linked data have been deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                  Navigator.popUntil(
                    context,
                        (route) =>
                    route.isFirst,
                  );
                },
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Delete account FirebaseAuth error: ${e.code}',
      );

      if (!mounted) return;

      if (e.code ==
          'requires-recent-login') {
        _showReauthenticationMessage();
      } else {
        _showMessage(
          'We could not delete your account. Please try again.',
        );
      }
    } catch (e) {
      debugPrint(
        'Delete account error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'We could not delete your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  Future<void> _reauthenticateIfNeeded(
      User user,
      ) async {
    // Google accounts require a fresh credential for a reliable
    // account-deletion flow. Re-authenticate before deleting any
    // Firestore data so the account deletion can be completed first.
    // If the user cancels Google sign-in, no account data is deleted.
    final providerIds =
    user.providerData
        .map(
          (provider) =>
      provider.providerId,
    )
        .toSet();

    if (!providerIds.contains(
      'google.com',
    )) {
      return;
    }

    try {
      final googleSignIn =
          GoogleSignIn.instance;

      await googleSignIn.initialize();

      final googleUser =
      await googleSignIn.authenticate();

      final googleAuth =
          googleUser.authentication;

      final idToken =
          googleAuth.idToken;

      if (idToken == null ||
          idToken.isEmpty) {
        throw FirebaseAuthException(
          code:
          'missing-google-id-token',
          message:
          'Google did not return an ID token.',
        );
      }

      final credential =
      GoogleAuthProvider.credential(
        idToken: idToken,
      );

      await user.reauthenticateWithCredential(
        credential,
      );
    } on GoogleSignInException catch (e) {
      if (e.code ==
          GoogleSignInExceptionCode
              .canceled) {
        throw FirebaseAuthException(
          code: 'reauth-cancelled',
          message:
          'Account deletion was cancelled.',
        );
      }

      rethrow;
    }
  }

  void _showReauthenticationMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'For security, please sign in again and then retry account deletion.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
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
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics:
          const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          children: [
            Container(
              padding:
              const EdgeInsets.all(20),
              decoration:
              BoxDecoration(
                color: colors.error
                    .withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                BorderRadius.circular(
                  23,
                ),
                border: Border.all(
                  color: colors.error
                      .withValues(
                    alpha: 0.13,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration:
                    BoxDecoration(
                      color: colors.error
                          .withValues(
                        alpha: 0.10,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child: Icon(
                      Icons
                          .delete_outline_rounded,
                      color:
                      colors.error,
                      size: 31,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Delete your TADKA account',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing:
                      -0.4,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    'This permanently removes your account and account-linked data.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: colors
                          .onSurfaceVariant,
                      fontSize: 10.5,
                      height: 1.45,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const _DeleteInfoCard(
              icon:
              Icons.person_outline_rounded,
              title:
              'Account information',
              text:
              'Your TADKA account document and authentication account will be removed.',
            ),

            const SizedBox(
              height: 10,
            ),

            const _DeleteInfoCard(
              icon:
              Icons.bookmark_outline_rounded,
              title:
              'Saved recipes',
              text:
              'Recipes saved inside your TADKA cookbook will be removed.',
            ),

            const SizedBox(
              height: 10,
            ),

            const _DeleteInfoCard(
              icon:
              Icons.monetization_on_outlined,
              title:
              'Coins and rewards',
              text:
              'Your account-linked Coins, streak information and reward state will no longer be available.',
            ),

            const SizedBox(
              height: 22,
            ),

            Container(
              padding:
              const EdgeInsets.all(14),
              decoration:
              BoxDecoration(
                color: colors.surface,
                borderRadius:
                BorderRadius.circular(
                  17,
                ),
                border: Border.all(
                  color: colors.outline
                      .withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Checkbox(
                    value:
                    _confirmed,
                    activeColor:
                    colors.error,
                    onChanged:
                    _deleting
                        ? null
                        : (value) {
                      setState(() {
                        _confirmed =
                            value ??
                                false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Padding(
                      padding:
                      EdgeInsets.only(
                        top: 12,
                      ),
                      child: Text(
                        'I understand that account deletion is permanent and cannot be undone.',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                          FontWeight.w600,
                          height: 1.4,
                        ),
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
                _confirmed &&
                    !_deleting
                    ? _deleteAccount
                    : null,
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  colors.error,
                  disabledBackgroundColor:
                  colors.onSurface
                      .withValues(
                    alpha: 0.08,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child: _deleting
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2.2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                  'DELETE MY ACCOUNT',
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
              height: 12,
            ),

            Text(
              'Your account deletion is processed from this app. '
                  'Before publishing, make sure your external Play Store deletion '
                  'request page is also configured.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color: colors
                    .onSurfaceVariant,
                fontSize: 8.5,
                height: 1.4,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentScreen
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_LegalSection> sections;

  const _LegalDocumentScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics:
          const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            35,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(
                      alpha: 0.12,
                    ),
                    colors.primary.withValues(
                      alpha: 0.035,
                    ),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(24),
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
                    decoration: BoxDecoration(
                      color: colors.primary
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: colors.primary,
                      size: 25,
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
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
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
            ),

            const SizedBox(height: 18),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius:
                BorderRadius.circular(13),
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
                    Icons.update_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Last updated: August 2026',
                    style: TextStyle(
                      color:
                      colors.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            ...sections.map(
                  (section) => Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 18,
                ),
                child: _LegalSectionCard(
                  section: section,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                'TADKA AI',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection({
    required this.title,
    required this.body,
  });
}

class _LegalSectionCard
    extends StatelessWidget {
  final _LegalSection section;

  const _LegalSectionCard({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        17,
        17,
        17,
        18,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(19),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteInfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _DeleteInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 19,
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
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 9.5,
                    height: 1.4,
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
