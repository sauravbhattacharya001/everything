import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/document_entry.dart';
import 'package:everything/core/services/document_tracker_service.dart';

void main() {
  late DocumentTrackerService service;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DocumentEntry _make({String id = 'd1', String name = 'Test Doc',
    DocumentCategory category = DocumentCategory.passport,
    DateTime? issueDate, DateTime? expiryDate, String? issuer, String? holder,
    String? documentNumber, List<RenewalRecord> renewalHistory = const [],
    int reminderDaysBefore = 30, bool isActive = true}) =>
    DocumentEntry(id: id, name: name, category: category,
      issueDate: issueDate ?? today.subtract(const Duration(days: 365)),
      expiryDate: expiryDate ?? today.add(const Duration(days: 365)),
      issuer: issuer, holder: holder, documentNumber: documentNumber,
      renewalHistory: renewalHistory, reminderDaysBefore: reminderDaysBefore, isActive: isActive);

  setUp(() => service = DocumentTrackerService());

  group('DocumentEntry model', () {
    test('daysRemaining positive for future', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 100))).daysRemaining, 100));
    test('daysRemaining negative for past', () =>
      expect(_make(expiryDate: today.subtract(const Duration(days: 5))).daysRemaining, -5));
    test('isExpired when past', () =>
      expect(_make(expiryDate: today.subtract(const Duration(days: 1))).isExpired, true));
    test('isValid when active and not expired', () => expect(_make().isValid, true));
    test('isValid false when inactive', () => expect(_make(isActive: false).isValid, false));
    test('urgency expired', () =>
      expect(_make(expiryDate: today.subtract(const Duration(days: 10))).urgency, ExpiryUrgency.expired));
    test('urgency critical', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 3))).urgency, ExpiryUrgency.critical));
    test('urgency warning', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 15))).urgency, ExpiryUrgency.warning));
    test('urgency upcoming', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 60))).urgency, ExpiryUrgency.upcoming));
    test('urgency safe', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 200))).urgency, ExpiryUrgency.safe));
    test('shouldRemind within window', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 20)), reminderDaysBefore: 30).shouldRemind, true));
    test('shouldRemind false outside', () =>
      expect(_make(expiryDate: today.add(const Duration(days: 60)), reminderDaysBefore: 30).shouldRemind, false));
    test('totalRenewalCost sums', () {
      final doc = _make(renewalHistory: [
        RenewalRecord(id: 'r1', renewedOn: today, previousExpiry: today, newExpiry: today, cost: 100),
        RenewalRecord(id: 'r2', renewedOn: today, previousExpiry: today, newExpiry: today, cost: 200),
      ]);
      expect(doc.totalRenewalCost, 300);
    });
    test('percentElapsed', () {
      final doc = _make(issueDate: today.subtract(const Duration(days: 50)),
        expiryDate: today.add(const Duration(days: 50)));
      expect(doc.percentElapsed, closeTo(50, 2));
    });
    test('totalValidityDays', () {
      expect(_make(issueDate: today.subtract(const Duration(days: 100)),
        expiryDate: today.add(const Duration(days: 265))).totalValidityDays, 365);
    });
    test('copyWith', () {
      final copy = _make(name: 'A', holder: 'Alice').copyWith(name: 'B');
      expect(copy.name, 'B'); expect(copy.holder, 'Alice');
    });
  });

  group('Serialization', () {
    test('roundtrip', () {
      final doc = _make(issuer: 'I', holder: 'H', documentNumber: 'N',
        renewalHistory: [RenewalRecord(id: 'r1', renewedOn: today, previousExpiry: today,
          newExpiry: today.add(const Duration(days: 365)), cost: 50, notes: 'n')]);
      final r = DocumentEntry.fromJson(doc.toJson());
      expect(r.name, doc.name); expect(r.renewalHistory.first.cost, 50);
    });
    test('missing optionals', () {
      final d = DocumentEntry.fromJson({'id': 'x', 'name': 'M',
        'issueDate': today.toIso8601String(), 'expiryDate': today.add(const Duration(days: 30)).toIso8601String()});
      expect(d.category, DocumentCategory.other); expect(d.renewalHistory, isEmpty);
    });
  });

  group('Enums', () {
    test('categories have labels', () { for (final c in DocumentCategory.values) expect(c.label.isNotEmpty, true); });
    test('categories have icons', () { for (final c in DocumentCategory.values) expect(c.icon.isNotEmpty, true); });
  });

  group('RenewalRecord', () {
    test('roundtrip', () {
      final r = RenewalRecord(id: 'r1', renewedOn: today,
        previousExpiry: today.subtract(const Duration(days: 1)),
        newExpiry: today.add(const Duration(days: 365)), cost: 99.99, notes: 'A');
      final x = RenewalRecord.fromJson(r.toJson());
      expect(x.cost, 99.99); expect(x.notes, 'A');
    });
  });

  group('Service CRUD', () {
    test('add', () { service.addDocument(_make()); expect(service.documents.length, 1); });
    test('getById', () { service.addDocument(_make(id: 'x')); expect(service.getById('x')?.name, 'Test Doc'); });
    test('getById null', () => expect(service.getById('x'), isNull));
    test('update', () {
      service.addDocument(_make(id: 'u', name: 'Old'));
      service.updateDocument(_make(id: 'u', name: 'New'));
      expect(service.getById('u')?.name, 'New');
    });
    test('remove', () { service.addDocument(_make(id: 'r')); service.removeDocument('r'); expect(service.documents, isEmpty); });
  });

  group('Filtering', () {
    test('getValid', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 100))));
      service.addDocument(_make(id: '2', expiryDate: today.subtract(const Duration(days: 10))));
      expect(service.getValid().length, 1);
    });
    test('getExpired', () {
      service.addDocument(_make(id: '1', expiryDate: today.subtract(const Duration(days: 5))));
      service.addDocument(_make(id: '2', expiryDate: today.add(const Duration(days: 100))));
      expect(service.getExpired().length, 1);
    });
    test('getExpiringSoon', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 10))));
      service.addDocument(_make(id: '2', expiryDate: today.add(const Duration(days: 60))));
      expect(service.getExpiringSoon(withinDays: 30).length, 1);
    });
    test('getByCategory', () {
      service.addDocument(_make(id: '1', category: DocumentCategory.passport));
      service.addDocument(_make(id: '2', category: DocumentCategory.visa));
      expect(service.getByCategory(DocumentCategory.passport).length, 1);
    });
    test('getByHolder', () {
      service.addDocument(_make(id: '1', holder: 'Alice Smith'));
      expect(service.getByHolder('alice').length, 1);
    });
    test('getByUrgency', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 3))));
      service.addDocument(_make(id: '2', expiryDate: today.add(const Duration(days: 200))));
      expect(service.getByUrgency(ExpiryUrgency.critical).length, 1);
    });
    test('search name', () {
      service.addDocument(_make(id: '1', name: 'Passport'));
      service.addDocument(_make(id: '2', name: 'Visa'));
      expect(service.search('pass').length, 1);
    });
    test('search issuer', () {
      service.addDocument(_make(id: '1', issuer: 'State Dept'));
      expect(service.search('state').length, 1);
    });
    test('search docNum', () {
      service.addDocument(_make(id: '1', documentNumber: 'ABC123'));
      expect(service.search('abc').length, 1);
    });
    test('getNeedingReminder', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 20)), reminderDaysBefore: 30));
      service.addDocument(_make(id: '2', expiryDate: today.add(const Duration(days: 200)), reminderDaysBefore: 30));
      expect(service.getNeedingReminder().length, 1);
    });
  });

  group('Renewals', () {
    test('updates expiry and history', () {
      service.addDocument(_make(id: 'r1', expiryDate: today.add(const Duration(days: 10))));
      final ne = today.add(const Duration(days: 375));
      service.renewDocument('r1', RenewalRecord(id: 'rn', renewedOn: today,
        previousExpiry: today.add(const Duration(days: 10)), newExpiry: ne, cost: 150), ne);
      final d = service.getById('r1')!;
      expect(d.expiryDate, ne); expect(d.renewalHistory.length, 1);
    });
  });

  group('Alerts', () {
    test('includes expired', () {
      service.addDocument(_make(id: '1', expiryDate: today.subtract(const Duration(days: 5))));
      expect(service.getAlerts().first.daysUntilExpiry, lessThan(0));
    });
    test('includes expiring soon', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 15))));
      expect(service.getAlerts(withinDays: 30).first.message.contains('15 days'), true);
    });
  });

  group('Summary', () {
    test('aggregates', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 200))));
      service.addDocument(_make(id: '2', expiryDate: today.subtract(const Duration(days: 5))));
      service.addDocument(_make(id: '3', expiryDate: today.add(const Duration(days: 3)), category: DocumentCategory.visa));
      final s = service.getSummary();
      expect(s.totalDocuments, 3); expect(s.validCount, 2); expect(s.expiredCount, 1); expect(s.criticalCount, 1);
    });
  });

  group('Analytics', () {
    test('timeline sorts', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 200))));
      service.addDocument(_make(id: '2', expiryDate: today.add(const Duration(days: 50))));
      expect(service.getExpiryTimeline().first.id, '2');
    });
    test('estimateUpcomingRenewalCost', () {
      service.addDocument(_make(id: '1', expiryDate: today.add(const Duration(days: 20)),
        renewalHistory: [
          RenewalRecord(id: 'r1', renewedOn: today, previousExpiry: today, newExpiry: today, cost: 100),
          RenewalRecord(id: 'r2', renewedOn: today, previousExpiry: today, newExpiry: today, cost: 200),
        ]));
      expect(service.estimateUpcomingRenewalCost(withinDays: 30), 150);
    });
    test('getByHolderGrouped', () {
      service.addDocument(_make(id: '1', holder: 'Alice'));
      service.addDocument(_make(id: '2', holder: 'Alice'));
      service.addDocument(_make(id: '3', holder: 'Bob'));
      expect(service.getByHolderGrouped()['Alice']?.length, 2);
    });
    test('null holder = Unassigned', () {
      service.addDocument(_make(id: '1'));
      expect(service.getByHolderGrouped().containsKey('Unassigned'), true);
    });
  });

  group('Persistence', () {
    test('export/import roundtrip', () {
      service.addDocument(_make(id: '1', name: 'P'));
      service.addDocument(_make(id: '2', name: 'L'));
      final j = service.exportToJson();
      final s2 = DocumentTrackerService(); s2.importFromJson(j);
      expect(s2.documents.length, 2); expect(s2.documents.first.name, 'P');
    });
    test('import clears', () {
      service.addDocument(_make(id: '1'));
      service.importFromJson('[]');
      expect(service.documents, isEmpty);
    });
  });
}
