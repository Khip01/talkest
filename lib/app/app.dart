import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/provider/theme_provider.dart';
import 'package:talkest/app/routes.dart';
import 'package:talkest/app/theme/theme.dart';

class TalkestApp extends StatelessWidget {
  const TalkestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Talkest",
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: Provider.of<ThemeProvider>(context).getThemeMode,
    );
  }
}
