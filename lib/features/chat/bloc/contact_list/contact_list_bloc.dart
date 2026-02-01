import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/contact_repository.dart';

part 'contact_list_event.dart';
part 'contact_list_state.dart';

class ContactListBloc extends Bloc<ContactListEvent, ContactListState> {
  final ContactRepository _contactRepository;
  final String _currentUserId;
  StreamSubscription<List<AppUser>>? _contactsSubscription;

  ContactListBloc({
    required ContactRepository contactRepository,
    required String currentUserId,
  }) : _contactRepository = contactRepository,
       _currentUserId = currentUserId,
       super(const ContactListInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<ContactsUpdated>(_onContactsUpdated);
    on<SearchContacts>(_onSearchContacts);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadContacts(
    LoadContacts event,
    Emitter<ContactListState> emit,
  ) async {
    emit(const ContactListLoading());

    try {
      await _contactsSubscription?.cancel();
      _contactsSubscription = _contactRepository
          .getContactUsers(_currentUserId)
          .listen(
            (contacts) {
              add(ContactsUpdated(contacts));
            },
            onError: (error) {
              add(ContactsUpdated([]));
            },
          );
    } catch (e) {
      emit(ContactListError('Failed to load contacts: $e'));
    }
  }

  void _onContactsUpdated(
    ContactsUpdated event,
    Emitter<ContactListState> emit,
  ) {
    if (event.contacts.isEmpty) {
      emit(const ContactListEmpty());
      return;
    }

    final groupedContacts = _groupContactsAlphabetically(event.contacts);

    emit(
      ContactListLoaded(
        allContacts: event.contacts,
        displayedContacts: event.contacts,
        searchQuery: '',
        groupedContacts: groupedContacts,
      ),
    );
  }

  void _onSearchContacts(SearchContacts event, Emitter<ContactListState> emit) {
    final currentState = state;
    if (currentState is! ContactListLoaded) return;

    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      // Show all contacts when search is cleared
      final groupedContacts = _groupContactsAlphabetically(
        currentState.allContacts,
      );
      emit(
        ContactListLoaded(
          allContacts: currentState.allContacts,
          displayedContacts: currentState.allContacts,
          searchQuery: '',
          groupedContacts: groupedContacts,
        ),
      );
      return;
    }

    // Client-side filtering
    final filteredContacts = currentState.allContacts.where((contact) {
      final displayName = contact.displayName.toLowerCase();
      final name = contact.name.toLowerCase();
      final email = contact.email.toLowerCase();

      return displayName.contains(query) ||
          name.contains(query) ||
          email.contains(query);
    }).toList();

    final groupedContacts = _groupContactsAlphabetically(filteredContacts);

    emit(
      ContactListLoaded(
        allContacts: currentState.allContacts,
        displayedContacts: filteredContacts,
        searchQuery: event.query,
        groupedContacts: groupedContacts,
      ),
    );
  }

  void _onClearSearch(ClearSearch event, Emitter<ContactListState> emit) {
    final currentState = state;
    if (currentState is! ContactListLoaded) return;

    final groupedContacts = _groupContactsAlphabetically(
      currentState.allContacts,
    );

    emit(
      ContactListLoaded(
        allContacts: currentState.allContacts,
        displayedContacts: currentState.allContacts,
        searchQuery: '',
        groupedContacts: groupedContacts,
      ),
    );
  }

  /// Group contacts alphabetically with section headers
  Map<String, List<AppUser>> _groupContactsAlphabetically(
    List<AppUser> contacts,
  ) {
    final Map<String, List<AppUser>> grouped = {};

    for (final contact in contacts) {
      final firstChar = contact.displayName.isNotEmpty
          ? contact.displayName[0].toUpperCase()
          : '#';

      // Only use A-Z, others go to '#'
      final key = RegExp(r'^[A-Z]$').hasMatch(firstChar) ? firstChar : '#';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(contact);
    }

    // Sort the keys alphabetically, with '#' at the end
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    final Map<String, List<AppUser>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}
