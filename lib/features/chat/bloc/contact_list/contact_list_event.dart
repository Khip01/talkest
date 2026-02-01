part of 'contact_list_bloc.dart';

abstract class ContactListEvent extends Equatable {
  const ContactListEvent();

  @override
  List<Object?> get props => [];
}

class LoadContacts extends ContactListEvent {
  const LoadContacts();
}

class ContactsUpdated extends ContactListEvent {
  final List<AppUser> contacts;

  const ContactsUpdated(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

class SearchContacts extends ContactListEvent {
  final String query;

  const SearchContacts(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends ContactListEvent {
  const ClearSearch();
}
