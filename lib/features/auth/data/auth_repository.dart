import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';

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
    return newUser;
  }

  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  Future<void> disconnect() async {
    await _authDataSource.disconnect();
  }

  User? get currentUser => _authDataSource.currentUser;
}
