import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/features/auth/auth_repository.dart';
import 'package:talkest/features/auth/screen/login_screen.dart';
import 'package:talkest/features/auth/screen/register_screen.dart';
import 'package:talkest/features/chat/screen/chat_screen.dart';

GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authRepository.currentUser;
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Redirect to login if not authenticated
      if (user == null && !loggingIn) {
        return '/login';
      }

      // Redirect to home if already authenticated and trying to access auth pages
      if (user != null && loggingIn) {
        return '/';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (_, _) => RegisterScreen(),
      ),
      GoRoute(name: 'root', path: '/', builder: (_, _) => ChatScreen()),
    ],
  );
}

/// Helper class to convert Stream to Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
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
