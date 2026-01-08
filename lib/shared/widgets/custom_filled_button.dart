import 'package:flutter/material.dart';
import 'package:talkest/app/theme/theme.dart';

class CustomFilledButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  Color backgroundColor;
  double? minWidth;

  CustomFilledButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor = AppColors.c_0_0_0,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 400 / 2,
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          backgroundColor: backgroundColor,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.onSurfaceTextStyle,
        ),
      ),
    );
  }
}
