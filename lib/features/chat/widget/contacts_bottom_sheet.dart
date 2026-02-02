import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/bloc/contact_list/contact_list_bloc.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';
import 'package:talkest/shared/widgets/custom_text_field.dart';

class ContactsBottomSheet extends StatefulWidget {
  const ContactsBottomSheet({super.key});

  @override
  State<ContactsBottomSheet> createState() => _ContactsBottomSheetState();
}

class _ContactsBottomSheetState extends State<ContactsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final AppUserRemoteDataSource _userRepository = AppUserRemoteDataSource();

  // Hardcoded suggested user UID
  static const String _suggestedUserUid = 'cjFcgpXvUEMWYcAUnq1y5HRlPkr2';
  AppUser? _suggestedUser;
  bool _loadingSuggestedUser = true;

  @override
  void initState() {
    super.initState();
    _fetchSuggestedUser();
  }

  Future<void> _fetchSuggestedUser() async {
    try {
      final user = await _userRepository.getUserData(_suggestedUserUid);
      if (mounted) {
        setState(() {
          _suggestedUser = user;
          _loadingSuggestedUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSuggestedUser = false;
        });
      }
    }
  }

  // End Hardcoded Suggested User

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CustomTextButton.icon(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    minWidth: 0,
                    padding: EdgeInsets.zero,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Contacts",
                    style: AppTextStyles.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomTextField(
                controller: _searchController,
                hintText: "Search by name or email",
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: BlocBuilder<ContactListBloc, ContactListState>(
                  builder: (context, state) {
                    if (state is ContactListLoaded && state.isSearching) {
                      return IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ContactListBloc>().add(
                            const ClearSearch(),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                contentPadding: const EdgeInsets.all(12),
                //   filled: true,
                //   fillColor: colorScheme.surfaceContainerHighest,
                //   border: OutlineInputBorder(
                //     borderRadius: BorderRadius.circular(12),
                //     borderSide: BorderSide.none,
                //   ),
                // ),
                onChanged: (query) {
                  context.read<ContactListBloc>().add(SearchContacts(query));
                },
              ),
            ),

            const SizedBox(height: 16),

            // Contact list
            Expanded(
              child: BlocBuilder<ContactListBloc, ContactListState>(
                builder: (context, state) {
                  if (state is ContactListLoading) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (state is ContactListError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    );
                  }

                  if (state is ContactListEmpty) {
                    // return Center(
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(32),
                    //     child: Column(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Icon(
                    //           Icons.people_outline,
                    //           size: 64,
                    //           color: colorScheme.onSurfaceVariant,
                    //         ),
                    //         const SizedBox(height: 16),
                    //         Text(
                    //           "No contacts yet",
                    //           style: Theme.of(context).textTheme.titleLarge
                    //               ?.copyWith(
                    //                 color: colorScheme.onSurfaceVariant,
                    //               ),
                    //         ),
                    //         const SizedBox(height: 8),
                    //         Text(
                    //           "Start a chat to add contacts",
                    //           style: Theme.of(context).textTheme.bodyMedium
                    //               ?.copyWith(
                    //                 color: colorScheme.onSurfaceVariant,
                    //               ),
                    //           textAlign: TextAlign.center,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // );
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Suggested Users Section
                          Text(
                            "Suggested Users",
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Fetch suggested user from Firestore
                          if (_loadingSuggestedUser)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (_suggestedUser != null)
                            ContactTile(contact: _suggestedUser!)
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Text(
                                'No suggested users',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Your Contacts Section
                          Text(
                            "Your Contacts",
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Alphabetical contact list
                          // _buildAlphabeticalContactList(state),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 64),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No contacts yet",
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Start a chat to add contacts",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ContactListLoaded) {
                    // Show suggested users section when not searching
                    if (!state.isSearching) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Suggested Users Section
                            Text(
                              "Suggested Users",
                              style: AppTextStyles.labelLarge.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Fetch suggested user from Firestore
                            if (_loadingSuggestedUser)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (_suggestedUser != null)
                              ContactTile(contact: _suggestedUser!)
                            else
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No suggested users',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Your Contacts Section
                            Text(
                              "Your Contacts",
                              style: AppTextStyles.labelLarge.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Alphabetical contact list
                            _buildAlphabeticalContactList(state),
                          ],
                        ),
                      );
                    }

                    // Search results
                    if (state.displayedContacts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No results found",
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try a different search term",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Search Results",
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildAlphabeticalContactList(state),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabeticalContactList(ContactListLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.groupedContacts.entries.map((entry) {
        final section = entry.key;
        final contacts = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                section,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),

            // Contacts in this section
            ...contacts.map((contact) => ContactTile(contact: contact)),

            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

class ContactTile extends StatelessWidget {
  final AppUser contact;

  const ContactTile({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // Close bottom sheet and navigate to chat
        context.pop();
        context.goNamed('chat_detail', pathParameters: {'id': contact.uid});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Profile photo
            ClipOval(
              child: contact.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: contact.photoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Contact info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display name
                  Text(
                    contact.displayName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Name with @ prefix
                  Text(
                    contact.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Email
                  Text(
                    contact.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
