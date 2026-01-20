import 'package:flutter/material.dart';
import 'package:talkest/app/theme/colors.dart';

/// Reusable error message box widget
/// Displays error with icon, message, and optional close button
class ErrorMessageBox extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const ErrorMessageBox({
    super.key,
    required this.message,
    this.onDismiss,
    this.margin,
    this.padding = const EdgeInsets.all(12),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget errorBox = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, color: colorScheme.error, size: 18),
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap with ConstrainedBox if maxWidth is provided
    if (maxWidth != null) {
      errorBox = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: errorBox,
      );
    }

    return errorBox;
  }
}

/// Warning message box variant
class WarningMessageBox extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const WarningMessageBox({
    super.key,
    required this.message,
    this.onDismiss,
    this.margin,
    this.padding = const EdgeInsets.all(12),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget warningBox = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.warningContainerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onWarningContainerColor,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: AppColors.warningColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (maxWidth != null) {
      warningBox = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: warningBox,
      );
    }

    return warningBox;
  }
}

/// Success message box variant
class SuccessMessageBox extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const SuccessMessageBox({
    super.key,
    required this.message,
    this.onDismiss,
    this.margin,
    this.padding = const EdgeInsets.all(12),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget successBox = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.successContainerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.successColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSuccessContainerColor,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: AppColors.successColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (maxWidth != null) {
      successBox = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: successBox,
      );
    }

    return successBox;
  }
}

/// Info message box variant
class InfoMessageBox extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const InfoMessageBox({
    super.key,
    required this.message,
    this.onDismiss,
    this.margin,
    this.padding = const EdgeInsets.all(12),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget infoBox = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.infoContainerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.infoColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onInfoContainerColor,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: AppColors.infoColor, size: 18),
              ),
            ),
          ],
        ],
      ),
    );

    if (maxWidth != null) {
      infoBox = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: infoBox,
      );
    }

    return infoBox;
  }
}

class CustomMessageBox {
  String? message;
  CustomMessageState state = CustomMessageState.none;

  Widget showWidget({
    required ErrorMessageBox Function(String msg) errorBox,
    required WarningMessageBox Function(String msg) warningBox,
    required SuccessMessageBox Function(String msg) successBox,
    required InfoMessageBox Function(String msg) infoBox,
  }) {
    switch (state) {
      case CustomMessageState.none:
        return SizedBox();
      case CustomMessageState.error:
        return errorBox(message ?? "");
      case CustomMessageState.warning:
        return warningBox(message ?? "");
      case CustomMessageState.success:
        return successBox(message ?? "");
      case CustomMessageState.info:
        return infoBox(message ?? "");
    }
  }

  void setValue({required String msg, required CustomMessageState state}) {
    this.message = msg;
    this.state = state;
  }
}

enum CustomMessageState { none, error, warning, success, info }
