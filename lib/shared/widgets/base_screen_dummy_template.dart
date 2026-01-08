import 'package:flutter/material.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/shared/utils/utils.dart';

class BaseScreenDummyTemplate extends StatefulWidget {
  final Widget body;

  const BaseScreenDummyTemplate({super.key, required this.body});

  @override
  State<BaseScreenDummyTemplate> createState() =>
      _BaseScreenDummyTemplateState();
}

class _BaseScreenDummyTemplateState extends State<BaseScreenDummyTemplate> {
  String funFact = "";

  @override
  void initState() {
    funFact = getRandomChattingAppTip();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double scrHeight = MediaQuery.sizeOf(context).height;
    final double scrWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Stack(
        children: [
          widget.body,
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: scrHeight / 8,
              horizontal: scrWidth / 6,
            ),
            child: Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: Text(
                "Fun Fact!\n$funFact",
                textAlign: TextAlign.center,
                style: AppTextStyles.quoteTextSTyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
