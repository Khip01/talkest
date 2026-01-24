import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {
  final Widget? icon;
  final String? text;
  final Color? backgroundColor;
  final double? minWidth;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;

  const CustomFilledButton._({
    super.key,
    this.icon,
    this.text,
    this.backgroundColor,
    this.minWidth,
    this.padding,
    this.onPressed,
  });

  factory CustomFilledButton.text({
    Key? key,
    Widget? icon,
    required String text,
    Color? backgroundColor,
    double? minWidth,
    EdgeInsets? padding,
    VoidCallback? onPressed,
  }) =>
      CustomFilledButton._(
        key: key,
        icon: icon,
        text: text,
        backgroundColor: backgroundColor,
        minWidth: minWidth,
        padding: padding,
        onPressed: onPressed,
      );

  factory CustomFilledButton.icon({
    Key? key,
    required Widget icon,
    String? label,
    Color? backgroundColor,
    double? minWidth,
    EdgeInsets? padding,
    VoidCallback? onPressed,
  }) =>
      CustomFilledButton._(
        key: key,
        icon: icon,
        text: label,
        backgroundColor: backgroundColor,
        minWidth: minWidth,
        padding: padding,
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.colorScheme.primary;

    Widget buttonChild;

    if (text != null) {
      buttonChild = FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
          backgroundColor: defaultBackgroundColor,
        ),
        icon: icon,
        label: Text(
          text!,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      );
    } else if (text == null && icon != null) {
      buttonChild = IconButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
          backgroundColor: defaultBackgroundColor,
        ),
        icon: icon!,
      );
    } else {
      buttonChild = SizedBox(); // unreachable code
    }

    return Container(
        constraints: BoxConstraints(minWidth: minWidth ?? 400 / 2),
        child: buttonChild,
    );
  }
}
