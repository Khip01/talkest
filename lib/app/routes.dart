import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/screen/login_screen.dart';
import 'package:talkest/features/chat/bloc/chat_detail/chat_detail_bloc.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/data/message_repository.dart';
import 'package:talkest/features/chat/screen/chat_detail_screen.dart';
import 'package:talkest/features/chat/screen/chat_list_screen.dart';
import 'package:talkest/features/profile/screen/profile_screen.dart';
import 'package:talkest/features/auth/screen/qr_scanner_screen.dart';
import 'package:talkest/shared/widgets/custom_transition.dart';

GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authRepository.currentUser;
      final loggingIn = state.matchedLocation == '/login';

      debugPrint('GoRouter redirect:');
      debugPrint('Current user: ${user?.email ?? 'null'}');
      debugPrint('Current location: ${state.matchedLocation}');
      debugPrint('Logging in page: $loggingIn');

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
        pageBuilder: (context, state) => CustomTransition.fade(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        name: 'root',
        path: '/',
        pageBuilder: (context, state) => CustomTransition.slide(
          context: context,
          state: state,
          child: const ChatListScreen(),
        ),
        routes: [
          GoRoute(
            name: 'chat_detail',
            path: 'chat/:id',
            pageBuilder: (context, state) {
              final String targetUserId = state.pathParameters['id'] ?? '';
              return CustomTransition.slideFade(
                context: context,
                state: state,
                child: BlocProvider(
                  create: (context) => ChatDetailBloc(
                    authRepository: context.read<AuthRepository>(),
                    chatRepository: ChatRepository(),
                    messageRepository: MessageRepository(),
                    userRepository: AppUserRemoteDataSource(),
                  ),
                  child: ChatDetailScreen(targetUserId: targetUserId),
                ),
              );
            },
          ),
          GoRoute(
            name: 'qr_scan',
            path: 's',
            pageBuilder: (context, state) => CustomTransition.none(
              state: state,
              child: const QRScannerScreen(),
            ),
          ),
          GoRoute(
            name: 'profile',
            path: '/profile',
            pageBuilder: (context, state) => CustomTransition.none(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Helper class to convert Stream to Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((event) {
      debugPrint('Auth state changed: $event');
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
