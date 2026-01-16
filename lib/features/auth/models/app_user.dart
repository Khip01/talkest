import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String displayName;
  final String email;
  final String photoUrl;
  final String provider;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLoginAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;

    return AppUser(
      uid: doc.id,
      name: data['name'] as String,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      photoUrl: data['photoUrl'] as String,
      provider: data['provider'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid,
      name: name,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl,
      provider: provider,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
