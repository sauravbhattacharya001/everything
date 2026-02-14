import '../local_storage.dart';

/// Repository for persisting and retrieving user profiles from local storage.
///
/// Mirrors [EventRepository] in structure — a thin domain-specific wrapper
/// over [LocalStorage] for the `users` table.
///
/// Users are stored with columns: `id` (TEXT PK), `name` (TEXT),
/// `email` (TEXT).
class UserRepository {
  /// Saves a user profile to local storage.
  ///
  /// Uses `ConflictAlgorithm.replace`, so calling this with an existing
  /// user ID will update rather than fail.
  Future<void> saveUser(Map<String, dynamic> user) async {
    await LocalStorage.insert('users', user);
  }

  /// Returns all persisted user profiles as raw JSON maps.
  ///
  /// The caller is responsible for deserializing these into [UserModel]
  /// instances via `UserModel.fromJson`.
  Future<List<Map<String, dynamic>>> getUsers() async {
    return await LocalStorage.getAll('users');
  }

  /// Deletes the user with the given [id] from local storage.
  ///
  /// No-op if no user with that ID exists.
  Future<void> deleteUser(String id) async {
    await LocalStorage.delete('users', id);
  }
}
