import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/gift_item.dart';
import 'package:everything/core/services/gift_service.dart';

void main() {
  const service = GiftService();

  GiftItem _gift({
    String name = 'Test Gift',
    String person = 'Alice',
    GiftOccasion occasion = GiftOccasion.birthday,
    GiftStatus status = GiftStatus.idea,
    GiftDirection direction = GiftDirection.giving,
    double? budget,
    double? actualCost,
    DateTime? occasionDate,
    bool thankYouSent = false,
    int rating = 0,
    List<String> tags = const [],
  }) =>
      GiftItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        recipientOrGiver: person,
        occasion: occasion,
        status: status,
        direction: direction,
        budget: budget,
        actualCost: actualCost,
        occasionDate: occasionDate,
        createdAt: DateTime.now(),
        thankYouSent: thankYouSent,
        rating: rating,
        tags: tags,
      );

  group('GiftItem model', () {
    test('copyWith preserves unchanged fields', () {
      final item = _gift(name: 'Book', person: 'Bob', budget: 25);
      final updated = item.copyWith(name: 'Notebook');
      expect(updated.name, 'Notebook');
      expect(updated.recipientOrGiver, 'Bob');
      expect(updated.budget, 25);
      expect(updated.id, item.id);
    });

    test('toggleThankYou flips the flag', () {
      final item = _gift(thankYouSent: false);
      expect(item.toggleThankYou().thankYouSent, true);
      expect(item.toggleThankYou().toggleThankYou().thankYouSent, false);
    });

    test('isOverBudget returns true when cost exceeds budget', () {
      expect(_gift(budget: 50, actualCost: 75).isOverBudget, true);
      expect(_gift(budget: 50, actualCost: 30).isOverBudget, false);
      expect(_gift(budget: 50).isOverBudget, false);
      expect(_gift(actualCost: 50).isOverBudget, false);
    });

    test('daysUntil calculates correctly', () {
      final future = _gift(
          occasionDate: DateTime.now().add(const Duration(days: 10)));
      expect(future.daysUntil, closeTo(10, 1));
      expect(future.isUpcoming, true);
      expect(future.isPast, false);
    });

    test('daysUntil is null without date', () {
      expect(_gift().daysUntil, isNull);
    });
  });

  group('GiftService', () {
    test('totalSpent sums giving gifts with actual cost', () {
      final items = [
        _gift(direction: GiftDirection.giving, actualCost: 50),
        _gift(direction: GiftDirection.giving, actualCost: 30),
        _gift(direction: GiftDirection.receiving, actualCost: 100),
        _gift(direction: GiftDirection.giving),
      ];
      expect(service.totalSpent(items), 80);
    });

    test('totalBudget sums giving gifts with budget', () {
      final items = [
        _gift(direction: GiftDirection.giving, budget: 50),
        _gift(direction: GiftDirection.giving, budget: 30),
        _gift(direction: GiftDirection.receiving, budget: 100),
      ];
      expect(service.totalBudget(items), 80);
    });

    test('totalSaved calculates budget minus actual', () {
      final items = [
        _gift(budget: 50, actualCost: 30),
        _gift(budget: 40, actualCost: 45),
      ];
      expect(service.totalSaved(items), 15); // 20 + (-5)
    });

    test('statusBreakdown counts by status', () {
      final items = [
        _gift(status: GiftStatus.idea),
        _gift(status: GiftStatus.idea),
        _gift(status: GiftStatus.purchased),
      ];
      final breakdown = service.statusBreakdown(items);
      expect(breakdown[GiftStatus.idea], 2);
      expect(breakdown[GiftStatus.purchased], 1);
    });

    test('occasionBreakdown counts by occasion', () {
      final items = [
        _gift(occasion: GiftOccasion.birthday),
        _gift(occasion: GiftOccasion.birthday),
        _gift(occasion: GiftOccasion.christmas),
      ];
      final breakdown = service.occasionBreakdown(items);
      expect(breakdown[GiftOccasion.birthday], 2);
      expect(breakdown[GiftOccasion.christmas], 1);
    });

    test('personBreakdown counts by person', () {
      final items = [
        _gift(person: 'Alice'),
        _gift(person: 'Alice'),
        _gift(person: 'Bob'),
      ];
      final breakdown = service.personBreakdown(items);
      expect(breakdown['Alice'], 2);
      expect(breakdown['Bob'], 1);
    });

    test('spendingPerPerson sums costs for giving', () {
      final items = [
        _gift(person: 'Alice', actualCost: 50),
        _gift(person: 'Alice', actualCost: 30),
        _gift(person: 'Bob', actualCost: 75),
        _gift(
            person: 'Carol',
            direction: GiftDirection.receiving,
            actualCost: 100),
      ];
      final spending = service.spendingPerPerson(items);
      expect(spending['Alice'], 80);
      expect(spending['Bob'], 75);
      expect(spending.containsKey('Carol'), false);
    });

    test('spendingPerOccasion sums by occasion', () {
      final items = [
        _gift(occasion: GiftOccasion.birthday, actualCost: 50),
        _gift(occasion: GiftOccasion.birthday, actualCost: 30),
        _gift(occasion: GiftOccasion.christmas, actualCost: 100),
      ];
      final spending = service.spendingPerOccasion(items);
      expect(spending[GiftOccasion.birthday], 80);
      expect(spending[GiftOccasion.christmas], 100);
    });

    test('upcoming returns items within window sorted by date', () {
      final items = [
        _gift(
            name: 'Soon',
            occasionDate: DateTime.now().add(const Duration(days: 5))),
        _gift(
            name: 'Later',
            occasionDate: DateTime.now().add(const Duration(days: 20))),
        _gift(
            name: 'TooFar',
            occasionDate: DateTime.now().add(const Duration(days: 100))),
        _gift(name: 'NoDate'),
        _gift(
            name: 'Past',
            occasionDate: DateTime.now().subtract(const Duration(days: 5))),
      ];
      final upcoming = service.upcoming(items, days: 30);
      expect(upcoming.length, 2);
      expect(upcoming[0].name, 'Soon');
      expect(upcoming[1].name, 'Later');
    });

    test('overBudget filters correctly', () {
      final items = [
        _gift(budget: 50, actualCost: 75),
        _gift(budget: 50, actualCost: 30),
        _gift(budget: null, actualCost: 100),
      ];
      expect(service.overBudget(items).length, 1);
    });

    test('pendingThankYou finds received gifts without thanks', () {
      final items = [
        _gift(
            direction: GiftDirection.receiving,
            status: GiftStatus.received,
            thankYouSent: false),
        _gift(
            direction: GiftDirection.receiving,
            status: GiftStatus.received,
            thankYouSent: true),
        _gift(
            direction: GiftDirection.giving,
            status: GiftStatus.given,
            thankYouSent: false),
      ];
      expect(service.pendingThankYou(items).length, 1);
    });

    test('avgRating ignores unrated items', () {
      final items = [
        _gift(rating: 5),
        _gift(rating: 3),
        _gift(rating: 0),
      ];
      expect(service.avgRating(items), 4.0);
    });

    test('avgRating returns 0 for empty list', () {
      expect(service.avgRating([]), 0);
    });

    test('topRecipient returns highest spender', () {
      final items = [
        _gift(person: 'Alice', actualCost: 100),
        _gift(person: 'Bob', actualCost: 200),
      ];
      expect(service.topRecipient(items), 'Bob');
    });

    test('topRecipient returns null for empty', () {
      expect(service.topRecipient([]), isNull);
    });

    test('monthlySpending groups by month in current year', () {
      final items = [
        GiftItem(
          id: '1',
          name: 'A',
          recipientOrGiver: 'X',
          occasion: GiftOccasion.birthday,
          status: GiftStatus.given,
          direction: GiftDirection.giving,
          actualCost: 50,
          createdAt: DateTime(DateTime.now().year, 3, 15),
        ),
        GiftItem(
          id: '2',
          name: 'B',
          recipientOrGiver: 'Y',
          occasion: GiftOccasion.christmas,
          status: GiftStatus.given,
          direction: GiftDirection.giving,
          actualCost: 75,
          createdAt: DateTime(DateTime.now().year, 3, 20),
        ),
      ];
      final monthly = service.monthlySpending(items);
      expect(monthly[3], 125);
    });

    test('ideaCount counts idea-status items', () {
      final items = [
        _gift(status: GiftStatus.idea),
        _gift(status: GiftStatus.idea),
        _gift(status: GiftStatus.purchased),
      ];
      expect(service.ideaCount(items), 2);
    });

    test('generateInsights returns starter message for empty', () {
      final insights = service.generateInsights([]);
      expect(insights.length, 1);
      expect(insights[0], contains('Start tracking'));
    });

    test('generateInsights includes spending info', () {
      final items = [
        _gift(actualCost: 50, budget: 75),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.contains('spent')), true);
    });

    test('generateInsights warns about over-budget', () {
      final items = [
        _gift(actualCost: 100, budget: 50),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.contains('over budget')), true);
    });

    test('generateInsights mentions pending thank-you', () {
      final items = [
        _gift(
            direction: GiftDirection.receiving,
            status: GiftStatus.received,
            thankYouSent: false),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.contains('thank-you')), true);
    });
  });

  group('GiftOccasion enum', () {
    test('all occasions have labels and emojis', () {
      for (final o in GiftOccasion.values) {
        expect(o.label, isNotEmpty);
        expect(o.emoji, isNotEmpty);
      }
    });

    test('has 13 occasions', () {
      expect(GiftOccasion.values.length, 13);
    });
  });

  group('GiftStatus enum', () {
    test('all statuses have labels and colors', () {
      for (final s in GiftStatus.values) {
        expect(s.label, isNotEmpty);
        expect(s.emoji, isNotEmpty);
        expect(s.color, isNotNull);
      }
    });

    test('has 6 statuses', () {
      expect(GiftStatus.values.length, 6);
    });
  });

  group('GiftDirection enum', () {
    test('has giving and receiving', () {
      expect(GiftDirection.values.length, 2);
      expect(GiftDirection.giving.label, 'Giving');
      expect(GiftDirection.receiving.label, 'Receiving');
    });
  });
}
