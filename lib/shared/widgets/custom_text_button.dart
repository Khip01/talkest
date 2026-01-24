import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final String? tooltip;
  final TextStyle? textStyle;
  final Color? textColor;
  final Color? overlayColor;
  final double? minWidth;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;

  const CustomTextButton._({
    super.key,
    this.text,
    this.icon,
    this.tooltip,
    this.textStyle,
    this.textColor,
    this.overlayColor,
    this.minWidth,
    this.padding,
    this.onPressed,
  });

  factory CustomTextButton.text({
    Key? key,
    required String text,
    Widget? icon,
    double? minWidth,
    EdgeInsets? padding,
    TextStyle? textStyle,
    Color? textColor,
    Color? overlayColor,
    VoidCallback? onPressed,
  }) => CustomTextButton._(
    key: key,
    icon: icon,
    text: text,
    minWidth: minWidth,
    padding: padding,
    textStyle: textStyle,
    textColor: textColor,
    overlayColor: overlayColor,
    onPressed: onPressed,
  );

  factory CustomTextButton.icon({
    Key? key,
    required Widget icon,
    String? label,
    String? tooltip,
    double? minWidth,
    EdgeInsets? padding,
    TextStyle? textStyle,
    Color? textColor,
    Color? overlayColor,
    VoidCallback? onPressed,
  }) => CustomTextButton._(
    key: key,
    icon: icon,
    text: label,
    tooltip: tooltip,
    minWidth: minWidth,
    padding: padding,
    textStyle: textStyle,
    textColor: textColor,
    overlayColor: overlayColor,
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = textStyle ?? theme.textTheme.bodyMedium!;
    final defaultTextColor = textColor ?? theme.colorScheme.onSurface;
    final defaultOverlayColor =
        overlayColor ?? theme.colorScheme.onSurfaceVariant;

    Widget buttonChild;

    if (text != null) {
      buttonChild = TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          overlayColor: defaultOverlayColor.withValues(alpha: .4),
        ),
        icon: icon,
        label: Text(
          text!,
          style: defaultTextStyle.copyWith(color: defaultTextColor),
        ),
      );
    } else if (text == null && icon != null) {
      buttonChild = IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
