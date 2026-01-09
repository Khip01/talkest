import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Color? backgroundColor;
  final double? minWidth;

  const CustomFilledButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 400 / 2),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          backgroundColor: defaultBackgroundColor,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
