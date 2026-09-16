import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/contact_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('crm_contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_contacts (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        normalized_phone TEXT NOT NULL,
        photo_bytes BLOB,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_contacts_name ON cached_contacts(display_name)');
    await db.execute('CREATE INDEX idx_contacts_phone ON cached_contacts(normalized_phone)');
  }

  Future<void> insertOrUpdateContacts(List<ContactModel> contacts) async {
    final db = await database;
    final batch = db.batch();

    for (final contact in contacts) {
      batch.insert(
        'cached_contacts',
        contact.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ContactModel>> getAllContacts() async {
    final db = await database;
    final result = await db.query(
      'cached_contacts',
      orderBy: 'display_name ASC',
    );

    return result.map((json) => ContactModel.fromDatabaseMap(json)).toList();
  }

  Future<List<ContactModel>> searchContacts(String query) async {
    final db = await database;
    final cleanQuery = query.trim().toLowerCase();
    final digitsQuery = query.replaceAll(RegExp(r'\D'), '');

    final result = await db.query(
      'cached_contacts',
      where: 'LOWER(display_name) LIKE ? OR normalized_phone LIKE ?',
      whereArgs: ['%$cleanQuery%', '%$digitsQuery%'],
      orderBy: 'display_name ASC',
    );

    return result.map((json) => ContactModel.fromDatabaseMap(json)).toList();
  }

  Future<int> getContactsCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_contacts'),
    );
    return count ?? 0;
  }

  Future<void> clearContacts() async {
    final db = await database;
    await db.delete('cached_contacts');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
