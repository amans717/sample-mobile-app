import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../repositories/contact_repository.dart';

class ContactProvider with ChangeNotifier {
  final ContactRepository _repository = ContactRepository();

  List<ContactModel> _contacts = [];
  List<ContactModel> _filteredContacts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;
  int _totalCount = 0;

  List<ContactModel> get contacts => _filteredContacts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  int get totalCount => _totalCount;

  Future<void> loadContacts({bool forceSync = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Instant load from SQLite cache first
      final cached = await _repository.getCachedContacts();
      if (cached.isNotEmpty) {
        _contacts = cached;
        _totalCount = cached.length;
        _applySearchFilter();
        _isLoading = false;
        notifyListeners();
      }

      // 2. If forced or cache was empty, sync with device
      if (forceSync || cached.isEmpty) {
        final synced = await _repository.syncWithDeviceContacts();
        _contacts = synced;
        _totalCount = synced.length;
        _applySearchFilter();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredContacts = List.from(_contacts);
    } else {
      final q = _searchQuery.toLowerCase().trim();
      final digits = _searchQuery.replaceAll(RegExp(r'\D'), '');

      _filteredContacts = _contacts.where((c) {
        final matchesName = c.displayName.toLowerCase().contains(q);
        final matchesPhone = digits.isNotEmpty && c.normalizedPhone.contains(digits);
        return matchesName || matchesPhone;
      }).toList();
    }
  }
}
