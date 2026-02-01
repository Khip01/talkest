import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/bloc/contact_list/contact_list_bloc.dart';
import 'package:talkest/features/chat/data/contact_repository.dart';
import 'package:talkest/features/chat/widget/contacts_bottom_sheet.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';
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

  void _showContactsList(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;
    if (currentUser == null) return;

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        enableDrag: true,
        isDismissible: true,
        builder: (_) => BlocProvider(
          create: (context) => ContactListBloc(
            contactRepository: ContactRepository(),
            currentUserId: currentUser.uid,
          )..add(const LoadContacts()),
          child: const ContactsBottomSheet(),
        ),
      );
    });
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
          Text('Start New Chat', style: AppTextStyles.titleLarge),
          const SizedBox(height: 24),

          // Message Box Validation
          validationBox.showWidget(
            margin: EdgeInsets.only(bottom: 16),
            errorBox: (msg) => ErrorMessageBox(
              message: msg,
              isTransparent: true,
              onDismiss: () => setState(() {
                validationBox.state = CustomMessageState.none;
              }),
            ),
          ),

          // Email TextField & Contact List Button
          SizedBox(
            width: 400,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Google email',
                        hintText: 'example@gmail.com',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: const Icon(Icons.email_outlined),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _startChatByEmail(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilledButton.icon(
                    icon: Icon(
                      Icons.perm_contact_calendar_rounded,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    onPressed: () => _showContactsList(context),
                    minWidth: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Get in touch button
          CustomFilledButton.icon(
            onPressed: _isLoading ? null : _startChatByEmail,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble),
            label: _isLoading ? 'Searching...' : 'Get in touch',
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Add via QR Code button
          CustomTextButton.icon(
            onPressed: _isLoading ? null : _openQRScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: "Add via QR Code",
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
