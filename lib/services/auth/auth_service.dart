import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Access the singleton instance in google_sign_in v7.x
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ==========================================================================
  // GOOGLE WEB CLIENT ID
  // ==========================================================================
  static const String _serverClientId =
      '668330228215-gja4s4nm3m1essmfnc27ji1gsd4af716.apps.googleusercontent.com';

  // ==========================================================================
  // CURRENT USER & AUTH STATE
  // ==========================================================================
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==========================================================================
  // GOOGLE SIGN IN
  // ==========================================================================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('TADKA AUTH: Initializing Google Sign-In...');

      // Initialize with serverClientId in v7.x
      await _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );

      print('TADKA AUTH: Starting Google Sign-In flow...');

      // In v7.x, use authenticate() instead of signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      print('TADKA AUTH: Account selected: ${googleUser.email}');

      // Get authentication credentials
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      print('TADKA AUTH: ID Token present: ${googleAuth.idToken != null}');

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In completed, but no ID Token was returned.',
        );
      }

      // In v7.x, pass only the idToken to GoogleAuthProvider.credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print('TADKA AUTH: Authenticating with Firebase...');

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user == null) {
        print('TADKA AUTH: Firebase returned null user.');
        return null;
      }

      print('TADKA AUTH: Firebase Sign-In successful! UID: ${user.uid}');

      await _createOrUpdateUser(user);

      return userCredential;
    }
    on GoogleSignInException catch (e) {
      print('==============================================');
      print('TADKA AUTH: GOOGLE SIGN-IN ERROR');
      print('Code: ${e.code}');
      print('Description: ${e.description}');
      print('Details: ${e.details}');
      print('==============================================');
      rethrow;
    }
    on FirebaseAuthException catch (e) {
      print('==============================================');
      print('TADKA AUTH: FIREBASE AUTH ERROR');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('==============================================');
      rethrow;
    }
    catch (e, stackTrace) {
      print('==============================================');
      print('TADKA AUTH: UNKNOWN ERROR');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==============================================');
      throw Exception('Google sign-in failed: $e');
    }
  }

  // ==========================================================================
  // CREATE / UPDATE USER DOCUMENT
  // ==========================================================================
  Future<void> _createOrUpdateUser(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final existing = await userRef.get();
    final now = FieldValue.serverTimestamp();

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