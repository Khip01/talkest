import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Main authentication repository (Facade pattern)
/// Exposes clean public API and delegates to specialized data sources
class AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final UserRemoteDataSource _userDataSource;

  AuthRepository({
    AuthRemoteDataSource? authDataSource,
    UserRemoteDataSource? userDataSource,
  }) : _authDataSource = authDataSource ?? AuthRemoteDataSource(),
       _userDataSource = userDataSource ?? UserRemoteDataSource();

  Stream<User?> get authStateChanges => _authDataSource.authStateChanges;

  /// Initialize Google Sign-In (REQUIRED in version 7.x)
  /// Should call this in main() before runApp()
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    await _authDataSource.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final userCredential = await _authDataSource.signInWithGoogle();

    // Save user data to Firestore after successful authentication
    if (userCredential.user != null) {
      await _userDataSource.saveUserData(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  User? get currentUser => _authDataSource.currentUser;
}

/// Handles Firebase Authentication and Google Sign-In
class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// CRITICAL: Initialize Google Sign-In before using
  /// In version 7.x this MUST be called before any sign-in attempts
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      // Version 7.x uses authenticate() instead of signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Get ID token from authentication (synchronous in v7.x)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Validate that we have the ID token
      if (googleAuth.idToken == null) {
        throw AuthException('Failed to get ID token from Google');
      }

      // Create Firebase credential using the ID token
      // Note: In v7.x, GoogleSignInAuthentication only has idToken (no accessToken)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Google sign-in was cancelled by user');
      }
      throw AuthException(
        'Google sign-in error: ${e.description ?? e.toString()}',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException('Firebase Auth error: ${e.message ?? e.code}');
    } catch (e) {
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  /// Regular sign out - user stays authorized for faster re-login
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(), // use signOut() instead of disconnect()
      ]);
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Complete disconnect - revokes all permissions and authorization
  /// User will need to go through full authorization flow again
  Future<void> disconnect() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.disconnect(),
      ]);
    } catch (e) {
      throw AuthException('Failed to disconnect: $e');
    }
  }
}

/// Handles Cloud Firestore user profile data
class UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';

  UserRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveUserData(User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw UserDataException('Failed to save user data: $e');
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw UserDataException('Failed to get user data: $e');
    }
  }

  /// Update user profile data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      throw UserDataException('Failed to update user data: $e');
    }
  }

  /// Delete user data from Firestore
  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw UserDataException('Failed to delete user data: $e');
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Custom exception for user data (Firestore) errors
class UserDataException implements Exception {
  final String message;

  UserDataException(this.message);

  @override
  String toString() => 'UserDataException: $message';
}
