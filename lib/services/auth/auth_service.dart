import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance =
  AuthService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  // ==========================================================================
  // CURRENT USER
  // ==========================================================================

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn =>
      _auth.currentUser != null;

  // ==========================================================================
  // AUTH STATE
  // ==========================================================================

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // ==========================================================================
  // GOOGLE SIGN IN
  // ==========================================================================

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In.
      await _googleSignIn.initialize();

      // Start Google authentication.
      final GoogleSignInAccount googleUser =
      await _googleSignIn.authenticate();

      // Get Google authentication token.
      final GoogleSignInAuthentication
      googleAuth =
          googleUser.authentication;

      // Create Firebase credential.
      final credential =
      GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase.
      final userCredential =
      await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) {
        return null;
      }

      // Save/update TADKA user profile.
      await _createOrUpdateUser(user);

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(
        'Google sign-in failed: $e',
      );
    }
  }

  // ==========================================================================
  // CREATE / UPDATE USER DOCUMENT
  // ==========================================================================

  Future<void> _createOrUpdateUser(
      User user,
      ) async {
    final userRef =
    _firestore.collection('users').doc(
      user.uid,
    );

    final existing =
    await userRef.get();

    final now =
    FieldValue.serverTimestamp();

    if (!existing.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'provider': 'google',
        'createdAt': now,
        'lastLoginAt': now,
        'updatedAt': now,
      });

      return;
    }

    await userRef.update({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'provider': 'google',
      'lastLoginAt': now,
      'updatedAt': now,
    });
  }

  // ==========================================================================
  // SIGN OUT
  // ==========================================================================

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } finally {
      await _auth.signOut();
    }
  }
}