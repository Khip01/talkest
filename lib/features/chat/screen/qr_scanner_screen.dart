import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final AppUserRemoteDataSource _userRepository = AppUserRemoteDataSource();
  bool _isProcessing = false;

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
        // context.push('/chat/$targetUid');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
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
          // Overlay with scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
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
                color: Colors.black.withOpacity(0.7),
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
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
