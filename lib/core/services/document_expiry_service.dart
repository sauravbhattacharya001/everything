import 'dart:convert';
import '../models/document_entry.dart';

/// Service for managing document expiry tracking — CRUD, filtering, analytics.
class DocumentExpiryService {
  final List<DocumentEntry> _documents = [];

  List<DocumentEntry> get documents => List.unmodifiable(_documents);

  /// All active (non-renewed) documents sorted by urgency (most urgent first).
  List<DocumentEntry> get activeDocuments {
    final active = _documents.where((d) => !d.renewed).toList();
    active.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return active;
  }

  /// Documents that have been renewed.
  List<DocumentEntry> get renewedDocuments =>
      _documents.where((d) => d.renewed).toList();

  /// Documents requiring attention (reminder due or expired).
  List<DocumentEntry> get alertDocuments =>
      activeDocuments.where((d) => d.isReminderDue).toList();

  /// Filter documents by category.
  List<DocumentEntry> byCategory(DocumentCategory category) =>
      _documents.where((d) => d.category == category).toList();

  /// Filter documents by urgency.
  List<DocumentEntry> byUrgency(DocumentUrgency urgency) =>
      activeDocuments.where((d) => d.urgency == urgency).toList();

  /// Search by name, issuer, or document number.
  List<DocumentEntry> search(String query) {
    final q = query.toLowerCase();
    return _documents.where((d) =>
        d.name.toLowerCase().contains(q) ||
        (d.issuer?.toLowerCase().contains(q) ?? false) ||
        (d.documentNumber?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  void addDocument(DocumentEntry doc) => _documents.add(doc);

  void updateDocument(String id, DocumentEntry updated) {
    final idx = _documents.indexWhere((d) => d.id == id);
    if (idx >= 0) _documents[idx] = updated;
  }

  void removeDocument(String id) =>
      _documents.removeWhere((d) => d.id == id);

  void markRenewed(String id, {DateTime? renewedDate}) {
    final idx = _documents.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _documents[idx] = _documents[idx].copyWith(
        renewed: true,
        renewedDate: renewedDate ?? DateTime.now(),
      );
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
    for (final d in _documents) {
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

  String exportToJson() => jsonEncode(_documents.map((d) => d.toJson()).toList());

  void importFromJson(String json) {
    _documents.clear();
    final list = jsonDecode(json) as List;
    _documents.addAll(list.map((e) => DocumentEntry.fromJson(e as Map<String, dynamic>)));
  }
}
