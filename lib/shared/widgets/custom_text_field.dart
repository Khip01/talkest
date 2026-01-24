import 'package:flutter/material.dart';
import 'package:talkest/app/theme/text_styles.dart';

/// Reusable TextField widget with consistent styling across the app
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool obscureText;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.obscureText = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      enabled: enabled,
      style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: prefixIcon,
              )
            : null,
        suffixIcon: suffixIcon,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}
