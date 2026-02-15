import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles FCM token management and push notification permissions.
/// All operations are no-op on Web platform.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Initialize FCM and request permission (mobile only).
  /// Returns the FCM token or null if on Web / permission denied.
  Future<String?> initialize() async {
    if (kIsWeb) return null;

    final messaging = FirebaseMessaging.instance;

    // Request notification permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('[NotificationService] Permission denied');
      return null;
    }

    // Retrieve FCM token
    final token = await messaging.getToken();
    debugPrint('[NotificationService] FCM token: $token');

    // Listen for token refresh and update Supabase
    messaging.onTokenRefresh.listen(_onTokenRefresh);

    return token;
  }

  /// Upsert email + fcm_token into Supabase 'profiles' table.
  Future<void> upsertFcmToken({
    required String email,
    required String fcmToken,
  }) async {
    if (kIsWeb) return;

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'email': email,
          'fcm_token': fcmToken,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'email',
      );
      debugPrint('[NotificationService] FCM token upserted for $email');
    } catch (e) {
      debugPrint('[NotificationService] Error upserting token: $e');
    }
  }

  /// Fetch receiver's FCM token by email from Supabase 'profiles' table.
  Future<String?> getFcmTokenByEmail(String email) async {
    if (kIsWeb) return null;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return response['fcm_token'] as String?;
    } catch (e) {
      debugPrint('[NotificationService] Error fetching token: $e');
      return null;
    }
  }

  /// Send push notification via Supabase Edge Function.
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (kIsWeb) return;

    try {
      await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'fcm_token': fcmToken,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      debugPrint('[NotificationService] Push notification sent');
    } catch (e) {
      debugPrint('[NotificationService] Error sending notification: $e');
    }
  }

  /// Handle FCM token refresh — update Supabase with the new token.
  void _onTokenRefresh(String newToken) {
    debugPrint('[NotificationService] Token refreshed: $newToken');

    // Attempt to update using current Supabase auth email
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email != null) {
      upsertFcmToken(email: user!.email!, fcmToken: newToken);
    }
  }

  /// Clear FCM token from Supabase when user signs out (mobile only).
  Future<void> clearFcmToken(String email) async {
    if (kIsWeb) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'fcm_token': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('email', email);
      debugPrint('[NotificationService] FCM token cleared for $email');
    } catch (e) {
      debugPrint('[NotificationService] Error clearing token: $e');
    }
  }
}
