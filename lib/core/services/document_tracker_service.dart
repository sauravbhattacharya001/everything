import 'dart:convert';
import '../../models/document_entry.dart';

class DocumentAlert {
  final DocumentEntry document;
  final int daysUntilExpiry;
  final String message;
  const DocumentAlert({required this.document, required this.daysUntilExpiry, required this.message});
}

class DocumentCategoryBreakdown {
  final DocumentCategory category;
  final int count, validCount, expiredCount;
  final double totalRenewalCost, percentOfTotal;
  const DocumentCategoryBreakdown({required this.category, required this.count,
    required this.validCount, required this.expiredCount,
    required this.totalRenewalCost, required this.percentOfTotal});
}

class DocumentSummary {
  final int totalDocuments, validCount, expiredCount, expiringSoonCount, criticalCount;
  final double totalRenewalCost;
  final List<DocumentCategoryBreakdown> categoryBreakdown;
  final List<DocumentAlert> alerts;
  const DocumentSummary({required this.totalDocuments, required this.validCount,
    required this.expiredCount, required this.expiringSoonCount, required this.criticalCount,
    required this.totalRenewalCost, required this.categoryBreakdown, required this.alerts});
}

class DocumentTrackerService {
  final List<DocumentEntry> _documents = [];
  List<DocumentEntry> get documents => List.unmodifiable(_documents);

  void addDocument(DocumentEntry e) => _documents.add(e);
  void updateDocument(DocumentEntry e) {
    final i = _documents.indexWhere((d) => d.id == e.id);
    if (i >= 0) _documents[i] = e;
  }
  void removeDocument(String id) => _documents.removeWhere((d) => d.id == id);
  DocumentEntry? getById(String id) {
    try { return _documents.firstWhere((d) => d.id == id); } catch (_) { return null; }
  }

  void renewDocument(String id, RenewalRecord renewal, DateTime newExpiry) {
    final doc = getById(id);
    if (doc == null) return;
    updateDocument(doc.copyWith(expiryDate: newExpiry, renewalHistory: [...doc.renewalHistory, renewal]));
  }

  List<DocumentEntry> getValid() => _documents.where((d) => d.isValid).toList();
  List<DocumentEntry> getExpired() => _documents.where((d) => d.isExpired).toList();
  List<DocumentEntry> getExpiringSoon({int withinDays = 30}) =>
    _documents.where((d) => !d.isExpired && d.daysRemaining <= withinDays).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  List<DocumentEntry> getByCategory(DocumentCategory c) => _documents.where((d) => d.category == c).toList();
  List<DocumentEntry> getByHolder(String h) {
    final q = h.toLowerCase();
    return _documents.where((d) => d.holder?.toLowerCase().contains(q) ?? false).toList();
  }
  List<DocumentEntry> getByUrgency(ExpiryUrgency u) => _documents.where((d) => d.urgency == u).toList();
  List<DocumentEntry> search(String query) {
    final q = query.toLowerCase();
    return _documents.where((d) => d.name.toLowerCase().contains(q) ||
      (d.issuer?.toLowerCase().contains(q) ?? false) ||
      (d.holder?.toLowerCase().contains(q) ?? false) ||
      (d.documentNumber?.toLowerCase().contains(q) ?? false)).toList();
  }
  List<DocumentEntry> getNeedingReminder() => _documents.where((d) => d.shouldRemind && d.isActive).toList();

  List<DocumentAlert> getAlerts({int withinDays = 90}) {
    final a = <DocumentAlert>[];
    for (final d in getExpired().where((d) => d.isActive)) {
      final days = d.daysRemaining.abs();
      a.add(DocumentAlert(document: d, daysUntilExpiry: d.daysRemaining,
        message: '${d.category.icon} ${d.name} expired $days day${days == 1 ? '' : 's'} ago!'));
    }
    for (final d in getExpiringSoon(withinDays: withinDays)) {
      final days = d.daysRemaining;
      final msg = days == 0 ? '${d.category.icon} ${d.name} expires today!'
        : days == 1 ? '${d.category.icon} ${d.name} expires tomorrow!'
        : days <= 7 ? '${d.category.icon} ${d.name} expires in $days days!'
        : '${d.category.icon} ${d.name} expires in $days days';
      a.add(DocumentAlert(document: d, daysUntilExpiry: days, message: msg));
    }
    return a;
  }

  DocumentSummary getSummary() {
    final valid = getValid(); final expired = getExpired().where((d) => d.isActive).toList();
    final soon = getExpiringSoon(); final crit = getByUrgency(ExpiryUrgency.critical);
    final cost = _documents.fold<double>(0, (s, d) => s + d.totalRenewalCost);
    final catMap = <DocumentCategory, List<DocumentEntry>>{};
    for (final d in _documents) catMap.putIfAbsent(d.category, () => []).add(d);
    final bd = catMap.entries.map((e) => DocumentCategoryBreakdown(
      category: e.key, count: e.value.length,
      validCount: e.value.where((d) => d.isValid).length,
      expiredCount: e.value.where((d) => d.isExpired).length,
      totalRenewalCost: e.value.fold<double>(0, (s, d) => s + d.totalRenewalCost),
      percentOfTotal: _documents.isNotEmpty ? (e.value.length / _documents.length) * 100 : 0,
    )).toList()..sort((a, b) => b.count.compareTo(a.count));
    return DocumentSummary(totalDocuments: _documents.length, validCount: valid.length,
      expiredCount: expired.length, expiringSoonCount: soon.length,
      criticalCount: crit.length, totalRenewalCost: cost, categoryBreakdown: bd, alerts: getAlerts());
  }

  List<DocumentEntry> getExpiryTimeline() {
    final a = _documents.where((d) => d.isActive).toList();
    a.sort((a, b) => a.expiryDate.compareTo(b.expiryDate)); return a;
  }

  double estimateUpcomingRenewalCost({int withinDays = 90}) {
    double est = 0;
    for (final d in getExpiringSoon(withinDays: withinDays))
      if (d.renewalHistory.isNotEmpty) est += d.totalRenewalCost / d.renewalCount;
    return est;
  }

  Map<String, List<DocumentEntry>> getByHolderGrouped() {
    final m = <String, List<DocumentEntry>>{};
    for (final d in _documents) m.putIfAbsent(d.holder ?? 'Unassigned', () => []).add(d);
    return m;
  }

  String exportToJson() => jsonEncode(_documents.map((d) => d.toJson()).toList());
  void importFromJson(String s) {
    final l = jsonDecode(s) as List<dynamic>; _documents.clear();
    for (final i in l) _documents.add(DocumentEntry.fromJson(i as Map<String, dynamic>));
  }
}
