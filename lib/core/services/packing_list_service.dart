/// Packing List Service — create, manage, and reuse packing lists with
/// trip-type templates, weight tracking, and progress monitoring.

import 'dart:convert';
import '../../models/packing_item.dart';

// ── Template Data ─────────────────────────────────────────────────────

/// Built-in packing suggestions by template type.
const Map<PackingTemplateType, List<_TemplateItem>> _builtInTemplates = {
  PackingTemplateType.beach: [
    _TemplateItem('Swimsuit', PackingCategory.clothing, PackingPriority.essential, 200),
    _TemplateItem('Sunscreen', PackingCategory.toiletries, PackingPriority.essential, 150),
    _TemplateItem('Sunglasses', PackingCategory.accessories, PackingPriority.essential, 30),
    _TemplateItem('Beach towel', PackingCategory.accessories, PackingPriority.essential, 500),
    _TemplateItem('Flip flops', PackingCategory.clothing, PackingPriority.essential, 300),
    _TemplateItem('Hat', PackingCategory.accessories, PackingPriority.important, 100),
    _TemplateItem('Light dress/shorts', PackingCategory.clothing, PackingPriority.important, 200),
    _TemplateItem('Aloe vera gel', PackingCategory.toiletries, PackingPriority.optional, 100),
    _TemplateItem('Snorkel gear', PackingCategory.entertainment, PackingPriority.optional, 400),
    _TemplateItem('Waterproof phone case', PackingCategory.electronics, PackingPriority.optional, 50),
  ],
  PackingTemplateType.business: [
    _TemplateItem('Suit/blazer', PackingCategory.clothing, PackingPriority.essential, 1200),
    _TemplateItem('Dress shoes', PackingCategory.clothing, PackingPriority.essential, 800),
    _TemplateItem('Dress shirts', PackingCategory.clothing, PackingPriority.essential, 250),
    _TemplateItem('Laptop', PackingCategory.electronics, PackingPriority.essential, 1500),
    _TemplateItem('Laptop charger', PackingCategory.electronics, PackingPriority.essential, 300),
    _TemplateItem('Business cards', PackingCategory.documents, PackingPriority.important, 30),
    _TemplateItem('Notebook & pen', PackingCategory.accessories, PackingPriority.important, 200),
    _TemplateItem('Tie/scarf', PackingCategory.accessories, PackingPriority.important, 100),
    _TemplateItem('Portable charger', PackingCategory.electronics, PackingPriority.optional, 200),
    _TemplateItem('Travel iron', PackingCategory.accessories, PackingPriority.optional, 500),
  ],
  PackingTemplateType.camping: [
    _TemplateItem('Tent', PackingCategory.accessories, PackingPriority.essential, 3000),
    _TemplateItem('Sleeping bag', PackingCategory.accessories, PackingPriority.essential, 1500),
    _TemplateItem('Sleeping pad', PackingCategory.accessories, PackingPriority.essential, 500),
    _TemplateItem('Headlamp', PackingCategory.electronics, PackingPriority.essential, 100),
    _TemplateItem('First aid kit', PackingCategory.medications, PackingPriority.essential, 300),
    _TemplateItem('Water bottle', PackingCategory.food, PackingPriority.essential, 200),
    _TemplateItem('Camp stove', PackingCategory.food, PackingPriority.important, 800),
    _TemplateItem('Insect repellent', PackingCategory.toiletries, PackingPriority.important, 100),
    _TemplateItem('Multi-tool', PackingCategory.accessories, PackingPriority.important, 200),
    _TemplateItem('Hiking boots', PackingCategory.clothing, PackingPriority.essential, 900),
    _TemplateItem('Rain jacket', PackingCategory.clothing, PackingPriority.important, 400),
    _TemplateItem('Firestarter', PackingCategory.accessories, PackingPriority.optional, 50),
  ],
  PackingTemplateType.winter: [
    _TemplateItem('Winter coat', PackingCategory.clothing, PackingPriority.essential, 1500),
    _TemplateItem('Thermal underwear', PackingCategory.clothing, PackingPriority.essential, 300),
    _TemplateItem('Wool socks', PackingCategory.clothing, PackingPriority.essential, 80),
    _TemplateItem('Gloves', PackingCategory.accessories, PackingPriority.essential, 150),
    _TemplateItem('Scarf', PackingCategory.accessories, PackingPriority.essential, 200),
    _TemplateItem('Beanie', PackingCategory.accessories, PackingPriority.essential, 80),
    _TemplateItem('Snow boots', PackingCategory.clothing, PackingPriority.essential, 1200),
    _TemplateItem('Lip balm', PackingCategory.toiletries, PackingPriority.important, 10),
    _TemplateItem('Hand warmers', PackingCategory.accessories, PackingPriority.optional, 50),
    _TemplateItem('Ski goggles', PackingCategory.accessories, PackingPriority.optional, 200),
  ],
  PackingTemplateType.backpacking: [
    _TemplateItem('Backpack (40-65L)', PackingCategory.accessories, PackingPriority.essential, 1500),
    _TemplateItem('Quick-dry clothes', PackingCategory.clothing, PackingPriority.essential, 300),
    _TemplateItem('Travel towel', PackingCategory.toiletries, PackingPriority.essential, 150),
    _TemplateItem('Passport', PackingCategory.documents, PackingPriority.essential, 50),
    _TemplateItem('Travel insurance docs', PackingCategory.documents, PackingPriority.essential, 10),
    _TemplateItem('Padlock', PackingCategory.accessories, PackingPriority.important, 100),
    _TemplateItem('Universal adapter', PackingCategory.electronics, PackingPriority.important, 120),
    _TemplateItem('Packing cubes', PackingCategory.accessories, PackingPriority.important, 200),
    _TemplateItem('Dry bag', PackingCategory.accessories, PackingPriority.optional, 100),
    _TemplateItem('Clothesline', PackingCategory.accessories, PackingPriority.optional, 30),
  ],
  PackingTemplateType.weekend: [
    _TemplateItem('Change of clothes', PackingCategory.clothing, PackingPriority.essential, 500),
    _TemplateItem('Toiletry bag', PackingCategory.toiletries, PackingPriority.essential, 300),
    _TemplateItem('Phone charger', PackingCategory.electronics, PackingPriority.essential, 50),
    _TemplateItem('Wallet/ID', PackingCategory.documents, PackingPriority.essential, 50),
    _TemplateItem('Sleepwear', PackingCategory.clothing, PackingPriority.important, 200),
    _TemplateItem('Snacks', PackingCategory.food, PackingPriority.optional, 200),
    _TemplateItem('Book/Kindle', PackingCategory.entertainment, PackingPriority.optional, 200),
  ],
  PackingTemplateType.family: [
    _TemplateItem('Kids clothes', PackingCategory.clothing, PackingPriority.essential, 500),
    _TemplateItem('Diapers/wipes', PackingCategory.toiletries, PackingPriority.essential, 400),
    _TemplateItem('Snacks', PackingCategory.food, PackingPriority.essential, 300),
    _TemplateItem('Car seat', PackingCategory.accessories, PackingPriority.essential, 5000),
    _TemplateItem('Stroller', PackingCategory.accessories, PackingPriority.important, 7000),
    _TemplateItem('Toys/games', PackingCategory.entertainment, PackingPriority.important, 500),
    _TemplateItem('First aid kit', PackingCategory.medications, PackingPriority.important, 300),
    _TemplateItem('Tablet with movies', PackingCategory.electronics, PackingPriority.optional, 500),
    _TemplateItem('Baby monitor', PackingCategory.electronics, PackingPriority.optional, 200),
  ],
};

