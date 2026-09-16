import '../core/database/database_helper.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';

class ContactRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ContactService _contactService = ContactService.instance;

  /// Loads cached contacts instantly from SQLite
  Future<List<ContactModel>> getCachedContacts() async {
    return await _dbHelper.getAllContacts();
  }

  /// Syncs device contacts and updates the local SQLite cache
  Future<List<ContactModel>> syncWithDeviceContacts() async {
    final freshContacts = await _contactService.fetchDeviceContacts();
    if (freshContacts.isNotEmpty) {
      await _dbHelper.clearContacts();
      await _dbHelper.insertOrUpdateContacts(freshContacts);
    }
    return await _dbHelper.getAllContacts();
  }

  /// Searches contacts in SQLite by query (name or phone digits)
  Future<List<ContactModel>> searchContacts(String query) async {
    if (query.trim().isEmpty) {
      return await getCachedContacts();
    }
    return await _dbHelper.searchContacts(query);
  }

  /// Returns total count of cached contacts
  Future<int> getTotalContactsCount() async {
    return await _dbHelper.getContactsCount();
  }
}
