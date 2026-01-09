import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final TextStyle? textStyle;
  final Color? textColor;
  final Color? overlayColor;
  final double? minWidth;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textStyle,
    this.textColor,
    this.overlayColor,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = textStyle ?? theme.textTheme.bodyMedium!;
    final defaultTextColor = textColor ?? theme.colorScheme.onSurface;
    final defaultOverlayColor =
        overlayColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 400 / 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          overlayColor: defaultOverlayColor.withValues(alpha: .4),
        ),
        child: Text(
          text,
          style: defaultTextStyle.copyWith(color: defaultTextColor),
        ),
      ),
    );
  }
}
