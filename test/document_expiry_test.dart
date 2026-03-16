import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/document_expiry_service.dart';
import 'package:everything/models/document_entry.dart';

void main() {
  late DocumentExpiryService service;
  final now = DateTime.now();

  DocumentEntry _makeDoc({
    String id = 'd1',
    String name = 'Test Doc',
    DocumentCategory category = DocumentCategory.identification,
    int daysAgoIssued = 365,
    int daysUntilExpiry = 90,
    String? issuer,
    String? documentNumber,
    int reminderDaysBefore = 30,
    bool renewed = false,
  }) {
    return DocumentEntry(
      id: id,
      name: name,
      category: category,
      issueDate: now.subtract(Duration(days: daysAgoIssued)),
      expiryDate: now.add(Duration(days: daysUntilExpiry)),
      issuer: issuer,
      documentNumber: documentNumber,
      reminderDaysBefore: reminderDaysBefore,
      renewed: renewed,
    );
  }

  setUp(() {
    service = DocumentExpiryService();
  });

  group('DocumentEntry', () {
    test('calculates days until expiry', () {
      final doc = _makeDoc(daysUntilExpiry: 45);
      expect(doc.daysUntilExpiry, 45);
    });

    test('reports negative days for expired docs', () {
      final doc = _makeDoc(daysUntilExpiry: -10);
      expect(doc.daysUntilExpiry, -10);
    });

    test('urgency is expired when past due', () {
      final doc = _makeDoc(daysUntilExpiry: -5);
      expect(doc.urgency, DocumentUrgency.expired);
    });

    test('urgency is critical under 30 days', () {
      final doc = _makeDoc(daysUntilExpiry: 15);
      expect(doc.urgency, DocumentUrgency.critical);
    });

    test('urgency is warning under 90 days', () {
      final doc = _makeDoc(daysUntilExpiry: 60);
      expect(doc.urgency, DocumentUrgency.warning);
    });

    test('urgency is upcoming under 180 days', () {
      final doc = _makeDoc(daysUntilExpiry: 120);
      expect(doc.urgency, DocumentUrgency.upcoming);
    });

    test('urgency is safe at 180+ days', () {
      final doc = _makeDoc(daysUntilExpiry: 200);
      expect(doc.urgency, DocumentUrgency.safe);
    });

    test('renewed docs are always safe', () {
      final doc = _makeDoc(daysUntilExpiry: -5, renewed: true);
      expect(doc.urgency, DocumentUrgency.safe);
    });

    test('isReminderDue when within reminder window', () {
      final doc = _makeDoc(daysUntilExpiry: 20, reminderDaysBefore: 30);
      expect(doc.isReminderDue, true);
    });

    test('isReminderDue false when outside window', () {
      final doc = _makeDoc(daysUntilExpiry: 60, reminderDaysBefore: 30);
      expect(doc.isReminderDue, false);
    });

    test('isReminderDue false when renewed', () {
      final doc = _makeDoc(daysUntilExpiry: 5, reminderDaysBefore: 30, renewed: true);
      expect(doc.isReminderDue, false);
    });

    test('validityUsedPercent at midpoint', () {
      final doc = DocumentEntry(
        id: 'x',
        name: 'X',
        category: DocumentCategory.other,
        issueDate: now.subtract(const Duration(days: 50)),
        expiryDate: now.add(const Duration(days: 50)),
      );
      expect(doc.validityUsedPercent, closeTo(0.5, 0.02));
    });

    test('toJson and fromJson round-trip', () {
      final doc = _makeDoc(issuer: 'Gov', documentNumber: 'ABC123', daysUntilExpiry: 100);
      final json = doc.toJson();
      final restored = DocumentEntry.fromJson(json);
      expect(restored.id, doc.id);
      expect(restored.name, doc.name);
      expect(restored.category, doc.category);
      expect(restored.issuer, 'Gov');
      expect(restored.documentNumber, 'ABC123');
    });

    test('copyWith creates modified copy', () {
      final doc = _makeDoc();
      final copy = doc.copyWith(name: 'New Name', renewed: true);
      expect(copy.name, 'New Name');
      expect(copy.renewed, true);
      expect(copy.id, doc.id);
    });
  });

  group('DocumentExpiryService', () {
    test('addDocument increases list', () {
      service.addDocument(_makeDoc());
      expect(service.documents.length, 1);
    });

    test('removeDocument removes by id', () {
      service.addDocument(_makeDoc(id: 'a'));
      service.addDocument(_makeDoc(id: 'b'));
      service.removeDocument('a');
      expect(service.documents.length, 1);
      expect(service.documents.first.id, 'b');
    });

    test('activeDocuments excludes renewed', () {
      service.addDocument(_makeDoc(id: 'a'));
      service.addDocument(_makeDoc(id: 'b', renewed: true));
      expect(service.activeDocuments.length, 1);
    });

    test('activeDocuments sorted by urgency', () {
      service.addDocument(_makeDoc(id: 'far', daysUntilExpiry: 200));
      service.addDocument(_makeDoc(id: 'close', daysUntilExpiry: 10));
      service.addDocument(_makeDoc(id: 'mid', daysUntilExpiry: 60));
      expect(service.activeDocuments.first.id, 'close');
      expect(service.activeDocuments.last.id, 'far');
    });

    test('alertDocuments returns reminder-due docs', () {
      service.addDocument(_makeDoc(id: 'a', daysUntilExpiry: 20, reminderDaysBefore: 30));
      service.addDocument(_makeDoc(id: 'b', daysUntilExpiry: 100, reminderDaysBefore: 30));
      expect(service.alertDocuments.length, 1);
      expect(service.alertDocuments.first.id, 'a');
    });

    test('byCategory filters correctly', () {
      service.addDocument(_makeDoc(id: 'a', category: DocumentCategory.travel));
      service.addDocument(_makeDoc(id: 'b', category: DocumentCategory.insurance));
      expect(service.byCategory(DocumentCategory.travel).length, 1);
    });

    test('byUrgency filters correctly', () {
      service.addDocument(_makeDoc(id: 'a', daysUntilExpiry: 15)); // critical
      service.addDocument(_makeDoc(id: 'b', daysUntilExpiry: 200)); // safe
      expect(service.byUrgency(DocumentUrgency.critical).length, 1);
    });

    test('search by name', () {
      service.addDocument(_makeDoc(name: 'US Passport'));
      service.addDocument(_makeDoc(id: 'b', name: 'License'));
      expect(service.search('passport').length, 1);
    });

    test('search by issuer', () {
      service.addDocument(_makeDoc(issuer: 'State Dept'));
      expect(service.search('state').length, 1);
    });

    test('search by document number', () {
      service.addDocument(_makeDoc(documentNumber: 'XY123'));
      expect(service.search('xy123').length, 1);
    });

    test('markRenewed sets renewed flag', () {
      service.addDocument(_makeDoc(id: 'a'));
      service.markRenewed('a');
      expect(service.documents.first.renewed, true);
      expect(service.documents.first.renewedDate, isNotNull);
    });

    test('urgencyCounts totals correctly', () {
      service.addDocument(_makeDoc(id: 'a', daysUntilExpiry: 15)); // critical
      service.addDocument(_makeDoc(id: 'b', daysUntilExpiry: 60)); // warning
      service.addDocument(_makeDoc(id: 'c', daysUntilExpiry: 60)); // warning
      final counts = service.urgencyCounts;
      expect(counts[DocumentUrgency.critical], 1);
      expect(counts[DocumentUrgency.warning], 2);
    });

    test('categoryCounts totals correctly', () {
      service.addDocument(_makeDoc(id: 'a', category: DocumentCategory.travel));
      service.addDocument(_makeDoc(id: 'b', category: DocumentCategory.travel));
      service.addDocument(_makeDoc(id: 'c', category: DocumentCategory.medical));
      expect(service.categoryCounts[DocumentCategory.travel], 2);
      expect(service.categoryCounts[DocumentCategory.medical], 1);
    });

    test('averageDaysToExpiry computes mean', () {
      service.addDocument(_makeDoc(id: 'a', daysUntilExpiry: 100));
      service.addDocument(_makeDoc(id: 'b', daysUntilExpiry: 200));
      expect(service.averageDaysToExpiry, closeTo(150, 1));
    });

    test('expiringWithin returns correct docs', () {
      service.addDocument(_makeDoc(id: 'a', daysUntilExpiry: 10));
      service.addDocument(_makeDoc(id: 'b', daysUntilExpiry: 50));
      service.addDocument(_makeDoc(id: 'c', daysUntilExpiry: 200));
      expect(service.expiringWithin(30).length, 1);
      expect(service.expiringWithin(60).length, 2);
    });

    test('nextToExpire returns soonest', () {
      service.addDocument(_makeDoc(id: 'a', daysUntilExpiry: 100));
      service.addDocument(_makeDoc(id: 'b', daysUntilExpiry: 10));
      expect(service.nextToExpire?.id, 'b');
    });

    test('exportToJson and importFromJson round-trip', () {
      service.addDocument(_makeDoc(id: 'a', name: 'Passport'));
      service.addDocument(_makeDoc(id: 'b', name: 'License'));
      final json = service.exportToJson();
      final service2 = DocumentExpiryService();
      service2.importFromJson(json);
      expect(service2.documents.length, 2);
      expect(service2.documents.first.name, 'Passport');
    });

    test('updateDocument replaces entry', () {
      service.addDocument(_makeDoc(id: 'a', name: 'Old'));
      service.updateDocument('a', _makeDoc(id: 'a', name: 'New'));
      expect(service.documents.first.name, 'New');
    });

    test('renewedDocuments returns only renewed', () {
      service.addDocument(_makeDoc(id: 'a', renewed: true));
      service.addDocument(_makeDoc(id: 'b'));
      expect(service.renewedDocuments.length, 1);
      expect(service.renewedDocuments.first.id, 'a');
    });

    test('empty service returns safe defaults', () {
      expect(service.documents, isEmpty);
      expect(service.activeDocuments, isEmpty);
      expect(service.alertDocuments, isEmpty);
      expect(service.nextToExpire, isNull);
      expect(service.averageDaysToExpiry, 0);
    });
  });

  group('DocumentCategory', () {
    test('all categories have labels', () {
      for (final c in DocumentCategory.values) {
        expect(c.label, isNotEmpty);
        expect(c.emoji, isNotEmpty);
      }
    });
  });

  group('DocumentUrgency', () {
    test('all urgency levels have labels', () {
      for (final u in DocumentUrgency.values) {
        expect(u.label, isNotEmpty);
        expect(u.emoji, isNotEmpty);
      }
    });
  });
}
