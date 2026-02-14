import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorage {
  static Database? _db;

  /// Returns the cached database instance, creating it on first access.
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initializeDB();
    return _db!;
  }

  static Future<Database> _initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'app_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT
          )
          ''',
        );
        await db.execute(
          '''
          CREATE TABLE events(
            id TEXT PRIMARY KEY,
            title TEXT,
            date TEXT
          )
          ''',
        );
      },
      version: 1,
    );
  }

  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  static Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Closes the database connection. Call during app shutdown if needed.
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
