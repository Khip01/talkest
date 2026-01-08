import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/features/auth/widgets/column_wrapper.dart';
import 'package:talkest/features/auth/widgets/custom_text_button.dart';
import 'package:talkest/features/chat/widgets/row_wrapper.dart';
import 'package:talkest/shared/widgets/base_screen_dummy_template.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
              "Here we are, on List Chat Screen! 🥂",
              style: AppTextStyles.surfaceHeading3TextStyle,
            ),
          ),
          RowWrapper(
            children: [
              CustomFilledButton(
                text: "Let's Chat!",
                minWidth: 0,
                onPressed: () {},
              ),
              CustomTextButton(
                text: "Logout",
                minWidth: 0,
                overlayColor: AppColors.c_156_42_42,
                onPressed: () => context.goNamed('login'),
                textColor: AppColors.c_156_42_42,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
