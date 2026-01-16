import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/features/auth/auth_repository.dart';
import 'package:talkest/features/auth/screen/login_screen.dart';
import 'package:talkest/features/chat/screen/list_chat_screen.dart';

GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authRepository.currentUser;
      final loggingIn = state.matchedLocation == '/login';

      debugPrint('🔀 GoRouter redirect:');
      debugPrint('   Current user: ${user?.email ?? 'null'}');
      debugPrint('   Current location: ${state.matchedLocation}');
      debugPrint('   Logging in page: $loggingIn');

      // Redirect to login if not authenticated
      if (user == null && !loggingIn) {
        debugPrint('   > Redirecting to /login (not authenticated)');
        return '/login';
      }

      // Redirect to home if already authenticated and trying to access auth pages
      if (user != null && loggingIn) {
        debugPrint('   > Redirecting to / (already authenticated)');
        return '/';
      }

      debugPrint('   > No redirect needed');
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(name: 'root', path: '/', builder: (_, _) => ListChatScreen()),
    ],
  );
}

/// Helper class to convert Stream to Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((event) {
      debugPrint('🔔 Auth state changed: $event');
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
