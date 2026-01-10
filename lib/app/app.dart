import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/provider/theme_provider.dart';
import 'package:talkest/app/theme/theme.dart';

class TalkestApp extends StatelessWidget {
  final GoRouter router;

  const TalkestApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Talkest",
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: context.watch<ThemeProvider>().getThemeMode,
    );
  }
}
