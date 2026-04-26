import 'package:flutter/material.dart';
import 'package:talkest/shared/widgets/markdown_viewer.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Terms of Service")),
      body: SafeArea(
        bottom: true,
        right: false,
        top: false,
        left: false,
        child: MarkdownViewer(
          url:
              "https://raw.githubusercontent.com/Khip01/talkest/refs/heads/main/TERMS.md",
        ),
      ),
    );
  }
}
