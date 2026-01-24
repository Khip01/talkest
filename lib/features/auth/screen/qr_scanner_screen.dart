import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final AppUserRemoteDataSource _userRepository = AppUserRemoteDataSource();
  bool _isProcessing = false;
  bool _isMirrored = kIsWeb;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String rawValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Parse QR code
      final data = jsonDecode(rawValue) as Map<String, dynamic>;

      // Validate QR format
      if (data['type'] != 'talkest_user' || data['uid'] == null) {
        _showMessage('Invalid QR code format');
        setState(() => _isProcessing = false);
        return;
      }

      final targetUid = data['uid'] as String;
      final currentUser = context.read<AuthRepository>().currentUser;

      if (currentUser == null) {
        _showMessage('Not authenticated');
        setState(() => _isProcessing = false);
        return;
      }

      // Check if trying to add self
      if (targetUid == currentUser.uid) {
        _showMessage('You cannot add yourself');
        setState(() => _isProcessing = false);
        return;
      }

      // Verify user exists
      final targetUser = await _userRepository.getUserData(targetUid);
      if (targetUser == null) {
        _showMessage('User not found');
        setState(() => _isProcessing = false);
        return;
      }

      // Navigate to chat using GoRouter
      if (mounted) {
        context.pop(); // Close scanner
        context.goNamed('chat_detail', pathParameters: {'id': targetUid});
      }
    } catch (e) {
      _showMessage('Failed to process QR code: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      isUsingBackButton: true,
      customAppBar: AppBar(
        title: Text(
          "Scan QR Profile",
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        titleSpacing: AppScaffold.appBarDefaultConfig.titleSpacing,
        leadingWidth: AppScaffold.appBarDefaultConfig.leadingWidth,
        leading: AppScaffold.appBarDefaultConfig.leading(context),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          if (!kIsWeb)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final bool isTorchOn =
                    _controller.value.torchState == TorchState.on;
                return CustomTextButton.icon(
                  padding: EdgeInsets.zero,
                  minWidth: 0,
                  icon: Icon(
                    Icons.flashlight_on_rounded,
                    color: isTorchOn
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  tooltip: "Turn ${isTorchOn ? "off" : "on"} the flash",
                  onPressed: () => _controller.toggleTorch(),
                );
              },
            ),
          if (!kIsWeb)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final bool isCamFront =
                    _controller.value.cameraDirection == CameraFacing.front;
                return CustomTextButton.icon(
                  padding: EdgeInsets.zero,
                  minWidth: 0,
                  icon: Icon(
                    Icons.flip_camera_ios,
                    color: isCamFront
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  tooltip:
                      "Flip to use the ${isCamFront ? "back" : "front"} camera",
                  onPressed: () => _controller.switchCamera(),
                );
              },
            ),
          CustomTextButton.icon(
            padding: EdgeInsets.zero,
            minWidth: 0,
            icon: Icon(
              Icons.flip,
              color: _isMirrored ? colorScheme.primary : colorScheme.onSurface,
            ),
            tooltip: "Mirror preview",
            onPressed: () => setState(() {
              _isMirrored = !_isMirrored;
            }),
          ),
        ],
      ),
      body: (context, constraints) {
        return Stack(
          children: [
            Transform(
              alignment: Alignment.center,
              transform: _isMirrored
                  ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                  : Matrix4.identity(),
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleQRCode(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
            // Overlay with scanning frame
            Center(
              child: Container(
                width: min(constraints.maxHeight, constraints.maxWidth) * 0.7,
                height: min(constraints.maxHeight, constraints.maxWidth) * 0.7,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Instructions
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Align QR code within the frame',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Processing indicator
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }
}
