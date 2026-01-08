import 'package:flutter/material.dart';
import 'package:talkest/app/theme/theme.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  TextStyle textStyle;
  Color textColor;
  Color overlayColor;
  double? minWidth;

  CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textStyle = AppTextStyles.surfaceBodyTextStyle,
    this.textColor = AppColors.c_0_0_0,
    this.overlayColor = AppColors.c_82_81_82,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 400 / 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          overlayColor: overlayColor.withValues(alpha: .4),
        ),
        child: Text(text, style: textStyle.copyWith(color: textColor)),
      ),
    );
  }
}
