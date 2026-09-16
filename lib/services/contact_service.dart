import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact_model.dart';

class ContactService {
  static final ContactService instance = ContactService._();
  ContactService._();

  Future<List<ContactModel>> fetchDeviceContacts() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      final requested = await Permission.contacts.request();
      if (!requested.isGranted) {
        throw Exception('Contacts permission was denied.');
      }
    }

    final contacts = await FastContacts.getAllContacts();

    final List<ContactModel> contactModels = [];

    for (final contact in contacts) {
      if (contact.phones.isEmpty) continue;

      final primaryPhone = contact.phones.first.number.trim();
      if (primaryPhone.isEmpty) continue;

      contactModels.add(ContactModel.fromFastContact(contact));
    }

    // Sort alphabetically by display name
    contactModels.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return contactModels;
  }
}
