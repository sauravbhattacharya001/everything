import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton SQLite database manager for local persistence.
///
/// Provides a shared [Database] instance via the [database] getter,
/// which lazily initializes the database on first access. The database
/// contains two tables:
///
/// - `users` — id (TEXT PK), name (TEXT), email (TEXT)
/// - `events` — id (TEXT PK), title (TEXT), date (TEXT)
///
/// All operations use parameterized queries to prevent SQL injection.
class LocalStorage {
  static Database? _db;

  // Prevent instantiation — all methods are static.
  LocalStorage._();

  /// Returns the cached database instance, creating it on first access.
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initializeDB();
    return _db!;
  }

  static Future<Database> _initializeDB() async {
    final path = await getDatabasesPath();
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
            description TEXT DEFAULT '',
            date TEXT,
            priority TEXT DEFAULT 'medium',
            tags TEXT DEFAULT '[]',
            recurrence TEXT,
            reminders TEXT
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns for existing databases
          await db.execute(
              "ALTER TABLE events ADD COLUMN description TEXT DEFAULT ''");
          await db.execute(
              "ALTER TABLE events ADD COLUMN priority TEXT DEFAULT 'medium'");
        }
        if (oldVersion < 3) {
          // Add tags column (JSON-encoded list of {name, colorIndex})
          await db.execute(
              "ALTER TABLE events ADD COLUMN tags TEXT DEFAULT '[]'");
        }
        if (oldVersion < 4) {
          // Add recurrence column (JSON-encoded RecurrenceRule or null)
          await db.execute(
              "ALTER TABLE events ADD COLUMN recurrence TEXT");
        }
        if (oldVersion < 5) {
          // Add reminders column (JSON-encoded list of ReminderOffset names)
          await db.execute(
              "ALTER TABLE events ADD COLUMN reminders TEXT");
        }
      },
      version: 5,
    );
  }

  /// Inserts or replaces a row in [table].
  ///
  /// Uses [ConflictAlgorithm.replace] so upserting is automatic.
  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns all rows from [table] as a list of JSON-compatible maps.
  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  /// Deletes the row with the given [id] from [table].
  ///
  /// Uses parameterized queries (`whereArgs`) to prevent SQL injection.
  static Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Closes the database connection and clears the cached instance.
  ///
  /// After calling this, the next access to [database] will re-open
  /// the connection. Call during app shutdown or testing teardown.
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
