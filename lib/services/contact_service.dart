import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact_model.dart';

class ContactService {
  static final ContactService instance = ContactService._();
  ContactService._();

  Future<List<ContactModel>> fetchDeviceContacts() async {
    final bool permissionGranted = await FlutterContacts.requestPermission(readonly: true);
    if (!permissionGranted) {
      throw Exception('Contacts permission was denied.');
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: true,
      withPhoto: true,
    );

    final List<ContactModel> contactModels = [];

    for (final contact in contacts) {
      if (contact.phones.isEmpty) continue;

      final primaryPhone = contact.phones.first.number.trim();
      if (primaryPhone.isEmpty) continue;

      contactModels.add(ContactModel.fromFlutterContact(contact));
    }

    // Sort alphabetically by display name
    contactModels.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return contactModels;
  }
}
