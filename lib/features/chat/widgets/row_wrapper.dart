import 'package:flutter/material.dart';

class RowWrapper extends StatelessWidget {
  final List<Widget> children;

  const RowWrapper({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, spacing: 12, children: children);
  }
}
