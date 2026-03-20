import 'dart:convert';

/// Generic CRUD service that eliminates the boilerplate duplicated across
/// 20+ tracker services in the app.
///
/// Provides: add, update (by id), remove (by id), getById, clear,
/// JSON export/import, and item count.
///
/// Subclasses must provide [getId], [toJson], and [fromJson] to adapt
/// their model types — no interface changes required on existing models.
///
/// Example:
/// ```dart
/// class CouponTrackerService extends CrudService<CouponEntry> {
///   @override
///   String getId(CouponEntry item) => item.id;
///   @override
///   Map<String, dynamic> toJson(CouponEntry item) => item.toJson();
///   @override
///   CouponEntry fromJson(Map<String, dynamic> json) =>
///       CouponEntry.fromJson(json);
///
///   // ... domain-specific methods only
/// }
/// ```
abstract class CrudService<T> {
  final List<T> _items = [];

  /// Unmodifiable view of all items.
  List<T> get items => List.unmodifiable(_items);

  /// Direct mutable access for subclasses that need custom mutations.
  List<T> get itemsMutable => _items;

  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Extract the unique identifier from an item.
  String getId(T item);

  /// Serialize a single item to JSON.
  Map<String, dynamic> toJson(T item);

  /// Deserialize a single item from JSON.
  T fromJson(Map<String, dynamic> json);

  // ── CRUD ──

  /// Add an item. Returns the added item for chaining.
  T add(T item) {
    _items.add(item);
    return item;
  }

  /// Add multiple items at once.
  void addAll(Iterable<T> newItems) => _items.addAll(newItems);

  /// Update an item by id. Returns true if found and updated.
  bool update(T updated) {
    final updatedId = getId(updated);
    final idx = _items.indexWhere((item) => getId(item) == updatedId);
    if (idx >= 0) {
      _items[idx] = updated;
      return true;
    }
    return false;
  }

  /// Update an item at a specific index. Useful when subclasses already
  /// located the index and want to avoid a second search.
  void updateAt(int index, T updated) {
    _items[index] = updated;
  }

  /// Remove an item by id. Returns true if found and removed.
  bool remove(String id) {
    final idx = _items.indexWhere((item) => getId(item) == id);
    if (idx >= 0) {
      _items.removeAt(idx);
      return true;
    }
    return false;
  }

  /// Remove all items matching a predicate.
  void removeWhere(bool Function(T) test) => _items.removeWhere(test);

  /// Find an item by id, or null if not found.
  T? getById(String id) {
    for (final item in _items) {
      if (getId(item) == id) return item;
    }
    return null;
  }

  /// Find the index of an item by id, or -1 if not found.
  int indexById(String id) => _items.indexWhere((item) => getId(item) == id);

  /// Remove all items.
  void clear() => _items.clear();

  // ── Serialization ──

  /// Export all items to a JSON string.
  String exportToJson() =>
      jsonEncode(_items.map((item) => toJson(item)).toList());

  /// Import items from a JSON string, replacing all current items.
  void importFromJson(String jsonStr) {
    _items.clear();
    final list = jsonDecode(jsonStr) as List;
    _items.addAll(
      list.map((e) => fromJson(e as Map<String, dynamic>)),
    );
  }

  /// Import items from a JSON string, appending to existing items.
  /// Returns the number of items imported.
  int importAndAppend(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    final newItems = list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    _items.addAll(newItems);
    return newItems.length;
  }
}
