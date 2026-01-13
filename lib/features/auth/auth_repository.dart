import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  /// Initialize Google Sign-In (REQUIRED for mobile)
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    await _authDataSource.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final userCredential = await _authDataSource.signInWithGoogle();

    if (userCredential.user != null) {
      await _userDataSource.saveUserData(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  Future<void> disconnect() async {
    await _authDataSource.disconnect();
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

/// Handles Cloud Firestore user profile data
class UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';

  UserRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveUserData(User user) async {
    await _firestore.collection(_usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
