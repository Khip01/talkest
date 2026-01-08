import 'package:flutter/material.dart';
import 'package:talkest/app/routes.dart';

class TalkestApp extends StatelessWidget {
  const TalkestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Talkest",
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
