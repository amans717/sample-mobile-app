import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactModel {
  final String id;
  final String displayName;
  final String phoneNumber;
  final String normalizedPhone;
  final Uint8List? photoBytes;
  final DateTime updatedAt;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.normalizedPhone,
    this.photoBytes,
    required this.updatedAt,
  });

  String get initials {
    final clean = displayName.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  factory ContactModel.fromFlutterContact(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    final normalized = phone.replaceAll(RegExp(r'\D'), '');

    return ContactModel(
      id: contact.id,
      displayName: contact.displayName.isNotEmpty ? contact.displayName : 'Unknown Contact',
      phoneNumber: phone,
      normalizedPhone: normalized,
      photoBytes: contact.photo,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'normalized_phone': normalizedPhone,
      'photo_bytes': photoBytes,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ContactModel.fromDatabaseMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      phoneNumber: map['phone_number'] as String,
      normalizedPhone: map['normalized_phone'] as String? ?? '',
      photoBytes: map['photo_bytes'] as Uint8List?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  ContactModel copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    String? normalizedPhone,
    Uint8List? photoBytes,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      photoBytes: photoBytes ?? this.photoBytes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
