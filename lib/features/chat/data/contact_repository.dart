import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/chat/models/chat.dart';

/// Repository for managing contact list (users that current user has chatted with)
class ContactRepository {
  final FirebaseFirestore _firestore;
  final AppUserRemoteDataSource _userRepository;
  static const String _chatsCollection = 'chats';

  ContactRepository({
    FirebaseFirestore? firestore,
    AppUserRemoteDataSource? userRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _userRepository = userRepository ?? AppUserRemoteDataSource();

  /// Get stream of users that current user has chatted with
  /// Fetches from chats collection where current user is a participant
  Stream<List<AppUser>> getContactUsers(String currentUserId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return <AppUser>[];
          }

          // Get unique other user IDs
          final Set<String> otherUserIds = {};
          for (final doc in snapshot.docs) {
            final chat = Chat.fromFirestore(doc);
            final otherUserId = chat.getOtherParticipantId(currentUserId);
            otherUserIds.add(otherUserId);
          }

          // Fetch user data for all contact users
          final List<AppUser> contacts = [];
          for (final userId in otherUserIds) {
            try {
              final user = await _userRepository.getUserData(userId);
              if (user != null) {
                contacts.add(user);
              }
            } catch (e) {
              // Skip users that fail to load
              continue;
            }
          }

          // Sort alphabetically by display name
          contacts.sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

          return contacts;
        });
  }

  /// Get paginated contacts (for lazy loading)
  Future<List<AppUser>> getContactUsersPaginated({
    required String currentUserId,
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      return <AppUser>[];
    }

    // Get unique other user IDs
    final Set<String> otherUserIds = {};
    for (final doc in snapshot.docs) {
      final chat = Chat.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
      final otherUserId = chat.getOtherParticipantId(currentUserId);
      otherUserIds.add(otherUserId);
    }

    // Fetch user data for all contact users
    final List<AppUser> contacts = [];
    for (final userId in otherUserIds) {
      try {
        final user = await _userRepository.getUserData(userId);
        if (user != null) {
          contacts.add(user);
        }
      } catch (e) {
        continue;
      }
    }

    // Sort alphabetically by display name
    contacts.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

    return contacts;
  }
}
