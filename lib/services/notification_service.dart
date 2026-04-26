import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.messageId}');
}

/// Handles FCM, local notifications, channel setup, and Supabase token sync.
/// All operations are no-op on Web.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'chat_messages';
  static const _channelName = 'Chat Messages';
  static const _channelDesc = 'Notifications for new chat messages';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentUserUid; // To track current user for token refresh updates

  /// Currently active chat ID — suppress notifications for this chat.
  String? currentActiveChatId;

  /// Stream of targetUserId from notification taps.
  /// Listened by the app shell to navigate via GoRouter.
  final StreamController<String> _notificationTapController =
      StreamController<String>.broadcast();

  Stream<String> get onNotificationTap => _notificationTapController.stream;

  /// Track last navigated targetUserId to prevent duplicate navigations.
  String? _lastNavigatedTargetUserId;
  DateTime? _lastNavigatedTime;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Initialize FCM + local notifications (mobile only).
  /// Requires current user UID to handle token refresh events properly.
  /// Returns the FCM token or null.
  Future<String?> initialize({String? uid}) async {
    debugPrint("[NotificationService] Initializing... status: $_initialized");

    if (kIsWeb) return null;

    if (uid != null) {
      _currentUserUid = uid;
    }

    if (!_initialized) {
      // 1. Create high-priority notification channel
      await _createNotificationChannel();

      // 2. Init flutter_local_notifications with tap callback
      await _initLocalNotifications();

      // 3. Request FCM + Android 13+ notification permission
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('[NotificationService] Permission denied');
        return null;
      }

      // Request Android 13+ POST_NOTIFICATIONS permission
      if (Platform.isAndroid) {
        await _requestAndroid13Permission();
      }

      // 4. Register foreground message handler
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 5. Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 6. Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmMessageTap);

      // 7. Get FCM token & listen for refresh
      messaging.onTokenRefresh.listen(_onTokenRefresh);

      _initialized = true;
    }

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('[NotificationService] Current FCM token: $token');
    return token;
  }

  /// Check if the app was opened from a terminated state by a notification tap.
  /// Call this once after the router is ready.
  Future<void> handleTerminatedLaunch() async {
    if (kIsWeb) return;

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[NotificationService] Terminated launch with message');
      _handleFcmMessageTap(initialMessage);
    }
  }

  /// Show a local notification with targetUserId payload for tap handling.
  Future<void> showNotification({
    required String senderIdentifier,
    required String title,
    required String body,
    String? targetUserId,
  }) async {
    if (kIsWeb) return;

    final notifId = _notificationIdFromSender(senderIdentifier);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Pass targetUserId as payload so tap handler can navigate
    await _localNotifications.show(
      notifId,
      title,
      body,
      details,
      payload: targetUserId,
    );
  }

  /// Dismiss all notifications from a specific sender (e.g. on chat open).
  Future<void> cancelNotificationBySender(String senderIdentifier) async {
    if (kIsWeb) return;

    final notifId = _notificationIdFromSender(senderIdentifier);
    await _localNotifications.cancel(notifId);
    debugPrint('[NotificationService] Cancelled notif for $senderIdentifier');
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _localNotifications.cancelAll();
  }

  /// Upsert FCM token into Firestore 'app_users' collection.
  Future<void> upsertFcmToken({
    required String uid,
    required String fcmToken,
  }) async {
    if (kIsWeb) return;

    try {
      await FirebaseFirestore.instance.collection('app_users').doc(uid).set({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[NotificationService] FCM token upserted for $uid');
    } catch (e) {
      debugPrint('[NotificationService] Error upserting token: $e');
    }
  }

  /// Fetch receiver's FCM token by UID from Firestore.
  Future<String?> getFcmTokenByUid(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_users')
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      return data?['fcmToken'] as String?;
    } catch (e) {
      debugPrint('[NotificationService] Error fetching token: $e');
      return null;
    }
  }

  /// Send push notification via Vercel Serverless Function securely using Firebase ID Token.
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Define URL in run/build command: --dart-define=VERCEL_API_URL=https://...
      const String apiUrl = String.fromEnvironment('VERCEL_API_URL', defaultValue: '');

      if (apiUrl.isEmpty) {
        debugPrint('[NotificationService] WARNING: VERCEL_API_URL is empty. Cannot send push.');
        return;
      }

      /// GET FIREBASE DYNAMIC TOKEN
      // Get the current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[NotificationService] WARNING: No authenticated user. Cannot send push.');
        return;
      }

      // Request a fresh token ID (Firebase will automatically refresh it if it expires)
      final idToken = await currentUser.getIdToken();
      if (idToken == null) {
        debugPrint('[NotificationService] WARNING: Failed to get ID Token.');
        return;
      }

      /// CONTINUE TO PUSH NOTIF
      final uri = Uri.parse('$apiUrl/api/send-notification');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // Bearer token from firebase
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[NotificationService] Push notification sent via Vercel');
      } else {
        debugPrint('[NotificationService] Vercel push failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error sending notification: $e');
    }
  }

  /// Clear FCM token from Firestore on sign-out.
  Future<void> clearFcmToken(String uid) async {
    if (kIsWeb) return;

    try {
      await FirebaseFirestore.instance.collection('app_users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[NotificationService] FCM token cleared for $uid');
    } catch (e) {
      debugPrint('[NotificationService] Error clearing token: $e');
    }
  }

  /// Clean up resources.
  void dispose() {
    _notificationTapController.close();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Create Android notification channel with max importance.
  Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint('[NotificationService] Channel "$_channelId" created');
  }

  /// Init flutter_local_notifications with tap response callback.
  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  /// Handle tap on local notification (foreground-shown notifications).
  void _onLocalNotificationTap(NotificationResponse response) {
    final targetUserId = response.payload;
    if (targetUserId == null || targetUserId.isEmpty) return;

    debugPrint('[NotificationService] Local notif tapped: $targetUserId');
    _emitNavigation(targetUserId);
  }

  /// Handle tap on FCM notification (background/terminated).
  void _handleFcmMessageTap(RemoteMessage message) {
    final targetUserId = message.data['targetUserId'] as String?;
    if (targetUserId == null || targetUserId.isEmpty) return;

    debugPrint('[NotificationService] FCM notif tapped: $targetUserId');
    _emitNavigation(targetUserId);
  }

  /// Emit navigation event with deduplication guard.
  void _emitNavigation(String targetUserId) {
    final now = DateTime.now();

    // Prevent duplicate navigation if same target tapped within 2 seconds
    if (_lastNavigatedTargetUserId == targetUserId &&
        _lastNavigatedTime != null &&
        now.difference(_lastNavigatedTime!).inSeconds < 2) {
      debugPrint('[NotificationService] Duplicate tap ignored');
      return;
    }

    _lastNavigatedTargetUserId = targetUserId;
    _lastNavigatedTime = now;

    _notificationTapController.add(targetUserId);
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+.
  Future<void> _requestAndroid13Permission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    await androidPlugin.requestNotificationsPermission();
  }

  /// Handle foreground FCM: show local notification popup.
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Suppress notification for the currently active chat
    final incomingChatId = message.data['chatId'] as String?;
    if (incomingChatId != null && incomingChatId == currentActiveChatId) {
      debugPrint(
        '[NotificationService] Suppressing notification for active chat',
      );
      return;
    }

    final senderEmail = message.data['senderEmail'] as String? ?? '';
    final targetUserId = message.data['targetUserId'] as String? ?? '';

    showNotification(
      senderIdentifier: senderEmail,
      title: notification.title ?? 'New message',
      body: notification.body ?? '',
      targetUserId: targetUserId,
    );
  }

  /// Handle FCM token refresh. Updates Firestore using the currently tracked UID.
  void _onTokenRefresh(String newToken) {
    debugPrint('[NotificationService] Token refreshed');
    if (_currentUserUid != null) {
      upsertFcmToken(uid: _currentUserUid!, fcmToken: newToken);
    } else {
      debugPrint('[NotificationService] Token refreshed but UID is null. Cannot update Firestore.');
    }
  }

  /// Generate a stable notification ID from sender identifier.
  /// Same sender always maps to the same ID → stacks/replaces.
  int _notificationIdFromSender(String senderIdentifier) {
    if (senderIdentifier.isEmpty) return 0;
    return senderIdentifier.hashCode & 0x7FFFFFFF; // positive 31-bit int
  }
}
