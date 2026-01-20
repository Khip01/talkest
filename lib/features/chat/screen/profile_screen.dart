import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final userRepository = AppUserRemoteDataSource();

    return AppScaffold(
      customAppBarTitle: Text(
        "Profile",
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),
      body: (context, constraints) {
        return FutureBuilder<AppUser?>(
          future: userRepository.getUserData(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to load profile'));
            }

            final appUser = snapshot.data!;

            // Generate QR code data
            final qrData = jsonEncode({
              'type': 'talkest_user',
              'uid': appUser.uid,
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Photo
                  appUser.photoUrl.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: appUser.photoUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 60,
                              child: Text(
                                appUser.displayName.isNotEmpty
                                    ? appUser.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 60,
                          child: Text(
                            appUser.displayName.isNotEmpty
                                ? appUser.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Profile Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name (read-only)
                          _ProfileField(
                            label: 'Name',
                            value: appUser.name,
                            icon: Icons.person,
                            isReadOnly: true,
                          ),
                          const Divider(height: 24),

                          // Display Name
                          _ProfileField(
                            label: 'Display Name',
                            value: appUser.displayName,
                            icon: Icons.badge,
                            isReadOnly: false,
                          ),
                          const Divider(height: 24),

                          // Email (read-only)
                          _ProfileField(
                            label: 'Email',
                            value: appUser.email,
                            icon: Icons.email,
                            isReadOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // QR Code Section
                  Text(
                    'My QR Code',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 200,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Others can scan this to start a chat with you',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await context.read<AuthRepository>().disconnect();
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isReadOnly;

  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        if (isReadOnly)
          Icon(
            Icons.lock_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}
