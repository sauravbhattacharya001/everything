import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/contact.dart';
import 'package:everything/core/services/contact_tracker_service.dart';

void main() {
  late ContactTrackerService sut;
  final now = DateTime(2026, 3, 4, 12, 0);

  setUp(() {
    sut = ContactTrackerService();
  });

  // ── Enum Tests ───────────────────────────────────────────

  group('RelationshipCategory', () {
    test('all categories have labels', () {
      for (final cat in RelationshipCategory.values) {
        expect(cat.label, isNotEmpty);
      }
    });

    test('all categories have emojis', () {
      for (final cat in RelationshipCategory.values) {
        expect(cat.emoji, isNotEmpty);
      }
    });
  });

  group('ContactFrequency', () {
    test('days returns correct values', () {
      expect(ContactFrequency.daily.days, 1);
      expect(ContactFrequency.weekly.days, 7);
      expect(ContactFrequency.biweekly.days, 14);
      expect(ContactFrequency.monthly.days, 30);
      expect(ContactFrequency.quarterly.days, 90);
      expect(ContactFrequency.yearly.days, 365);
      expect(ContactFrequency.asNeeded.days, isNull);
    });

    test('all frequencies have labels', () {
      for (final f in ContactFrequency.values) {
        expect(f.label, isNotEmpty);
      }
    });
  });

  group('ContactMethod', () {
    test('all methods have labels', () {
      for (final m in ContactMethod.values) {
        expect(m.label, isNotEmpty);
      }
    });
  });

  // ── Contact Model Tests ──────────────────────────────────

  group('Contact model', () {
    test('displayName returns nickname if set', () {
      final c = Contact(
        id: '1', name: 'Robert Smith', nickname: 'Bob',
        category: RelationshipCategory.friend, createdAt: now,
      );
      expect(c.displayName, 'Bob');
    });

    test('displayName returns name when no nickname', () {
      final c = Contact(
        id: '1', name: 'Alice',
        category: RelationshipCategory.friend, createdAt: now,
      );
      expect(c.displayName, 'Alice');
    });

    test('daysSinceLastContact returns null when no interactions', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.other, createdAt: now,
      );
      expect(c.daysSinceLastContact(now), isNull);
    });

    test('daysSinceLastContact calculates correctly', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.other, createdAt: now,
        interactions: [
          Interaction(id: 'i1', date: now.subtract(const Duration(days: 5)),
              note: 'Call', method: ContactMethod.phone),
        ],
      );
      expect(c.daysSinceLastContact(now), 5);
    });

    test('isOverdue true when past frequency cycle', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.weekly, createdAt: now,
        interactions: [
          Interaction(id: 'i1', date: now.subtract(const Duration(days: 10)),
              note: 'Lunch', method: ContactMethod.inPerson),
        ],
      );
      expect(c.isOverdue(now), isTrue);
    });

    test('isOverdue false when within frequency cycle', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.monthly, createdAt: now,
        interactions: [
          Interaction(id: 'i1', date: now.subtract(const Duration(days: 5)),
              note: 'Coffee', method: ContactMethod.inPerson),
        ],
      );
      expect(c.isOverdue(now), isFalse);
    });

    test('isOverdue true when never contacted', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.weekly, createdAt: now,
      );
      expect(c.isOverdue(now), isTrue);
    });

    test('isOverdue false for asNeeded frequency', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.other,
        desiredFrequency: ContactFrequency.asNeeded, createdAt: now,
      );
      expect(c.isOverdue(now), isFalse);
    });

    test('daysUntilDue returns null for asNeeded', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.other,
        desiredFrequency: ContactFrequency.asNeeded, createdAt: now,
      );
      expect(c.daysUntilDue(now), isNull);
    });

    test('daysUntilDue returns 0 when never contacted', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.weekly, createdAt: now,
      );
      expect(c.daysUntilDue(now), 0);
    });

    test('daysUntilDue positive when not yet due', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.monthly, createdAt: now,
        interactions: [
          Interaction(id: 'i1', date: now.subtract(const Duration(days: 10)),
              note: 'Chat', method: ContactMethod.text),
        ],
      );
      expect(c.daysUntilDue(now), 20);
    });

    test('daysUntilDue negative when overdue', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.weekly, createdAt: now,
        interactions: [
          Interaction(id: 'i1', date: now.subtract(const Duration(days: 10)),
              note: 'Chat', method: ContactMethod.text),
        ],
      );
      expect(c.daysUntilDue(now), -3);
    });

    test('hasBirthdaySoon detects upcoming birthday', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend, createdAt: now,
        birthday: DateTime(1990, 3, 20),
      );
      expect(c.hasBirthdaySoon(now, withinDays: 30), isTrue);
    });

    test('hasBirthdaySoon false for distant birthday', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend, createdAt: now,
        birthday: DateTime(1990, 9, 15),
      );
      expect(c.hasBirthdaySoon(now, withinDays: 30), isFalse);
    });

    test('daysUntilBirthday returns null without birthday', () {
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend, createdAt: now,
      );
      expect(c.daysUntilBirthday(now), isNull);
    });

    test('hasBirthdaySoon wraps around year boundary', () {
      final dec20 = DateTime(2026, 12, 20);
      final c = Contact(
        id: '1', name: 'Test',
        category: RelationshipCategory.friend, createdAt: dec20,
        birthday: DateTime(1990, 1, 5),
      );
      expect(c.hasBirthdaySoon(dec20, withinDays: 30), isTrue);
    });

    test('toJson and fromJson round-trip', () {
      final c = Contact(
        id: 'c-1', name: 'Jane Doe', nickname: 'Janey',
        category: RelationshipCategory.friend,
        preferredMethod: ContactMethod.videoCall,
        desiredFrequency: ContactFrequency.biweekly,
        email: 'jane@example.com', phone: '555-1234',
        company: 'Acme', notes: 'Met at conference',
        tags: ['tech', 'conf'],
        birthday: DateTime(1992, 6, 15), createdAt: now,
        interactions: [
          Interaction(id: 'i1', date: now, note: 'Video call',
              method: ContactMethod.videoCall,
              duration: const Duration(minutes: 30)),
        ],
      );
      final json = c.toJson();
      final restored = Contact.fromJson(json);
      expect(restored.id, c.id);
      expect(restored.name, c.name);
      expect(restored.nickname, c.nickname);
      expect(restored.category, c.category);
      expect(restored.preferredMethod, c.preferredMethod);
      expect(restored.desiredFrequency, c.desiredFrequency);
      expect(restored.email, c.email);
      expect(restored.phone, c.phone);
      expect(restored.company, c.company);
      expect(restored.notes, c.notes);
      expect(restored.tags, c.tags);
      expect(restored.interactions.length, 1);
      expect(restored.interactions[0].duration!.inMinutes, 30);
      expect(restored.birthday!.month, 6);
      expect(restored.archived, false);
    });

    test('copyWith preserves unmodified fields', () {
      final c = Contact(
        id: '1', name: 'Original',
        category: RelationshipCategory.family, createdAt: now,
        tags: ['a'],
      );
      final updated = c.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.category, RelationshipCategory.family);
      expect(updated.tags, ['a']);
    });

    test('toString includes key fields', () {
      final c = Contact(
        id: '1', name: 'Alice',
        category: RelationshipCategory.friend, createdAt: now,
      );
      expect(c.toString(), contains('Alice'));
      expect(c.toString(), contains('Friend'));
    });
  });

  // ── Interaction Model Tests ──────────────────────────────

  group('Interaction model', () {
    test('toJson and fromJson round-trip', () {
      final i = Interaction(
        id: 'i-1', date: now, note: 'Had coffee',
        method: ContactMethod.inPerson,
        duration: const Duration(minutes: 45),
      );
      final restored = Interaction.fromJson(i.toJson());
      expect(restored.id, i.id);
      expect(restored.note, i.note);
      expect(restored.method, ContactMethod.inPerson);
      expect(restored.duration!.inMinutes, 45);
    });

    test('toJson omits null duration', () {
      final i = Interaction(
        id: 'i-1', date: now, note: 'Quick text',
        method: ContactMethod.text,
      );
      expect(i.toJson().containsKey('durationMinutes'), isFalse);
    });
  });

  // ── Service: addContact ──────────────────────────────────

  group('addContact', () {
    test('creates contact with generated ID', () {
      final c = sut.addContact(
        name: 'Alice', category: RelationshipCategory.friend, now: now,
      );
      expect(c.id, 'contact-1');
      expect(c.name, 'Alice');
      expect(sut.contacts.length, 1);
    });

    test('trims name and optional fields', () {
      final c = sut.addContact(
        name: '  Bob  ', nickname: ' Bobby ', company: ' Acme Corp ',
        category: RelationshipCategory.colleague, now: now,
      );
      expect(c.name, 'Bob');
      expect(c.nickname, 'Bobby');
      expect(c.company, 'Acme Corp');
    });

    test('throws on empty name', () {
      expect(
        () => sut.addContact(name: '', category: RelationshipCategory.other),
        throwsArgumentError,
      );
    });

    test('throws on whitespace-only name', () {
      expect(
        () => sut.addContact(name: '   ', category: RelationshipCategory.other),
        throwsArgumentError,
      );
    });

    test('increments IDs', () {
      final c1 = sut.addContact(
          name: 'A', category: RelationshipCategory.friend, now: now);
      final c2 = sut.addContact(
          name: 'B', category: RelationshipCategory.friend, now: now);
      expect(c1.id, 'contact-1');
      expect(c2.id, 'contact-2');
    });

    test('sets default frequency and method', () {
      final c = sut.addContact(
          name: 'Default', category: RelationshipCategory.other, now: now);
      expect(c.desiredFrequency, ContactFrequency.monthly);
      expect(c.preferredMethod, ContactMethod.text);
    });
  });

  // ── Service: updateContact ───────────────────────────────

  group('updateContact', () {
    test('updates existing contact', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      final updated =
          sut.updateContact(c.id, (c) => c.copyWith(name: 'Alicia'));
      expect(updated.name, 'Alicia');
      expect(sut.getContact(c.id)!.name, 'Alicia');
    });

    test('throws on unknown ID', () {
      expect(
        () => sut.updateContact('nonexistent', (c) => c),
        throwsArgumentError,
      );
    });
  });

  // ── Service: archive/remove ──────────────────────────────

  group('archiveContact', () {
    test('archives contact', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      sut.archiveContact(c.id);
      expect(sut.getContact(c.id)!.archived, isTrue);
      expect(sut.activeContacts(), isEmpty);
    });

    test('unarchiveContact restores contact', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      sut.archiveContact(c.id);
      sut.unarchiveContact(c.id);
      expect(sut.getContact(c.id)!.archived, isFalse);
      expect(sut.activeContacts().length, 1);
    });
  });

  group('removeContact', () {
    test('removes contact permanently', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      final removed = sut.removeContact(c.id);
      expect(removed, isTrue);
      expect(sut.contacts, isEmpty);
    });

    test('returns false for unknown contact', () {
      expect(sut.removeContact('nope'), isFalse);
    });
  });

  // ── Service: getContact ──────────────────────────────────

  group('getContact', () {
    test('returns null for unknown ID', () {
      expect(sut.getContact('nope'), isNull);
    });

    test('returns contact by ID', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      expect(sut.getContact(c.id)!.name, 'Alice');
    });
  });

  // ── Service: logInteraction ──────────────────────────────

  group('logInteraction', () {
    test('adds interaction to contact', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      final i = sut.logInteraction(
        contactId: c.id, note: 'Had lunch',
        method: ContactMethod.inPerson, date: now,
      );
      expect(i.id, 'interaction-1');
      expect(sut.getContact(c.id)!.interactions.length, 1);
    });

    test('keeps interactions sorted by date', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      sut.logInteraction(
        contactId: c.id, note: 'Recent',
        method: ContactMethod.text, date: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Older',
        method: ContactMethod.phone,
        date: now.subtract(const Duration(days: 5)),
      );
      final interactions = sut.getContact(c.id)!.interactions;
      expect(interactions[0].note, 'Older');
      expect(interactions[1].note, 'Recent');
    });

    test('throws for unknown contact', () {
      expect(
        () => sut.logInteraction(
            contactId: 'nope', note: 'Hi', method: ContactMethod.text),
        throwsArgumentError,
      );
    });

    test('records duration', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      sut.logInteraction(
        contactId: c.id, note: 'Long call',
        method: ContactMethod.phone,
        duration: const Duration(hours: 1), date: now,
      );
      expect(sut.getContact(c.id)!.interactions[0].duration!.inMinutes, 60);
    });
  });

  // ── Service: filtering ───────────────────────────────────

  group('filtering', () {
    setUp(() {
      sut.addContact(
        name: 'Mom', category: RelationshipCategory.family,
        tags: ['important'], now: now,
      );
      sut.addContact(
        name: 'Bob', category: RelationshipCategory.friend,
        company: 'TechCorp', tags: ['tech'], now: now,
      );
      sut.addContact(
        name: 'Carol', category: RelationshipCategory.colleague,
        notes: 'Met at AI conference', tags: ['tech', 'ai'], now: now,
      );
    });

    test('byCategory filters correctly', () {
      expect(sut.byCategory(RelationshipCategory.family).length, 1);
      expect(sut.byCategory(RelationshipCategory.friend).length, 1);
      expect(sut.byCategory(RelationshipCategory.mentor).length, 0);
    });

    test('byTag filters correctly', () {
      expect(sut.byTag('tech').length, 2);
      expect(sut.byTag('ai').length, 1);
      expect(sut.byTag('none').length, 0);
    });

    test('search matches name', () {
      expect(sut.search('mom').length, 1);
    });

    test('search matches company', () {
      expect(sut.search('techcorp').length, 1);
    });

    test('search matches notes', () {
      expect(sut.search('conference').length, 1);
    });

    test('search matches tags', () {
      expect(sut.search('ai').length, 1);
    });

    test('search is case-insensitive', () {
      expect(sut.search('BOB').length, 1);
    });

    test('search matches nickname', () {
      sut.addContact(
        name: 'Elizabeth', nickname: 'Liz',
        category: RelationshipCategory.friend, now: now,
      );
      expect(sut.search('liz').length, 1);
    });

    test('activeContacts excludes archived', () {
      final c = sut.contacts[0];
      sut.archiveContact(c.id);
      expect(sut.activeContacts().length, 2);
    });
  });

  // ── Service: overdueContacts ─────────────────────────────

  group('overdueContacts', () {
    test('identifies overdue contacts', () {
      final c = sut.addContact(
        name: 'Alice', category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.weekly, now: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Chat', method: ContactMethod.text,
        date: now.subtract(const Duration(days: 14)),
      );
      final overdue = sut.overdueContacts(now);
      expect(overdue.length, 1);
      expect(overdue[0].daysOverdue, 7);
    });

    test('never-contacted contacts are overdue', () {
      sut.addContact(
        name: 'Ghost', category: RelationshipCategory.acquaintance,
        desiredFrequency: ContactFrequency.monthly, now: now,
      );
      expect(sut.overdueContacts(now).length, 1);
    });

    test('on-track contacts not in overdue list', () {
      final c = sut.addContact(
        name: 'Active', category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.monthly, now: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Recent chat', method: ContactMethod.text,
        date: now.subtract(const Duration(days: 2)),
      );
      expect(sut.overdueContacts(now), isEmpty);
    });

    test('asNeeded contacts never overdue', () {
      sut.addContact(
        name: 'Chill', category: RelationshipCategory.acquaintance,
        desiredFrequency: ContactFrequency.asNeeded, now: now,
      );
      expect(sut.overdueContacts(now), isEmpty);
    });

    test('overdue sorted by urgency score descending', () {
      final fam = sut.addContact(
        name: 'Mom', category: RelationshipCategory.family,
        desiredFrequency: ContactFrequency.weekly, now: now,
      );
      sut.logInteraction(
        contactId: fam.id, note: 'Call', method: ContactMethod.phone,
        date: now.subtract(const Duration(days: 14)),
      );

      final acq = sut.addContact(
        name: 'Neighbor', category: RelationshipCategory.acquaintance,
        desiredFrequency: ContactFrequency.weekly, now: now,
      );
      sut.logInteraction(
        contactId: acq.id, note: 'Wave', method: ContactMethod.inPerson,
        date: now.subtract(const Duration(days: 14)),
      );

      final overdue = sut.overdueContacts(now);
      expect(overdue.length, 2);
      expect(overdue[0].contact.name, 'Mom');
    });

    test('urgency score is clamped to 0-100', () {
      final c = sut.addContact(
        name: 'Very Overdue', category: RelationshipCategory.family,
        desiredFrequency: ContactFrequency.daily, now: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Old', method: ContactMethod.text,
        date: now.subtract(const Duration(days: 100)),
      );
      final overdue = sut.overdueContacts(now);
      expect(overdue[0].urgencyScore, lessThanOrEqualTo(100));
    });
  });

  // ── Service: upcomingBirthdays ───────────────────────────

  group('upcomingBirthdays', () {
    test('finds birthdays within window', () {
      sut.addContact(
        name: 'March Person', category: RelationshipCategory.friend,
        birthday: DateTime(1990, 3, 20), now: now,
      );
      sut.addContact(
        name: 'September Person', category: RelationshipCategory.friend,
        birthday: DateTime(1995, 9, 1), now: now,
      );
      final birthdays = sut.upcomingBirthdays(now, withinDays: 30);
      expect(birthdays.length, 1);
      expect(birthdays[0].contact.name, 'March Person');
      expect(birthdays[0].daysUntil, 16);
    });

    test('calculates turning age', () {
      sut.addContact(
        name: 'Young', category: RelationshipCategory.friend,
        birthday: DateTime(2000, 3, 10), now: now,
      );
      final birthdays = sut.upcomingBirthdays(now);
      expect(birthdays[0].turningAge, 26);
    });

    test('sorted by days until', () {
      sut.addContact(
        name: 'Later', category: RelationshipCategory.friend,
        birthday: DateTime(1990, 3, 25), now: now,
      );
      sut.addContact(
        name: 'Sooner', category: RelationshipCategory.friend,
        birthday: DateTime(1990, 3, 10), now: now,
      );
      final birthdays = sut.upcomingBirthdays(now);
      expect(birthdays[0].contact.name, 'Sooner');
    });

    test('excludes archived contacts', () {
      final c = sut.addContact(
        name: 'Archived', category: RelationshipCategory.friend,
        birthday: DateTime(1990, 3, 10), now: now,
      );
      sut.archiveContact(c.id);
      expect(sut.upcomingBirthdays(now), isEmpty);
    });
  });

  // ── Service: interactionTrends ───────────────────────────

  group('interactionTrends', () {
    test('needs at least 2 interactions for a trend', () {
      final c = sut.addContact(
          name: 'Sparse', category: RelationshipCategory.friend, now: now);
      sut.logInteraction(
        contactId: c.id, note: 'Only one', method: ContactMethod.text,
        date: now,
      );
      expect(sut.interactionTrends(), isEmpty);
    });

    test('computes stable trend for regular interactions', () {
      final c = sut.addContact(
          name: 'Regular', category: RelationshipCategory.friend, now: now);
      for (var i = 5; i >= 0; i--) {
        sut.logInteraction(
          contactId: c.id, note: 'Chat $i', method: ContactMethod.text,
          date: now.subtract(Duration(days: i * 7)),
        );
      }
      final trends = sut.interactionTrends();
      expect(trends.length, 1);
      expect(trends[0].trend, 'stable');
      expect(trends[0].totalInteractions, 6);
    });

    test('detects increasing frequency', () {
      final c = sut.addContact(
          name: 'Closer', category: RelationshipCategory.friend, now: now);
      // Gaps: 30, 20, 5, 3, 2 — getting more frequent
      final daysAgo = [60, 30, 10, 5, 2, 0];
      for (var i = 0; i < daysAgo.length; i++) {
        sut.logInteraction(
          contactId: c.id, note: 'Chat $i', method: ContactMethod.text,
          date: now.subtract(Duration(days: daysAgo[i])),
        );
      }
      final trends = sut.interactionTrends();
      expect(trends.length, 1);
      expect(trends[0].trend, 'increasing');
    });

    test('computes average days between interactions', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      sut.logInteraction(
        contactId: c.id, note: 'First', method: ContactMethod.text,
        date: now.subtract(const Duration(days: 20)),
      );
      sut.logInteraction(
        contactId: c.id, note: 'Second', method: ContactMethod.text,
        date: now.subtract(const Duration(days: 10)),
      );
      sut.logInteraction(
        contactId: c.id, note: 'Third', method: ContactMethod.text, date: now,
      );
      final trends = sut.interactionTrends();
      expect(trends[0].avgDaysBetween, 10.0);
    });
  });

  // ── Service: networkHealth ───────────────────────────────

  group('networkHealth', () {
    test('empty network returns F grade', () {
      final health = sut.networkHealth(now);
      expect(health.totalContacts, 0);
      expect(health.grade, 'F');
      expect(health.healthScore, 0);
    });

    test('all on-track contacts gives A grade', () {
      for (var i = 0; i < 5; i++) {
        final c = sut.addContact(
          name: 'Person $i', category: RelationshipCategory.friend,
          desiredFrequency: ContactFrequency.monthly, now: now,
        );
        sut.logInteraction(
          contactId: c.id, note: 'Recent', method: ContactMethod.text,
          date: now.subtract(const Duration(days: 2)),
        );
      }
      final health = sut.networkHealth(now);
      expect(health.grade, 'A');
      expect(health.activeContacts, 5);
      expect(health.overdueContacts, 0);
    });

    test('never-contacted penalizes health score', () {
      sut.addContact(
        name: 'Ghost', category: RelationshipCategory.acquaintance,
        desiredFrequency: ContactFrequency.monthly, now: now,
      );
      final health = sut.networkHealth(now);
      expect(health.neverContacted, 1);
      expect(health.healthScore, lessThan(100));
    });

    test('category breakdown computed correctly', () {
      sut.addContact(
          name: 'A', category: RelationshipCategory.family, now: now);
      sut.addContact(
          name: 'B', category: RelationshipCategory.family, now: now);
      sut.addContact(
          name: 'C', category: RelationshipCategory.friend, now: now);
      final health = sut.networkHealth(now);
      expect(health.categoryBreakdown.length, 2);
      expect(health.categoryBreakdown[0].count, 2);
    });

    test('method distribution tracks interaction methods', () {
      final c = sut.addContact(
          name: 'Alice', category: RelationshipCategory.friend, now: now);
      sut.logInteraction(
          contactId: c.id, note: 'a', method: ContactMethod.text, date: now);
      sut.logInteraction(
          contactId: c.id, note: 'b', method: ContactMethod.text, date: now);
      sut.logInteraction(
          contactId: c.id, note: 'c', method: ContactMethod.phone, date: now);
      final health = sut.networkHealth(now);
      expect(health.methodDistribution[ContactMethod.text], 2);
      expect(health.methodDistribution[ContactMethod.phone], 1);
    });

    test('health score between 0 and 100', () {
      for (var i = 0; i < 3; i++) {
        sut.addContact(
          name: 'Person $i', category: RelationshipCategory.friend,
          desiredFrequency: ContactFrequency.weekly, now: now,
        );
      }
      final health = sut.networkHealth(now);
      expect(health.healthScore, greaterThanOrEqualTo(0));
      expect(health.healthScore, lessThanOrEqualTo(100));
    });
  });

  // ── Service: generateReport ──────────────────────────────

  group('generateReport', () {
    test('produces text summary', () {
      final c = sut.addContact(
        name: 'Alice', category: RelationshipCategory.friend,
        desiredFrequency: ContactFrequency.weekly, now: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Coffee', method: ContactMethod.inPerson,
        date: now.subtract(const Duration(days: 2)),
      );
      final report = sut.generateReport(now);
      expect(report.textSummary, contains('Contact Network Report'));
      expect(report.totalInteractions, 1);
      expect(report.mostContacted!.name, 'Alice');
    });

    test('report includes overdue follow-ups', () {
      final c = sut.addContact(
        name: 'Neglected', category: RelationshipCategory.family,
        desiredFrequency: ContactFrequency.weekly, now: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Long ago', method: ContactMethod.phone,
        date: now.subtract(const Duration(days: 30)),
      );
      final report = sut.generateReport(now);
      expect(report.overdueFollowUps.length, 1);
      expect(report.textSummary, contains('Overdue'));
    });

    test('report includes upcoming birthdays', () {
      sut.addContact(
        name: 'Birthday Person', category: RelationshipCategory.friend,
        birthday: DateTime(1995, 3, 15), now: now,
      );
      final report = sut.generateReport(now);
      expect(report.upcomingBirthdays.length, 1);
      expect(report.textSummary, contains('Birthday'));
    });

    test('report identifies most and least contacted', () {
      final a = sut.addContact(
          name: 'Frequent', category: RelationshipCategory.friend, now: now);
      final b = sut.addContact(
          name: 'Sparse', category: RelationshipCategory.friend, now: now);
      for (var i = 0; i < 5; i++) {
        sut.logInteraction(
          contactId: a.id, note: 'Chat $i', method: ContactMethod.text,
          date: now.subtract(Duration(days: i)),
        );
      }
      sut.logInteraction(
        contactId: b.id, note: 'Once', method: ContactMethod.text, date: now,
      );
      final report = sut.generateReport(now);
      expect(report.mostContacted!.name, 'Frequent');
      expect(report.leastContacted!.name, 'Sparse');
    });
  });

  // ── Service: persistence ─────────────────────────────────

  group('persistence', () {
    test('toJson and loadJson round-trip', () {
      final c = sut.addContact(
        name: 'Alice', nickname: 'Ali',
        category: RelationshipCategory.friend,
        email: 'alice@example.com', tags: ['close'],
        birthday: DateTime(1995, 6, 15), now: now,
      );
      sut.logInteraction(
        contactId: c.id, note: 'Coffee date',
        method: ContactMethod.inPerson,
        duration: const Duration(minutes: 60), date: now,
      );

      final json = sut.toJson();
      final restored = ContactTrackerService();
      restored.loadJson(json);

      expect(restored.contacts.length, 1);
      expect(restored.contacts[0].name, 'Alice');
      expect(restored.contacts[0].nickname, 'Ali');
      expect(restored.contacts[0].interactions.length, 1);
      expect(restored.contacts[0].interactions[0].duration!.inMinutes, 60);
    });

    test('loadJson clears existing data', () {
      sut.addContact(
          name: 'Old', category: RelationshipCategory.other, now: now);
      final other = ContactTrackerService();
      other.addContact(
          name: 'New', category: RelationshipCategory.friend, now: now);
      sut.loadJson(other.toJson());
      expect(sut.contacts.length, 1);
      expect(sut.contacts[0].name, 'New');
    });
  });
}
