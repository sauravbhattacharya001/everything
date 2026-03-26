/// Shared collection utilities to eliminate duplicated frequency-counting,
/// grouping, and top-N patterns across 20+ service files.
///
/// Before this utility, the pattern:
/// ```dart
/// final counts = <K, int>{};
/// for (final item in items) {
///   counts[key] = (counts[key] ?? 0) + 1;
/// }
/// ```
/// was copy-pasted 25+ times across services. These helpers make the
/// intent clearer and reduce boilerplate.
class CollectionUtils {
  CollectionUtils._();

  /// Counts occurrences of each key extracted from [items].
  ///
  /// Example:
  /// ```dart
  /// final tagCounts = CollectionUtils.frequency(
  ///   bookmarks,
  ///   (b) => b.folder,
  /// );
  /// ```
  static Map<K, int> frequency<T, K>(
    Iterable<T> items,
    K Function(T) keyOf,
  ) {
    final counts = <K, int>{};
    for (final item in items) {
      final key = keyOf(item);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  /// Counts occurrences across multiple keys per item (e.g., tags).
  ///
  /// Example:
  /// ```dart
  /// final tagCounts = CollectionUtils.frequencyFlat(
  ///   bookmarks,
  ///   (b) => b.tags,
  /// );
  /// ```
  static Map<K, int> frequencyFlat<T, K>(
    Iterable<T> items,
    Iterable<K> Function(T) keysOf,
  ) {
    final counts = <K, int>{};
    for (final item in items) {
      for (final key in keysOf(item)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Returns the top [limit] entries from a frequency map, sorted
  /// descending by count.
  ///
  /// Example:
  /// ```dart
  /// final top5 = CollectionUtils.topN(domainCounts, 5);
  /// ```
  static List<MapEntry<K, int>> topN<K>(Map<K, int> counts, int limit) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Returns the key with the highest count, or null if empty.
  static K? maxByCount<K>(Map<K, int> counts) {
    if (counts.isEmpty) return null;
    K? best;
    int bestCount = -1;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        bestCount = e.value;
        best = e.key;
      }
    }
    return best;
  }

  /// Groups items by a key, preserving insertion order.
  ///
  /// Example:
  /// ```dart
  /// final byCategory = CollectionUtils.groupBy(
  ///   items,
  ///   (item) => item.category,
  /// );
  /// ```
  static Map<K, List<T>> groupBy<T, K>(
    Iterable<T> items,
    K Function(T) keyOf,
  ) {
    final map = <K, List<T>>{};
    for (final item in items) {
      final key = keyOf(item);
      (map[key] ??= []).add(item);
    }
    return map;
  }

  /// Sums a numeric property across all items.
  static double sumBy<T>(Iterable<T> items, double Function(T) valueOf) {
    double total = 0;
    for (final item in items) {
      total += valueOf(item);
    }
    return total;
  }
}
