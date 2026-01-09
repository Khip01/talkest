import 'package:go_router/go_router.dart';
import 'package:talkest/features/auth/screen/login_screen.dart';
import 'package:talkest/features/auth/screen/register_screen.dart';
import 'package:talkest/features/chat/screen/chat_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  // redirect: (context, state) {
  //   // final user = FirebaseAuth.instance.currentUser;
  //   // final loggingIn = state.matchedLocation == "/login" ||
  //   //     state.matchedLocation == "/register";
  //   //
  //   // if (user == null && !loggingIn) {
  //   //   return "/login";
  //   // }
  //   // if (user != null && loggingIn) {
  //   //   return "/dashboard";
  //   // }
  //   //
  //   // return null;
  // },
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
