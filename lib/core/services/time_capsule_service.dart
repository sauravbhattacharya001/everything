import '../../models/time_capsule_entry.dart';
import 'storage_backend.dart';

/// Service for managing time capsules with local persistence.
class TimeCapsuleService {
  static const String _storageKey = 'time_capsule_entries';
  List<TimeCapsuleEntry> _entries = [];
  bool _initialized = false;

  List<TimeCapsuleEntry> get entries => List.unmodifiable(_entries);
  int get totalCapsules => _entries.length;
  int get lockedCount => _entries.where((e) => !e.isUnlocked).length;
  int get readyToOpenCount => _entries.where((e) => e.canOpen).length;
  int get openedCount => _entries.where((e) => e.isOpened).length;

  Future<void> init() async {
    if (_initialized) return;
    final data = await StorageBackend.read(_storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = TimeCapsuleEntry.decodeList(data);
    }
    _entries.sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    _initialized = true;
  }

  Future<void> _save() async {
    await StorageBackend.write(_storageKey, TimeCapsuleEntry.encodeList(_entries));
  }

  /// Create a new time capsule.
  Future<void> addCapsule(TimeCapsuleEntry capsule) async {
    await init();
    _entries.add(capsule);
    _entries.sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    await _save();
  }

  /// Open a capsule (marks it as opened).
  Future<TimeCapsuleEntry?> openCapsule(String id) async {
    await init();
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    final entry = _entries[idx];
    if (!entry.isUnlocked) return null;
    final opened = entry.copyWith(isOpened: true, openedAt: DateTime.now());
    _entries[idx] = opened;
    await _save();
    return opened;
  }

  /// Delete a capsule.
  Future<bool> deleteCapsule(String id) async {
    await init();
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length < before) {
      await _save();
      return true;
    }
    return false;
  }

  /// Get capsules grouped by status.
  List<TimeCapsuleEntry> get locked =>
      _entries.where((e) => !e.isUnlocked).toList();

  List<TimeCapsuleEntry> get readyToOpen =>
      _entries.where((e) => e.canOpen).toList();

  List<TimeCapsuleEntry> get opened =>
      _entries.where((e) => e.isOpened).toList();
}
