import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/warranty_tracker_service.dart';
import 'package:everything/models/warranty_entry.dart';

void main() {
  late WarrantyTrackerService service;
  final now = DateTime.now();

  WarrantyEntry _make({
    String id = 'w1',
    String name = 'Test Product',
    WarrantyCategory category = WarrantyCategory.electronics,
    WarrantyType type = WarrantyType.manufacturer,
    int daysAgo = 100,
    int daysUntilExpiry = 100,
    double price = 500.0,
    String? brand,
    String? retailer,
    List<WarrantyClaim> claims = const [],
  }) =>
      WarrantyEntry(
        id: id,
        productName: name,
        brand: brand,
        category: category,
        type: type,
        purchaseDate: now.subtract(Duration(days: daysAgo)),
        expirationDate: now.add(Duration(days: daysUntilExpiry)),
        purchasePrice: price,
        retailer: retailer,
        claims: claims,
      );

  setUp(() {
    service = WarrantyTrackerService();
  });

  group('CRUD', () {
    test('add and list warranties', () {
      service.addWarranty(_make());
      expect(service.warranties.length, 1);
      expect(service.warranties.first.productName, 'Test Product');
    });

    test('update warranty', () {
      service.addWarranty(_make());
      service.updateWarranty(_make().copyWith(productName: 'Updated'));
      expect(service.warranties.first.productName, 'Updated');
    });

    test('remove warranty', () {
      service.addWarranty(_make());
      service.removeWarranty('w1');
      expect(service.warranties, isEmpty);
    });

    test('getById returns correct warranty', () {
      service.addWarranty(_make(id: 'a'));
      service.addWarranty(_make(id: 'b', name: 'Other'));
      expect(service.getById('b')?.productName, 'Other');
    });

    test('getById returns null for missing', () {
      expect(service.getById('nonexistent'), isNull);
    });
  });

  group('WarrantyEntry model', () {
    test('isExpired returns true for past expiration', () {
      final w = _make(daysUntilExpiry: -10);
      expect(w.isExpired, isTrue);
    });

    test('isExpired returns false for future expiration', () {
      final w = _make(daysUntilExpiry: 10);
      expect(w.isExpired, isFalse);
    });

    test('isValid checks active and not expired', () {
      final w = _make(daysUntilExpiry: 50);
      expect(w.isValid, isTrue);
    });

    test('isExpiringSoon within 30 days', () {
      expect(_make(daysUntilExpiry: 15).isExpiringSoon, isTrue);
      expect(_make(daysUntilExpiry: 60).isExpiringSoon, isFalse);
      expect(_make(daysUntilExpiry: -5).isExpiringSoon, isFalse);
    });

    test('daysRemaining calculated correctly', () {
      final w = _make(daysUntilExpiry: 42);
      expect(w.daysRemaining, 42);
    });

    test('percentElapsed within range', () {
      final w = _make(daysAgo: 50, daysUntilExpiry: 50);
      expect(w.percentElapsed, greaterThanOrEqualTo(0));
      expect(w.percentElapsed, lessThanOrEqualTo(100));
    });

    test('claimCount and openClaimCount', () {
      final w = _make(claims: [
        WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'broken', status: ClaimStatus.submitted),
        WarrantyClaim(id: 'c2', dateSubmitted: now, issue: 'cracked', status: ClaimStatus.completed),
      ]);
      expect(w.claimCount, 2);
      expect(w.openClaimCount, 1);
    });
  });

  group('WarrantyClaim model', () {
    test('isResolved for completed and denied', () {
      expect(WarrantyClaim(id: 'c', dateSubmitted: now, issue: 'x', status: ClaimStatus.completed).isResolved, isTrue);
      expect(WarrantyClaim(id: 'c', dateSubmitted: now, issue: 'x', status: ClaimStatus.denied).isResolved, isTrue);
      expect(WarrantyClaim(id: 'c', dateSubmitted: now, issue: 'x', status: ClaimStatus.inProgress).isResolved, isFalse);
    });

    test('daysToResolve calculation', () {
      final c = WarrantyClaim(
        id: 'c', dateSubmitted: now.subtract(const Duration(days: 10)),
        issue: 'x', status: ClaimStatus.completed, dateResolved: now,
      );
      expect(c.daysToResolve, 10);
    });

    test('daysToResolve returns -1 when unresolved', () {
      final c = WarrantyClaim(id: 'c', dateSubmitted: now, issue: 'x');
      expect(c.daysToResolve, -1);
    });
  });

  group('Filtering', () {
    test('getActive returns only valid warranties', () {
      service.addWarranty(_make(id: 'a', daysUntilExpiry: 100));
      service.addWarranty(_make(id: 'b', daysUntilExpiry: -10));
      expect(service.getActive().length, 1);
      expect(service.getActive().first.id, 'a');
    });

    test('getExpired returns only expired', () {
      service.addWarranty(_make(id: 'a', daysUntilExpiry: 100));
      service.addWarranty(_make(id: 'b', daysUntilExpiry: -10));
      expect(service.getExpired().length, 1);
    });

    test('getExpiringSoon sorted by days remaining', () {
      service.addWarranty(_make(id: 'a', daysUntilExpiry: 25));
      service.addWarranty(_make(id: 'b', daysUntilExpiry: 5));
      service.addWarranty(_make(id: 'c', daysUntilExpiry: 100));
      final soon = service.getExpiringSoon();
      expect(soon.length, 2);
      expect(soon.first.id, 'b');
    });

    test('getByCategory filters correctly', () {
      service.addWarranty(_make(id: 'a', category: WarrantyCategory.electronics));
      service.addWarranty(_make(id: 'b', category: WarrantyCategory.furniture));
      expect(service.getByCategory(WarrantyCategory.electronics).length, 1);
    });

    test('getByType filters correctly', () {
      service.addWarranty(_make(id: 'a', type: WarrantyType.lifetime));
      service.addWarranty(_make(id: 'b', type: WarrantyType.manufacturer));
      expect(service.getByType(WarrantyType.lifetime).length, 1);
    });

    test('searchByName matches product, brand, retailer', () {
      service.addWarranty(_make(id: 'a', name: 'MacBook', brand: 'Apple', retailer: 'Apple Store'));
      expect(service.searchByName('mac').length, 1);
      expect(service.searchByName('apple').length, 1);
      expect(service.searchByName('store').length, 1);
      expect(service.searchByName('xyz'), isEmpty);
    });

    test('getWithOpenClaims', () {
      service.addWarranty(_make(id: 'a', claims: [
        WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'x', status: ClaimStatus.submitted),
      ]));
      service.addWarranty(_make(id: 'b'));
      expect(service.getWithOpenClaims().length, 1);
    });
  });

  group('Claims management', () {
    test('addClaim appends to warranty', () {
      service.addWarranty(_make());
      service.addClaim('w1', WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'broken'));
      expect(service.getById('w1')!.claimCount, 1);
    });

    test('updateClaim modifies existing claim', () {
      service.addWarranty(_make(claims: [
        WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'old issue'),
      ]));
      service.updateClaim('w1', WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'old issue', status: ClaimStatus.approved));
      expect(service.getById('w1')!.claims.first.status, ClaimStatus.approved);
    });

    test('addClaim to nonexistent warranty is no-op', () {
      service.addClaim('missing', WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'x'));
      expect(service.warranties, isEmpty);
    });
  });

  group('Alerts', () {
    test('getExpiryAlerts generates messages', () {
      service.addWarranty(_make(id: 'a', name: 'Laptop', daysUntilExpiry: 5));
      final alerts = service.getExpiryAlerts();
      expect(alerts.length, 1);
      expect(alerts.first.message, contains('Laptop'));
      expect(alerts.first.message, contains('5 days'));
    });

    test('alert message for 1 day', () {
      service.addWarranty(_make(id: 'a', name: 'Phone', daysUntilExpiry: 1));
      final alerts = service.getExpiryAlerts();
      expect(alerts.first.message, contains('tomorrow'));
    });
  });

  group('Summary', () {
    test('getSummary returns correct counts', () {
      service.addWarranty(_make(id: 'a', daysUntilExpiry: 100, price: 1000));
      service.addWarranty(_make(id: 'b', daysUntilExpiry: -10, price: 500));
      service.addWarranty(_make(id: 'c', daysUntilExpiry: 20, price: 300));
      final s = service.getSummary();
      expect(s.totalWarranties, 3);
      expect(s.activeCount, 2);
      expect(s.expiredCount, 1);
      expect(s.totalPurchaseValue, 1800);
      expect(s.protectedValue, 1300);
    });

    test('category breakdown populated', () {
      service.addWarranty(_make(id: 'a', category: WarrantyCategory.electronics, price: 500));
      service.addWarranty(_make(id: 'b', category: WarrantyCategory.furniture, price: 300));
      final s = service.getSummary();
      expect(s.categoryBreakdown.length, 2);
    });
  });

  group('Coverage', () {
    test('getCoverageScore returns 100 when all active', () {
      service.addWarranty(_make(daysUntilExpiry: 100));
      expect(service.getCoverageScore(), 100);
    });

    test('getCoverageScore returns 0 when all expired', () {
      service.addWarranty(_make(daysUntilExpiry: -10));
      expect(service.getCoverageScore(), 0);
    });

    test('getCoverageScore returns 0 when empty', () {
      expect(service.getCoverageScore(), 0);
    });

    test('getExpirationTimeline sorted by date', () {
      service.addWarranty(_make(id: 'a', daysUntilExpiry: 100));
      service.addWarranty(_make(id: 'b', daysUntilExpiry: 10));
      final timeline = service.getExpirationTimeline();
      expect(timeline.first.id, 'b');
    });
  });

  group('Serialization', () {
    test('toJson and fromJson round-trip for WarrantyEntry', () {
      final w = _make(brand: 'TestBrand', retailer: 'TestStore', claims: [
        WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'broken', status: ClaimStatus.approved),
      ]);
      final json = w.toJson();
      final restored = WarrantyEntry.fromJson(json);
      expect(restored.productName, w.productName);
      expect(restored.brand, 'TestBrand');
      expect(restored.claims.length, 1);
      expect(restored.claims.first.status, ClaimStatus.approved);
    });

    test('exportToJson and importFromJson round-trip', () {
      service.addWarranty(_make(id: 'a'));
      service.addWarranty(_make(id: 'b', name: 'Other'));
      final exported = service.exportToJson();
      final service2 = WarrantyTrackerService();
      service2.importFromJson(exported);
      expect(service2.warranties.length, 2);
      expect(service2.warranties.last.productName, 'Other');
    });

    test('WarrantyClaim copyWith', () {
      final c = WarrantyClaim(id: 'c1', dateSubmitted: now, issue: 'old');
      final c2 = c.copyWith(status: ClaimStatus.denied, issue: 'new');
      expect(c2.status, ClaimStatus.denied);
      expect(c2.issue, 'new');
      expect(c2.id, 'c1');
    });
  });

  group('Enums', () {
    test('WarrantyCategory labels', () {
      for (final c in WarrantyCategory.values) {
        expect(c.label, isNotEmpty);
      }
    });

    test('WarrantyType labels', () {
      for (final t in WarrantyType.values) {
        expect(t.label, isNotEmpty);
      }
    });

    test('ClaimStatus labels', () {
      for (final s in ClaimStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });
}
