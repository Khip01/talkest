import 'package:flutter/material.dart';
import 'package:talkest/shared/widgets/markdown_viewer.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Privacy Policy")),
      body: SafeArea(
        bottom: true,
        right: false,
        top: false,
        left: false,
        child: MarkdownViewer(
          url:
              "https://raw.githubusercontent.com/Khip01/talkest/refs/heads/main/PRIVACY.md",
        ),
      ),
    );
  }
}
