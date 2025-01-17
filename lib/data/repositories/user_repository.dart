import '../local_storage.dart';

class UserRepository {
  Future<void> saveUser(Map<String, dynamic> user) async {
    await LocalStorage.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return await LocalStorage.getAll('users');
  }

  Future<void> deleteUser(String id) async {
    await LocalStorage.delete('users', id);
  }
}
