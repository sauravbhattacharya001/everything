import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorage {
  static Future<Database> initializeDB() async {
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
    final db = await initializeDB();
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await initializeDB();
    return db.query(table);
  }

  static Future<void> delete(String table, String id) async {
    final db = await initializeDB();
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
