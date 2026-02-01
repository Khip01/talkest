part of 'contact_list_bloc.dart';

abstract class ContactListState extends Equatable {
  const ContactListState();

  @override
  List<Object?> get props => [];
}

class ContactListInitial extends ContactListState {
  const ContactListInitial();
}

class ContactListLoading extends ContactListState {
  const ContactListLoading();
}

class ContactListLoaded extends ContactListState {
  final List<AppUser> allContacts;
  final List<AppUser> displayedContacts;
  final String searchQuery;
  final Map<String, List<AppUser>> groupedContacts;

  const ContactListLoaded({
    required this.allContacts,
    required this.displayedContacts,
    required this.searchQuery,
    required this.groupedContacts,
  });

  bool get isSearching => searchQuery.isNotEmpty;

  @override
  List<Object?> get props => [
    allContacts,
    displayedContacts,
    searchQuery,
    groupedContacts,
  ];
}

class ContactListEmpty extends ContactListState {
  const ContactListEmpty();
}

class ContactListError extends ContactListState {
  final String message;

  const ContactListError(this.message);

  @override
  List<Object?> get props => [message];
}
