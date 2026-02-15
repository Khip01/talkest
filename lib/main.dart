import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://ljcwzhfhhhryrrrdsxgp.supabase.co',
    ),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Initialize push notifications (no-op on Web)
  if (!kIsWeb) {
    await NotificationService.instance.initialize();
  }

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
