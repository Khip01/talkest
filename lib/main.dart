import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/app.dart';
import 'package:talkest/app/provider/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: TalkestApp(),
    ),
  );
}
