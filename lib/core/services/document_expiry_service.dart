import '../../models/document_entry.dart';
import 'crud_service.dart';

/// Service for managing document expiry tracking — CRUD, filtering, analytics.
///
/// Extends [CrudService] for standard CRUD + JSON persistence,
/// adding document-specific urgency tracking, category filtering,
/// and expiry analytics.
class DocumentExpiryService extends CrudService<DocumentEntry> {
  @override
  String getId(DocumentEntry item) => item.id;
  @override
  Map<String, dynamic> toJson(DocumentEntry item) => item.toJson();
  @override
  DocumentEntry fromJson(Map<String, dynamic> json) =>
      DocumentEntry.fromJson(json);

  /// Backward-compatible accessor.
  List<DocumentEntry> get documents => items;

  /// All active (non-renewed) documents sorted by urgency (most urgent first).
  List<DocumentEntry> get activeDocuments {
    final active = items.where((d) => !d.renewed).toList();
    active.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return active;
  }

  /// Documents that have been renewed.
  List<DocumentEntry> get renewedDocuments =>
      items.where((d) => d.renewed).toList();

  /// Documents requiring attention (reminder due or expired).
  List<DocumentEntry> get alertDocuments =>
      activeDocuments.where((d) => d.isReminderDue).toList();

  /// Filter documents by category.
  List<DocumentEntry> byCategory(DocumentCategory category) =>
      items.where((d) => d.category == category).toList();

  /// Filter documents by urgency.
  List<DocumentEntry> byUrgency(DocumentUrgency urgency) =>
      activeDocuments.where((d) => d.urgency == urgency).toList();

  /// Search by name, issuer, or document number.
  List<DocumentEntry> search(String query) {
    final q = query.toLowerCase();
    return items.where((d) =>
        d.name.toLowerCase().contains(q) ||
        (d.issuer?.toLowerCase().contains(q) ?? false) ||
        (d.documentNumber?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  // ── Legacy CRUD wrappers ──

  void addDocument(DocumentEntry doc) => add(doc);

  void updateDocument(String id, DocumentEntry updated) {
    final idx = indexById(id);
    if (idx >= 0) updateAt(idx, updated);
  }

  void removeDocument(String id) => remove(id);

  void markRenewed(String id, {DateTime? renewedDate}) {
    final idx = indexById(id);
    if (idx >= 0) {
      updateAt(idx, itemsMutable[idx].copyWith(
        renewed: true,
        renewedDate: renewedDate ?? DateTime.now(),
      ));
    }
  }

  /// Count by urgency level.
  Map<DocumentUrgency, int> get urgencyCounts {
    final counts = <DocumentUrgency, int>{};
    for (final u in DocumentUrgency.values) {
      counts[u] = 0;
    }
    for (final d in activeDocuments) {
      counts[d.urgency] = (counts[d.urgency] ?? 0) + 1;
    }
    return counts;
  }

  /// Count by category.
  Map<DocumentCategory, int> get categoryCounts {
    final counts = <DocumentCategory, int>{};
    for (final d in items) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Average days until expiry across active documents.
  double get averageDaysToExpiry {
    final active = activeDocuments;
    if (active.isEmpty) return 0;
    return active.map((d) => d.daysUntilExpiry).reduce((a, b) => a + b) /
        active.length;
  }

  /// Documents expiring within the next N days.
  List<DocumentEntry> expiringWithin(int days) =>
      activeDocuments.where((d) => d.daysUntilExpiry <= days && d.daysUntilExpiry >= 0).toList();

  /// Next document to expire.
  DocumentEntry? get nextToExpire {
    final active = activeDocuments;
    if (active.isEmpty) return null;
    return active.first;
  }
}
