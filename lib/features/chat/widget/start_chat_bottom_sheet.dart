import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/screen/qr_scanner_screen.dart';
import 'package:talkest/shared/widgets/custom_message_box.dart';

class StartChatBottomSheet extends StatefulWidget {
  const StartChatBottomSheet({super.key});

  @override
  State<StartChatBottomSheet> createState() => _StartChatBottomSheetState();
}

class _StartChatBottomSheetState extends State<StartChatBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final AppUserRemoteDataSource _userRepository = AppUserRemoteDataSource();
  bool _isLoading = false;
  final CustomMessageBox validationBox = CustomMessageBox();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _startChatByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      // _showMessage('Please enter an email address');
      setState(() {
        validationBox.setValue(
          msg: "Please enter an email address",
          state: CustomMessageState.error,
        );
      });
      return;
    }

    final currentUser = context.read<AuthRepository>().currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Query Firestore by email
      final AppUser? targetUser = await _userRepository.getUserByEmail(email);

      if (targetUser == null) {
        // _showMessage('User not found. Please check the email.');
        validationBox.setValue(
          msg: "User not found. Please check the email.",
          state: CustomMessageState.error,
        );
        return;
      }

      // Check if trying to chat with self
      if (targetUser.uid == currentUser.uid) {
        setState(() {
          validationBox.setValue(
            msg: "You cannot start a chat with yourself.",
            state: CustomMessageState.error,
          );
        });
        return;
      }

      // Close bottom sheet and navigate using path parameter
      if (mounted) {
        context.pop(context); // Close bottom sheet first
        // context.push(
        //   '/chat/${targetUser.uid}',
        // ); // Use push instead of pushNamed
        context.goNamed('chat_detail', pathParameters: {'id': targetUser.uid});
      }
    } catch (e) {
      // _showMessage('Failed to start chat: $e');
      debugPrint("Failed to start chat: $e");
      setState(() {
        validationBox.setValue(
          msg: "Failed to start chat",
          state: CustomMessageState.error,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openQRScanner() async {
    context.pop(context);
    context.goNamed('qr_scan');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Start New Chat',
            style: AppTextStyles.titleLarge,
            // textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Message Box Validation
          validationBox.showWidget(
            errorBox: (msg) => ErrorMessageBox(message: msg),
            warningBox: (msg) => WarningMessageBox(message: msg),
            successBox: (msg) => SuccessMessageBox(message: msg),
            infoBox: (msg) => InfoMessageBox(message: msg),
          ),
          const SizedBox(height: 16),

          // Email TextField
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Google email',
              hintText: 'example@gmail.com',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Icon(Icons.email_outlined),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _startChatByEmail(),
          ),
          const SizedBox(height: 16),

          // Get in touch button
          FilledButton.icon(
            onPressed: _isLoading ? null : _startChatByEmail,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble),
            label: Text(_isLoading ? 'Searching...' : 'Get in touch'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Add via QR Code button
          TextButton.icon(
            onPressed: _isLoading ? null : _openQRScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Add via QR Code'),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
