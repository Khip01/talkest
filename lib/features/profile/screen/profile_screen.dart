import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/shared/utils/embed_context.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';
import 'package:talkest/shared/widgets/custom_message_box.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';
import 'package:talkest/shared/widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;
  final CustomMessageBox _messageBox = CustomMessageBox();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = context.read<AuthRepository>().currentUser;
    if (currentUser == null) return;

    try {
      final userRepository = AppUserRemoteDataSource();
      final user = await userRepository.getUserData(currentUser.uid);
      if (mounted) {
        setState(() {
          _appUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  void _updateDisplayName(String newDisplayName) async {
    if (_appUser == null) return;

    // Update local state immediately for better UX
    setState(() {
      _appUser = _appUser!.copyWith(
        displayName: newDisplayName,
        updatedAt: DateTime.now(),
      );
    });

    // Save to Firestore
    try {
      final userRepository = AppUserRemoteDataSource();
      await userRepository.updateDisplayName(_appUser!.uid, newDisplayName);

      // Show success message after successful save
      if (mounted) {
        setState(() {
          _messageBox.setValue(
            msg: 'Display name updated successfully!',
            state: CustomMessageState.success,
          );
        });
      }
    } catch (e) {
      // Show error message if save failed
      if (mounted) {
        setState(() {
          _messageBox.setValue(
            msg: 'Failed to update display name. Please try again.',
            state: CustomMessageState.error,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return AppScaffold(
      showProfileIcon: false,
      isUsingBackButton: true,
      customAppBarTitle: Text(
        "Profile",
        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w400),
      ),
      body: (context, constraints) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (_errorMessage != null || _appUser == null) {
          return Center(
            child: ErrorMessageBox(
              message: _errorMessage ?? 'Failed to load profile',
              maxWidth: 300,
            ),
          );
        }

        final appUser = _appUser!;
        final colorScheme = Theme.of(context).colorScheme;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ============================================================
              // HEADER: Avatar + Display Name + Tag
              // ============================================================
              Center(
                child: Column(
                  children: [
                    _ProfileAvatar(
                      photoUrl: appUser.photoUrl,
                      displayName: appUser.displayName,
                    ),
                    const SizedBox(height: 16),
                    // Display Name (yang tampil ke user lain)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appUser.displayName.isNotEmpty
                              ? appUser.displayName
                              : appUser.name,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            "(display name)",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Name sebagai tag (@username style)
                    Text(
                      appUser.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Success/Error notifications
              _messageBox.showWidget(
                margin: const EdgeInsets.only(bottom: 16),
                errorBox: (msg) => ErrorMessageBox(
                  message: msg,
                  onDismiss: () => setState(() {
                    _messageBox.state = CustomMessageState.none;
                  }),
                ),
                successBox: (msg) => SuccessMessageBox(
                  message: msg,
                  onDismiss: () => setState(() {
                    _messageBox.state = CustomMessageState.none;
                  }),
                ),
              ),

              // ============================================================
              // ACTION BUTTONS: QR Code & Edit Display Name
              // ============================================================
              LayoutBuilder(
                builder: (context, constraints) {
                  List<Widget> actionButtons = [
                    CustomFilledButton.icon(
                      icon: Icon(
                        Icons.qr_code_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      label: 'My QR Code',
                      minWidth: 0,
                      onPressed: () => _showQrCodeSheet(context, appUser),
                    ),
                    CustomFilledButton.icon(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 20,
                      ),
                      minWidth: 0,
                      label: 'Edit Display Name',
                      onPressed: () =>
                          _showEditDisplayNameSheet(context, appUser),
                    ),
                  ];

                  if (constraints.maxWidth <= 400) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: actionButtons,
                    );
                  } else {
                    return Row(
                      spacing: 12,
                      children: actionButtons
                          .map((widget) => Expanded(child: widget))
                          .toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // ============================================================
              // ACCOUNT INFO SECTION
              // ============================================================
              Text(
                'Account',
                style: AppTextStyles.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Email
              _AccountInfoItem(label: 'Email', value: appUser.email),

              Divider(
                height: 32,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),

              // Sign-in provider
              _AccountInfoItem(
                label: 'Signed in with',
                value: _capitalizeFirst(appUser.provider),
              ),

              Divider(
                height: 32,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),

              // Member since
              _AccountInfoItem(
                label: 'Member since',
                value: _formatDate(appUser.createdAt),
              ),

              Divider(
                height: 32,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),

              // Last login
              _AccountInfoItem(
                label: 'Last login',
                value: _formatDate(appUser.lastLoginAt),
              ),

              const SizedBox(height: 48),

              // ============================================================
              // LOGOUT
              // ============================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    'Logout',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.4),
                    ),
                    overlayColor: colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  void _showQrCodeSheet(BuildContext context, AppUser appUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      builder: (_) => _QrCodeBottomSheet(appUser: appUser),
    );
  }

  void _showEditDisplayNameSheet(BuildContext context, AppUser appUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      builder: (_) => _EditDisplayNameBottomSheet(
        appUser: appUser,
        onSaved: _updateDisplayName,
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Logout', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          CustomTextButton.text(
            minWidth: 0,
            padding: EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => Navigator.pop(context, false),
            text: "Cancel",
            textStyle: AppTextStyles.labelLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          CustomFilledButton.text(
            text: "Logout",
            minWidth: 0,
            backgroundColor: colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final state = GoRouterState.of(context);

      final embed = EmbedContext.fromUri(
        state.uri,
        pathTargetUid: state.pathParameters['id'],
      );

      await context.read<AuthRepository>().disconnect();
      if (!context.mounted) return;
      if (embed.isValidEmbed) {
        context.goNamed(
          'root',
          queryParameters: {'embed': '1', 'targetUid': embed.targetUid!},
        );
      } else {
        context.goNamed('login');
      }
    }
  }
}

// =============================================================================
// PROFILE AVATAR
// =============================================================================

class _ProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final String displayName;

  const _ProfileAvatar({required this.photoUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    const double size = 88;

    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              _buildPlaceholder(colorScheme, initial, size, isLoading: true),
          errorWidget: (context, url, error) =>
              _buildPlaceholder(colorScheme, initial, size),
        ),
      );
    }

    return _buildPlaceholder(colorScheme, initial, size);
  }

  Widget _buildPlaceholder(
    ColorScheme colorScheme,
    String initial,
    double size, {
    bool isLoading = false,
  }) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primaryContainer,
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Text(
              initial,
              style: AppTextStyles.headlineLarge.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
}

// =============================================================================
// ACCOUNT INFO ITEM
// =============================================================================

class _AccountInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _AccountInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// QR CODE BOTTOM SHEET (Full Screen)
// =============================================================================

class _QrCodeBottomSheet extends StatelessWidget {
  final AppUser appUser;

  const _QrCodeBottomSheet({required this.appUser});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final qrData = jsonEncode({'type': 'talkest_user', 'uid': appUser.uid});

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        color: colorScheme.surface.withValues(alpha: 0.7),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CustomTextButton.icon(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      minWidth: 0,
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My QR Code',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // User info below QR
              Text(
                appUser.displayName.isNotEmpty
                    ? appUser.displayName
                    : appUser.name,
                style: AppTextStyles.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan to start a chat',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EDIT DISPLAY NAME BOTTOM SHEET
// =============================================================================

class _EditDisplayNameBottomSheet extends StatefulWidget {
  final AppUser appUser;
  final Function(String) onSaved;

  const _EditDisplayNameBottomSheet({
    required this.appUser,
    required this.onSaved,
  });

  @override
  State<_EditDisplayNameBottomSheet> createState() =>
      _EditDisplayNameBottomSheetState();
}

class _EditDisplayNameBottomSheetState
    extends State<_EditDisplayNameBottomSheet> {
  late TextEditingController _controller;
  bool _isSaving = false;
  final CustomMessageBox _messageBox = CustomMessageBox();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.appUser.displayName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _messageBox.setValue(
          msg: 'Display name cannot be empty',
          state: CustomMessageState.error,
        );
      });
      return;
    }

    if (newName == widget.appUser.displayName) {
      context.pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _messageBox.state = CustomMessageState.none;
    });

    try {
      final userRepository = AppUserRemoteDataSource();
      await userRepository.updateDisplayName(widget.appUser.uid, newName);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _messageBox.state = CustomMessageState.none;
        });

        widget.onSaved(newName);

        // Auto close after success
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _messageBox.setValue(
            msg: 'Failed to update. Please try again.',
            state: CustomMessageState.error,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        color: colorScheme.surface.withValues(alpha: 0.7),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    CustomTextButton.icon(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      minWidth: 0,
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Display Name',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info text
                Text(
                  'This is how others will see you in chats.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 16),

                // Message Box Validation
                _messageBox.showWidget(
                  margin: const EdgeInsets.only(bottom: 16),
                  errorBox: (msg) => ErrorMessageBox(
                    message: msg,
                    isTransparent: true,
                    onDismiss: () => setState(() {
                      _messageBox.state = CustomMessageState.none;
                    }),
                  ),
                ),

                // Text Field
                CustomTextField(
                  controller: _controller,
                  hintText: 'Enter display name',
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveDisplayName(),
                ),

                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: CustomFilledButton.text(
                    text: _isSaving ? 'Saving...' : 'Save',
                    minWidth: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: _isSaving ? null : _saveDisplayName,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
