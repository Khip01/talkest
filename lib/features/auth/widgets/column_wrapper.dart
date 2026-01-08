import 'package:flutter/material.dart';

class ColumnWrapper extends StatelessWidget {
  final List<Widget> children;
  double spacing;

  ColumnWrapper({super.key, this.spacing = 12, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: children,
    );
  }
}