/// Common essentials added to every list regardless of template.
const List<_TemplateItem> _universalEssentials = [
  _TemplateItem('Underwear', PackingCategory.clothing, PackingPriority.essential, 60),
  _TemplateItem('Socks', PackingCategory.clothing, PackingPriority.essential, 40),
  _TemplateItem('T-shirts', PackingCategory.clothing, PackingPriority.essential, 150),
  _TemplateItem('Toothbrush & paste', PackingCategory.toiletries, PackingPriority.essential, 80),
  _TemplateItem('Deodorant', PackingCategory.toiletries, PackingPriority.essential, 70),
  _TemplateItem('Phone charger', PackingCategory.electronics, PackingPriority.essential, 50),
  _TemplateItem('Medications', PackingCategory.medications, PackingPriority.essential, 50),
  _TemplateItem('ID/passport', PackingCategory.documents, PackingPriority.essential, 50),
];

class _TemplateItem {
  final String name;
  final PackingCategory category;
  final PackingPriority priority;
  final double weightGrams;
  const _TemplateItem(this.name, this.category, this.priority, this.weightGrams);
}

// ── Result Classes ────────────────────────────────────────────────────

/// Summary statistics across all packing lists.
class PackingSummary {
  final int totalLists;
  final int activeLists;
  final int archivedLists;
  final int fullyPackedLists;
  final int totalItems;
  final int packedItems;
  final double overallProgressPercent;
  final double totalWeightKg;
  final Map<PackingCategory, int> itemsByCategory;
  final PackingList? nextDeparture;

