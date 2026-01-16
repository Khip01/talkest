import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkest/features/auth/models/app_user.dart';

/// Handles Cloud Firestore user profile data
class AppUserRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _appUsersCollection = 'app_users';

  AppUserRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createNewUserData(AppUser appUser) async {
    await _firestore
        .collection(_appUsersCollection)
        .doc(appUser.uid)
        .set(appUser.toFirestore(), SetOptions(merge: true));
  }

  /// Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(_appUsersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw UserDataException("Failed to get user data: $e");
    }
  }

  /// Update user profile data
  Future<void> updateUserData(AppUser appUser) async {
    try {
      await _firestore
          .collection(_appUsersCollection)
          .doc(appUser.uid)
          .update(appUser.toFirestore());
    } catch (e) {
      throw UserDataException("Failed to update user data: $e");
    }
  }

  /// Delete user data from Firestore
  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection(_appUsersCollection).doc(uid).delete();
    } catch (e) {
      throw UserDataException("Failed to delete user data: $e");
    }
  }
}

/// Custom exception for user data (Firestore) errors
class UserDataException implements Exception {
  final String message;

  UserDataException(this.message);

  @override
  String toString() => "UserDataException --- $message";
}
