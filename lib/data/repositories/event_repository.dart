import '../local_storage.dart';

class EventRepository {
  Future<void> saveEvent(Map<String, dynamic> event) async {
    await LocalStorage.insert('events', event);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    return await LocalStorage.getAll('events');
  }

  Future<void> deleteEvent(String id) async {
    await LocalStorage.delete('events', id);
  }
}