  const PackingSummary({
    required this.totalLists,
    required this.activeLists,
    required this.archivedLists,
    required this.fullyPackedLists,
    required this.totalItems,
    required this.packedItems,
    required this.overallProgressPercent,
    required this.totalWeightKg,
    required this.itemsByCategory,
    this.nextDeparture,
  });
}

/// Weight breakdown by category.
class WeightBreakdown {
  final double totalWeightKg;
  final Map<PackingCategory, double> byCategory;
  final String heaviestItem;
  final double heaviestItemWeightGrams;
  final int itemsWithoutWeight;

  const WeightBreakdown({
    required this.totalWeightKg,
    required this.byCategory,
    required this.heaviestItem,
    required this.heaviestItemWeightGrams,
    required this.itemsWithoutWeight,
  });
}

/// Packing readiness check.
class ReadinessCheck {
  final String listName;
  final double progressPercent;
  final List<PackingItem> essentialUnpacked;
  final List<PackingItem> importantUnpacked;
  final List<PackingItem> optionalUnpacked;
  final bool isReady;
  final int daysUntilDeparture;

  const ReadinessCheck({
    required this.listName,
    required this.progressPercent,
    required this.essentialUnpacked,
    required this.importantUnpacked,
    required this.optionalUnpacked,
    required this.isReady,
    required this.daysUntilDeparture,
  });
}

// ── Service ───────────────────────────────────────────────────────────

/// Main service for packing list management.
class PackingListService {
  final List<PackingList> _lists;
  int _nextId;

  PackingListService({List<PackingList>? lists})
      : _lists = lists ?? [],
        _nextId = 1;

  List<PackingList> get allLists => List.unmodifiable(_lists);
  List<PackingList> get activeLists =>
      _lists.where((l) => !l.isArchived).toList();
  List<PackingList> get archivedLists =>
      _lists.where((l) => l.isArchived).toList();

  String _genId() => 'pkg_${_nextId++}_${DateTime.now().millisecondsSinceEpoch}';

  // ── CRUD ──────────────────────────────────────────────────────

  /// Create a new packing list from a template.
  /// Populates universal essentials + template-specific items.
  /// For multi-day trips, adjusts clothing quantities.
  PackingList createFromTemplate({
    required String name,
    required PackingTemplateType templateType,
    int tripDays = 1,
    DateTime? departureDate,
  }) {
    final items = <PackingItem>[];
    final addedNames = <String>{};

    // Add universal essentials first
    for (final t in _universalEssentials) {
      int qty = 1;
      // Scale clothing by trip days
      if (t.category == PackingCategory.clothing && tripDays > 1) {
        qty = tripDays;
      }
      items.add(PackingItem(
        id: _genId(),
        name: t.name,
        category: t.category,
        priority: t.priority,
        quantity: qty,
        weightGrams: t.weightGrams,
      ));
      addedNames.add(t.name.toLowerCase());
    }

    // Add template-specific items (skip duplicates)
    final templateItems = _builtInTemplates[templateType] ?? [];
    for (final t in templateItems) {
      if (addedNames.contains(t.name.toLowerCase())) continue;
      items.add(PackingItem(
        id: _genId(),
        name: t.name,
        category: t.category,
        priority: t.priority,
        quantity: 1,
        weightGrams: t.weightGrams,
      ));
      addedNames.add(t.name.toLowerCase());
    }

    final list = PackingList(
      id: _genId(),
      name: name,
      templateType: templateType,
      tripDays: tripDays,
      createdAt: DateTime.now(),
      departureDate: departureDate,
      items: items,
    );
    _lists.add(list);
    return list;
  }

  /// Create an empty packing list.
  PackingList createEmpty({required String name, DateTime? departureDate}) {
    final list = PackingList(
      id: _genId(),
      name: name,
      templateType: PackingTemplateType.custom,
      createdAt: DateTime.now(),
      departureDate: departureDate,
    );
    _lists.add(list);
    return list;
  }

  /// Get a list by ID.
  PackingList? getList(String listId) {
    for (final l in _lists) {
      if (l.id == listId) return l;
    }
    return null;
  }

