import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/features/auth/widgets/column_wrapper.dart';
import 'package:talkest/features/auth/widgets/custom_text_button.dart';
import 'package:talkest/shared/widgets/base_screen_dummy_template.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double scrHeight = MediaQuery.sizeOf(context).height;

    return BaseScreenDummyTemplate(
      body: ColumnWrapper(
        spacing: 60,
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            height: scrHeight / 2,
            child: Text(
              "Welcome to Login Screen! 👋",
              style: AppTextStyles.surfaceHeading3TextStyle,
            ),
          ),
          ColumnWrapper(
            spacing: 12,
            children: [
              CustomFilledButton(
                text: "Login 😃",
                onPressed: () => context.goNamed('root'),
              ),
              CustomTextButton(
                text: "Do register instead :/",
                textStyle: AppTextStyles.linkTextStyle,
                onPressed: () => context.goNamed('register'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
