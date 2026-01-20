import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Firebase Authentication and Google Sign-In
class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Initialize GoogleSignIn (mobile only)
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    if (!kIsWeb) {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      } else {
        return await _signInWithGoogleMobile();
      }
    } catch (e) {
      // Let UI handle all errors
      rethrow;
    }
  }

  /// Web: Google Sign-In using popup
  Future<UserCredential> _signInWithGoogleWeb() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    return await _firebaseAuth.signInWithPopup(googleProvider);
  }

  /// Mobile: Google Sign-In using google_sign_in package
  Future<UserCredential> _signInWithGoogleMobile() async {
    // Sign out first to force account selection
    await _googleSignIn.signOut();
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    if (kIsWeb) {
      await _firebaseAuth.signOut();
    } else {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    }
  }

  /// Disconnect: revokes all permissions
  Future<void> disconnect() async {
    if (kIsWeb) {
      await _firebaseAuth.signOut();
    } else {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.disconnect()]);
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