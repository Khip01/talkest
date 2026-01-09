import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/features/auth/widgets/column_wrapper.dart';
import 'package:talkest/features/auth/widgets/custom_text_button.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: (context, constraints) {
        return Center(
          child: ColumnWrapper(
            spacing: 60,
            children: [
              Text(
                "Oh, hello Register Screen! 👀",
                style: AppTextStyles.titleMedium,
              ),
              ColumnWrapper(
                spacing: 12,
                children: [
                  CustomFilledButton(
                    text: "Register 📜",
                    onPressed: () => context.goNamed('root'),
                  ),
                  CustomTextButton(
                    text: "Do login instead :)",
                    textStyle: AppTextStyles.link,
                    onPressed: () => context.goNamed('login'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
