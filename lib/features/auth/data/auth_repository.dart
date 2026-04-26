import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/services/notification_service.dart';

/// Main authentication repository (Facade pattern)
/// Exposes clean public API and delegates to specialized data sources
class AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final AppUserRemoteDataSource _appUserDataSource;

  AuthRepository({
    AuthRemoteDataSource? authDataSource,
    AppUserRemoteDataSource? userDataSource,
  }) : _authDataSource = authDataSource ?? AuthRemoteDataSource(),
       _appUserDataSource = userDataSource ?? AppUserRemoteDataSource();

  Stream<User?> get authStateChanges => _authDataSource.authStateChanges;

  /// Initialize Google Sign-In (REQUIRED for mobile)
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    await _authDataSource.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Future<AppUser> signInWithGoogle() async {
    final userCredential = await _authDataSource.signInWithGoogle();
    final User? authUser = userCredential.user;
    if (authUser == null) {
      throw AuthException("User is null after Google sign-in");
    }

    final DateTime now = DateTime.now();
    final AppUser? existingAppUser = await _appUserDataSource.getUserData(
      authUser.uid,
    );

    if (existingAppUser != null) {
      // Update last login
      final updatedUser = existingAppUser.copyWith(
        lastLoginAt: now,
        updatedAt: now,
      );
      await _appUserDataSource.updateUserData(updatedUser);

      // Register FCM token after sign-in (mobile only)
      // _registerFcmToken(updatedUser.email);
      _registerFcmToken(updatedUser.uid);

      return updatedUser;
    }

    // Create New User
    final newUser = AppUser(
      uid: authUser.uid,
      name: authUser.displayName ?? '',
      displayName: authUser.displayName ?? '',
      email: authUser.email ?? '',
      photoUrl: authUser.photoURL ?? '',
      provider: authUser.providerData.first.providerId,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
    );

    await _appUserDataSource.createNewUserData(newUser);

    // Register FCM token after sign-in (mobile only)
    // _registerFcmToken(newUser.email);
    _registerFcmToken(newUser.uid);

    return newUser;
  }

  Future<void> signOut() async {
    // Clear FCM token before signing out (mobile only)
    final uid = _authDataSource.currentUser?.uid;
    if (!kIsWeb && uid != null) {
      await NotificationService.instance.clearFcmToken(uid);
    }
    await _authDataSource.signOut();
  }

  Future<void> disconnect() async {
    // Clear FCM token before disconnecting (mobile only)
    final uid = _authDataSource.currentUser?.uid;
    if (!kIsWeb && uid != null) {
      await NotificationService.instance.clearFcmToken(uid);
    }
    await _authDataSource.disconnect();
  }

  User? get currentUser => _authDataSource.currentUser;

  /// Register FCM token to Firestore (fire-and-forget, mobile only).
  void _registerFcmToken(String uid) {
    debugPrint("-------------------------------------------------- UID EMPTYY?? ${uid.isEmpty}");
    if (kIsWeb || uid.isEmpty) return;

    Future(() async {
      // Pass the UID to initialize so the service can track it for token refreshes
      final token = await NotificationService.instance.initialize(uid: uid);
      debugPrint("-------------------------------------------------- THENNN THE TOKENN??? ${token ?? "EMPTY :)"}");
      if (token != null) {
        await NotificationService.instance.upsertFcmToken(
          uid: uid,
          fcmToken: token,
        );
      }
    });
  }
}