  /// Delete a list.
  bool deleteList(String listId) {
    final before = _lists.length;
    _lists.removeWhere((l) => l.id == listId);
    return _lists.length < before;
  }

  /// Archive a list (mark as done/past trip).
  PackingList? archiveList(String listId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return null;
    final updated = _lists[idx].copyWith(isArchived: true);
    _lists[idx] = updated;
    return updated;
  }

  /// Unarchive a list.
  PackingList? unarchiveList(String listId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return null;
    final updated = _lists[idx].copyWith(isArchived: false);
    _lists[idx] = updated;
    return updated;
  }

  // ── Item Management ───────────────────────────────────────────

  /// Add an item to a list.
  PackingItem? addItem(String listId, {
    required String name,
    required PackingCategory category,
    PackingPriority priority = PackingPriority.important,
    int quantity = 1,
    double? weightGrams,
    String? notes,
  }) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return null;
    final item = PackingItem(
      id: _genId(),
      name: name,
      category: category,
      priority: priority,
      quantity: quantity,
      weightGrams: weightGrams,
      notes: notes,
    );
    final updated = _lists[idx].copyWith(
      items: [..._lists[idx].items, item],
    );
    _lists[idx] = updated;
    return item;
  }

  /// Remove an item from a list.
  bool removeItem(String listId, String itemId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return false;
    final newItems = _lists[idx].items.where((i) => i.id != itemId).toList();
    if (newItems.length == _lists[idx].items.length) return false;
    _lists[idx] = _lists[idx].copyWith(items: newItems);
    return true;
  }

  /// Toggle an item's packed status.
  PackingItem? togglePacked(String listId, String itemId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return null;
    final items = _lists[idx].items.toList();
    final itemIdx = items.indexWhere((i) => i.id == itemId);
    if (itemIdx < 0) return null;
    final toggled = items[itemIdx].copyWith(isPacked: !items[itemIdx].isPacked);
    items[itemIdx] = toggled;
    _lists[idx] = _lists[idx].copyWith(items: items);
    return toggled;
  }

  /// Mark all items as packed.
  PackingList? packAll(String listId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return null;
    final items = _lists[idx].items.map((i) => i.copyWith(isPacked: true)).toList();
    _lists[idx] = _lists[idx].copyWith(items: items);
    return _lists[idx];
  }

  /// Unpack all items (reset).
  PackingList? unpackAll(String listId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return null;
    final items = _lists[idx].items.map((i) => i.copyWith(isPacked: false)).toList();
    _lists[idx] = _lists[idx].copyWith(items: items);
    return _lists[idx];
  }

  // ── Duplicate / Reuse ─────────────────────────────────────────

  /// Duplicate a list (all items unpacked) for a new trip.
  PackingList? duplicateList(String listId, {required String newName, DateTime? departureDate}) {
    final source = getList(listId);
    if (source == null) return null;
    final newItems = source.items.map((i) => PackingItem(
      id: _genId(),
      name: i.name,
      category: i.category,
      priority: i.priority,
      quantity: i.quantity,
      weightGrams: i.weightGrams,
      isPacked: false,
      notes: i.notes,
    )).toList();
    final newList = PackingList(
      id: _genId(),
      name: newName,
      templateType: source.templateType,
      tripDays: source.tripDays,
      createdAt: DateTime.now(),
      departureDate: departureDate,
      items: newItems,
    );
    _lists.add(newList);
    return newList;
  }

  // ── Analytics ─────────────────────────────────────────────────

  /// Get weight breakdown for a list.
  WeightBreakdown? weightBreakdown(String listId) {
    final list = getList(listId);
    if (list == null) return null;

    final byCategory = <PackingCategory, double>{};
    String heaviestName = '';
    double heaviestWeight = 0;
    int noWeight = 0;

    for (final item in list.items) {
      final totalW = (item.weightGrams ?? 0) * item.quantity;
      if (item.weightGrams != null) {
        byCategory[item.category] = (byCategory[item.category] ?? 0) + totalW;
        if (totalW > heaviestWeight) {
          heaviestWeight = totalW;
          heaviestName = item.name;
        }
      } else {
        noWeight++;
      }
    }

    // Convert to kg
    final byCatKg = <PackingCategory, double>{};
    for (final e in byCategory.entries) {
      byCatKg[e.key] = _round(e.value / 1000, 2);
    }

    return WeightBreakdown(
      totalWeightKg: _round(list.totalWeightKg, 2),
      byCategory: byCatKg,
      heaviestItem: heaviestName,
      heaviestItemWeightGrams: heaviestWeight,
      itemsWithoutWeight: noWeight,
    );
  }

  /// Check readiness for departure.
  ReadinessCheck? readinessCheck(String listId, {DateTime? now}) {
    final list = getList(listId);
    if (list == null) return null;

    final essentialUnpacked = list.items
        .where((i) => i.priority == PackingPriority.essential && !i.isPacked)
        .toList();
    final importantUnpacked = list.items
        .where((i) => i.priority == PackingPriority.important && !i.isPacked)
        .toList();
    final optionalUnpacked = list.items
        .where((i) => i.priority == PackingPriority.optional && !i.isPacked)
        .toList();

    final today = now ?? DateTime.now();
    int daysUntil = -1;
    if (list.departureDate != null) {
      daysUntil = list.departureDate!.difference(today).inDays;
    }

    // Ready = all essentials packed
    final isReady = essentialUnpacked.isEmpty;

    return ReadinessCheck(
      listName: list.name,
      progressPercent: _round(list.progressPercent, 1),
      essentialUnpacked: essentialUnpacked,
      importantUnpacked: importantUnpacked,
      optionalUnpacked: optionalUnpacked,
      isReady: isReady,
      daysUntilDeparture: daysUntil,
    );
  }

  /// Get overall summary across all lists.
  PackingSummary computeSummary({DateTime? now}) {
    final active = activeLists;
    final archived = archivedLists;
    int totalItems = 0;
    int packedItems = 0;
    double totalWeight = 0;
    final byCat = <PackingCategory, int>{};

    for (final list in _lists) {
      totalItems += list.totalItems;
      packedItems += list.packedItems;
      totalWeight += list.totalWeightGrams;
      for (final item in list.items) {
        byCat[item.category] = (byCat[item.category] ?? 0) + item.quantity;
      }
    }

    final fullyPacked = active.where((l) => l.isFullyPacked).length;
    final progress = totalItems == 0 ? 0.0 : (packedItems / totalItems) * 100;

    // Find next departure
    final today = now ?? DateTime.now();
    PackingList? nextDep;
    int closest = 999999;
    for (final list in active) {
      if (list.departureDate != null) {
        final days = list.departureDate!.difference(today).inDays;
        if (days >= 0 && days < closest) {
          closest = days;
          nextDep = list;
        }
      }
    }

    return PackingSummary(
      totalLists: _lists.length,
      activeLists: active.length,
      archivedLists: archived.length,
      fullyPackedLists: fullyPacked,
      totalItems: totalItems,
      packedItems: packedItems,
      overallProgressPercent: _round(progress, 1),
      totalWeightKg: _round(totalWeight / 1000, 2),
      itemsByCategory: byCat,
      nextDeparture: nextDep,
    );
  }

  /// Search items across all lists.
  List<MapEntry<String, PackingItem>> searchItems(String query) {
    final q = query.toLowerCase();
    final results = <MapEntry<String, PackingItem>>[];
    for (final list in _lists) {
      for (final item in list.items) {
        if (item.name.toLowerCase().contains(q) ||
            (item.notes != null && item.notes!.toLowerCase().contains(q))) {
          results.add(MapEntry(list.id, item));
        }
      }
    }
    return results;
  }

  /// Get items grouped by category for a list.
  Map<PackingCategory, List<PackingItem>> itemsByCategory(String listId) {
    final list = getList(listId);
    if (list == null) return {};
    final grouped = <PackingCategory, List<PackingItem>>{};
    for (final item in list.items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  /// Get list of available template types with item counts.
  List<MapEntry<PackingTemplateType, int>> availableTemplates() {
    return _builtInTemplates.entries
        .map((e) => MapEntry(e.key, e.value.length + _universalEssentials.length))
        .toList();
  }

  // ── Export / Import ───────────────────────────────────────────

  /// Export all lists to JSON string.
  String exportJson() {
    return jsonEncode(_lists.map((l) => l.toJson()).toList());
  }

  /// Import lists from JSON string (appends to existing).
  int importJson(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      int count = 0;
      for (final item in data) {
        final list = PackingList.fromJson(item as Map<String, dynamic>);
        _lists.add(list);
        count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // ── Helper ────────────────────────────────────────────────────

  static double _round(double v, int decimals) {
    final f = 1.0;
    var factor = f;
    for (int i = 0; i < decimals; i++) {
      factor *= 10;
    }
    return (v * factor).roundToDouble() / factor;
  }
}
