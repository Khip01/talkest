import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/app.dart';
import 'package:talkest/app/provider/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:talkest/app/routes.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize push notifications (no-op on Web)
  await NotificationService.instance.initialize();

  // Initialize AuthRepository and Google Sign-In
  final authRepository = AuthRepository();

  if (kIsWeb) {
    await authRepository.initialize(
      clientId: const String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
      ), // Web Client ID
      // serverClientId: 'SERVER_CLIENT_ID.apps.googleusercontent.com', // Optional for server auth code
    );
  } else {
    /// Mobile (Android & iOS) already handled on google-services.json AND GoogleService-Info.plist
    await authRepository.initialize();
  }

  // Inject router with AuthRepository
  final router = createRouter(authRepository);

  // Listen for notification taps → navigate to chat detail
  if (!kIsWeb) {
    NotificationService.instance.onNotificationTap.listen((targetUserId) {
      debugPrint('[Main] Navigating to chat/$targetUserId from notification');
      router.go('/chat/$targetUserId');
    });

    // Handle terminated state: app was opened from a killed state by a notification tap
    // Delayed slightly to ensure router is fully mounted
    Future.delayed(const Duration(milliseconds: 500), () {
      NotificationService.instance.handleTerminatedLaunch();
    });
  }

  // Initialize ThemeProvider and load saved theme
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider<AuthRepository>.value(value: authRepository),
      ],
      child: TalkestApp(router: router),
    ),
  );
}
