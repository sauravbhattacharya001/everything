import 'dart:convert';

import '../../models/contact.dart';

/// Statistics for a relationship category.
class CategoryStats {
  final RelationshipCategory category;
  final int count;
  final int overdueCount;
  final double avgDaysSinceContact;

  const CategoryStats({
    required this.category,
    required this.count,
    required this.overdueCount,
    required this.avgDaysSinceContact,
  });
}

/// A contact needing follow-up with urgency scoring.
class FollowUpReminder {
  final Contact contact;
  final int daysOverdue;
  final double urgencyScore;

  const FollowUpReminder({
    required this.contact,
    required this.daysOverdue,
    required this.urgencyScore,
  });
}

/// Interaction frequency trend for a contact.
class InteractionTrend {
  final Contact contact;
  final double avgDaysBetween;
  final int totalInteractions;
  final String trend; // 'increasing', 'decreasing', 'stable'

  const InteractionTrend({
    required this.contact,
    required this.avgDaysBetween,
    required this.totalInteractions,
    required this.trend,
  });
}

/// Birthday coming up soon.
class UpcomingBirthday {
  final Contact contact;
  final int daysUntil;
  final int? turningAge;

  const UpcomingBirthday({
    required this.contact,
    required this.daysUntil,
    this.turningAge,
  });
}

/// Network health overview.
class NetworkHealth {
  final int totalContacts;
  final int activeContacts;
  final int overdueContacts;
  final int neverContacted;
  final double healthScore;
  final List<CategoryStats> categoryBreakdown;
  final Map<ContactMethod, int> methodDistribution;
  final String grade;

  const NetworkHealth({
    required this.totalContacts,
    required this.activeContacts,
    required this.overdueContacts,
    required this.neverContacted,
    required this.healthScore,
    required this.categoryBreakdown,
    required this.methodDistribution,
    required this.grade,
  });
}

/// Full contact network report.
class ContactReport {
  final NetworkHealth health;
  final List<FollowUpReminder> overdueFollowUps;
  final List<UpcomingBirthday> upcomingBirthdays;
  final List<InteractionTrend> trends;
  final Contact? mostContacted;
  final Contact? leastContacted;
  final int totalInteractions;
  final String textSummary;

  const ContactReport({
    required this.health,
    required this.overdueFollowUps,
    required this.upcomingBirthdays,
    required this.trends,
    this.mostContacted,
    this.leastContacted,
    required this.totalInteractions,
    required this.textSummary,
  });
}

/// Service for managing contacts, interactions, and relationship health.
class ContactTrackerService {
  /// Maximum contacts allowed via [loadJson] to prevent memory exhaustion
  /// from corrupted or malicious import data (CWE-770).
  static const int maxImportEntries = 50000;

  final List<Contact> _contacts = [];
  int _nextId = 1;
  int _nextInteractionId = 1;

  List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Add a new contact. Returns the created contact with generated ID.
  Contact addContact({
    required String name,
    String? nickname,
    required RelationshipCategory category,
    ContactMethod preferredMethod = ContactMethod.text,
    ContactFrequency desiredFrequency = ContactFrequency.monthly,
    String? email,
    String? phone,
    String? company,
    String? notes,
    List<String> tags = const [],
    DateTime? birthday,
    DateTime? now,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Contact name cannot be empty');
    }
    final contact = Contact(
      id: 'contact-${_nextId++}',
      name: name.trim(),
      nickname: nickname?.trim(),
      category: category,
      preferredMethod: preferredMethod,
      desiredFrequency: desiredFrequency,
      email: email?.trim(),
      phone: phone?.trim(),
      company: company?.trim(),
      notes: notes?.trim(),
      tags: tags,
      birthday: birthday,
      createdAt: now ?? DateTime.now(),
    );
    _contacts.add(contact);
    return contact;
  }

  /// Update an existing contact by ID.
  Contact updateContact(String id, Contact Function(Contact) updater) {
    final idx = _contacts.indexWhere((c) => c.id == id);
    if (idx == -1) throw ArgumentError('Contact not found: $id');
    final updated = updater(_contacts[idx]);
    _contacts[idx] = updated;
    return updated;
  }

  /// Archive a contact (soft delete).
  void archiveContact(String id) {
    updateContact(id, (c) => c.copyWith(archived: true));
  }

  /// Unarchive a contact.
  void unarchiveContact(String id) {
    updateContact(id, (c) => c.copyWith(archived: false));
  }

  /// Remove a contact permanently.
  bool removeContact(String id) {
    final idx = _contacts.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    _contacts.removeAt(idx);
    return true;
  }

  /// Get a contact by ID, or null if not found.
  Contact? getContact(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Log an interaction with a contact.
  Interaction logInteraction({
    required String contactId,
    required String note,
    required ContactMethod method,
    Duration? duration,
    DateTime? date,
  }) {
    final idx = _contacts.indexWhere((c) => c.id == contactId);
    if (idx == -1) throw ArgumentError('Contact not found: $contactId');

    final interaction = Interaction(
      id: 'interaction-${_nextInteractionId++}',
      date: date ?? DateTime.now(),
      note: note,
      method: method,
      duration: duration,
    );

    final contact = _contacts[idx];
    final updatedInteractions = [...contact.interactions, interaction];
    updatedInteractions.sort((a, b) => a.date.compareTo(b.date));
    _contacts[idx] = contact.copyWith(interactions: updatedInteractions);
    return interaction;
  }

  /// Get active (non-archived) contacts.
  List<Contact> activeContacts() =>
      _contacts.where((c) => !c.archived).toList();

  /// Get contacts by category.
  List<Contact> byCategory(RelationshipCategory category) =>
      activeContacts().where((c) => c.category == category).toList();

  /// Get contacts by tag.
  List<Contact> byTag(String tag) =>
      activeContacts().where((c) => c.tags.contains(tag)).toList();

  /// Search contacts by name, nickname, company, notes, or tags.
  List<Contact> search(String query) {
    final q = query.toLowerCase();
    return activeContacts().where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.nickname?.toLowerCase().contains(q) ?? false) ||
          (c.company?.toLowerCase().contains(q) ?? false) ||
          (c.notes?.toLowerCase().contains(q) ?? false) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// Get contacts that are overdue for follow-up.
  List<FollowUpReminder> overdueContacts(DateTime now) {
    final reminders = <FollowUpReminder>[];
    for (final contact in activeContacts()) {
      if (!contact.isOverdue(now)) continue;
      final daysSince = contact.daysSinceLastContact(now);
      final cycleDays = contact.desiredFrequency.days;
      if (cycleDays == null) continue;
      final daysOverdue = (daysSince ?? cycleDays) - cycleDays;
      final categoryWeight = _categoryWeight(contact.category);
      final urgency = (daysOverdue / cycleDays) * 50 + categoryWeight * 50;
      reminders.add(FollowUpReminder(
        contact: contact,
        daysOverdue: daysOverdue < 0 ? 0 : daysOverdue,
        urgencyScore: urgency.clamp(0, 100),
      ));
    }
    reminders.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    return reminders;
  }

  /// Get contacts with upcoming birthdays.
  List<UpcomingBirthday> upcomingBirthdays(DateTime now,
      {int withinDays = 30}) {
    final birthdays = <UpcomingBirthday>[];
    for (final contact in activeContacts()) {
      if (!contact.hasBirthdaySoon(now, withinDays: withinDays)) continue;
      final daysUntil = contact.daysUntilBirthday(now)!;
      int? turningAge;
      if (contact.birthday != null) {
        turningAge = now.year - contact.birthday!.year;
        final thisYearBday =
            DateTime(now.year, contact.birthday!.month, contact.birthday!.day);
        if (thisYearBday.isBefore(now) &&
            !thisYearBday.isAtSameMomentAs(now)) {
          turningAge += 1;
        }
      }
      birthdays.add(UpcomingBirthday(
        contact: contact,
        daysUntil: daysUntil,
        turningAge: turningAge,
      ));
    }
    birthdays.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return birthdays;
  }

  /// Compute interaction trends per contact.
  List<InteractionTrend> interactionTrends() {
    final trends = <InteractionTrend>[];
    for (final contact in activeContacts()) {
      if (contact.interactions.length < 2) continue;
      final sorted = List.of(contact.interactions)
        ..sort((a, b) => a.date.compareTo(b.date));
      final gaps = <int>[];
      for (var i = 1; i < sorted.length; i++) {
        gaps.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
      }
      final avgDays = gaps.reduce((a, b) => a + b) / gaps.length;

      String trend;
      if (gaps.length >= 4) {
        final mid = gaps.length ~/ 2;
        final firstHalf = gaps.sublist(0, mid);
        final secondHalf = gaps.sublist(mid);
        final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg =
            secondHalf.reduce((a, b) => a + b) / secondHalf.length;
        if (secondAvg < firstAvg * 0.8) {
          trend = 'increasing';
        } else if (secondAvg > firstAvg * 1.2) {
          trend = 'decreasing';
        } else {
          trend = 'stable';
        }
      } else {
        trend = 'stable';
      }

      trends.add(InteractionTrend(
        contact: contact,
        avgDaysBetween: avgDays,
        totalInteractions: contact.interactions.length,
        trend: trend,
      ));
    }
    return trends;
  }

  /// Compute network health score and stats.
  NetworkHealth networkHealth(DateTime now) {
    final active = activeContacts();
    if (active.isEmpty) {
      return const NetworkHealth(
        totalContacts: 0,
        activeContacts: 0,
        overdueContacts: 0,
        neverContacted: 0,
        healthScore: 0,
        categoryBreakdown: [],
        methodDistribution: {},
        grade: 'F',
      );
    }

    int overdue = 0;
    int neverContacted = 0;
    int onTrack = 0;

    for (final c in active) {
      if (c.interactions.isEmpty) {
        neverContacted++;
      } else if (c.isOverdue(now)) {
        overdue++;
      } else {
        onTrack++;
      }
    }

    final catMap = <RelationshipCategory, List<Contact>>{};
    for (final c in active) {
      catMap.putIfAbsent(c.category, () => []).add(c);
    }
    final categoryBreakdown = catMap.entries.map((e) {
      final overdueInCat = e.value.where((c) => c.isOverdue(now)).length;
      final daysList = e.value
          .map((c) => c.daysSinceLastContact(now))
          .whereType<int>()
          .toList();
      final avgDays = daysList.isEmpty
          ? 0.0
          : daysList.reduce((a, b) => a + b) / daysList.length;
      return CategoryStats(
        category: e.key,
        count: e.value.length,
        overdueCount: overdueInCat,
        avgDaysSinceContact: avgDays,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final methodMap = <ContactMethod, int>{};
    for (final c in active) {
      for (final i in c.interactions) {
        methodMap[i.method] = (methodMap[i.method] ?? 0) + 1;
      }
    }

    final baseScore = (onTrack / active.length) * 100;
    final neverPenalty = (neverContacted / active.length) * 20;
    final healthScore = (baseScore - neverPenalty).clamp(0.0, 100.0);

    return NetworkHealth(
      totalContacts: active.length,
      activeContacts: onTrack,
      overdueContacts: overdue,
      neverContacted: neverContacted,
      healthScore: healthScore,
      categoryBreakdown: categoryBreakdown,
      methodDistribution: methodMap,
      grade: _gradeFromScore(healthScore),
    );
  }

  /// Generate a full contact network report.
  ContactReport generateReport(DateTime now) {
    final health = networkHealth(now);
    final overdue = overdueContacts(now);
    final birthdays = upcomingBirthdays(now);
    final trends = interactionTrends();

    final active = activeContacts();
    Contact? mostContacted;
    Contact? leastContacted;
    int totalInteractions = 0;

    for (final c in active) {
      totalInteractions += c.interactions.length;
      if (c.interactions.isNotEmpty) {
        if (mostContacted == null ||
            c.interactions.length > mostContacted.interactions.length) {
          mostContacted = c;
        }
        if (leastContacted == null ||
            c.interactions.length < leastContacted.interactions.length) {
          leastContacted = c;
        }
      }
    }

    final summary = _buildSummary(health, overdue, birthdays, totalInteractions,
        mostContacted, leastContacted);

    return ContactReport(
      health: health,
      overdueFollowUps: overdue,
      upcomingBirthdays: birthdays,
      trends: trends,
      mostContacted: mostContacted,
      leastContacted: leastContacted,
      totalInteractions: totalInteractions,
      textSummary: summary,
    );
  }

  /// Persist contacts to JSON string.
  String toJson() {
    return jsonEncode({
      'contacts': _contacts.map((c) => c.toJson()).toList(),
      'nextId': _nextId,
      'nextInteractionId': _nextInteractionId,
    });
  }

  /// Restore contacts from JSON string.
  ///
  /// Parses into a temporary list first so that malformed JSON
  /// doesn't destroy existing contact data.
  void loadJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final list = data['contacts'] as List<dynamic>;
    if (list.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries contacts '
        '(got ${list.length}). This limit prevents memory '
        'exhaustion from corrupted or malicious data.',
      );
    }
    final parsed = <Contact>[];
    for (final item in list) {
      parsed.add(Contact.fromJson(item as Map<String, dynamic>));
    }
    final nextIdVal = data['nextId'] as int? ?? parsed.length + 1;
    final nextIntIdVal = data['nextInteractionId'] as int? ?? parsed.length + 1;
    // All parsed successfully — safe to replace.
    _contacts.clear();
    _contacts.addAll(parsed);
    _nextId = nextIdVal;
    _nextInteractionId = nextIntIdVal;
  }

  double _categoryWeight(RelationshipCategory cat) {
    switch (cat) {
      case RelationshipCategory.family:
        return 1.0;
      case RelationshipCategory.friend:
        return 0.9;
      case RelationshipCategory.mentor:
        return 0.8;
      case RelationshipCategory.mentee:
        return 0.7;
      case RelationshipCategory.colleague:
        return 0.6;
      case RelationshipCategory.client:
        return 0.5;
      case RelationshipCategory.neighbor:
        return 0.4;
      case RelationshipCategory.acquaintance:
        return 0.3;
      case RelationshipCategory.other:
        return 0.2;
    }
  }

  String _gradeFromScore(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  String _buildSummary(
    NetworkHealth health,
    List<FollowUpReminder> overdue,
    List<UpcomingBirthday> birthdays,
    int totalInteractions,
    Contact? mostContacted,
    Contact? leastContacted,
  ) {
    final buf = StringBuffer();
    buf.writeln('Contact Network Report');
    buf.writeln('${'=' * 30}');
    buf.writeln(
        'Network Health: ${health.grade} (${health.healthScore.toStringAsFixed(1)}/100)');
    buf.writeln('Total Contacts: ${health.totalContacts}');
    buf.writeln('On Track: ${health.activeContacts}');
    buf.writeln('Overdue: ${health.overdueContacts}');
    buf.writeln('Never Contacted: ${health.neverContacted}');
    buf.writeln('Total Interactions: $totalInteractions');

    if (mostContacted != null) {
      buf.writeln(
          'Most Contacted: ${mostContacted.displayName} (${mostContacted.interactions.length} interactions)');
    }
    if (leastContacted != null && leastContacted != mostContacted) {
      buf.writeln(
          'Least Contacted: ${leastContacted.displayName} (${leastContacted.interactions.length} interactions)');
    }

    if (overdue.isNotEmpty) {
      buf.writeln('\nOverdue Follow-ups:');
      for (final r in overdue.take(5)) {
        buf.writeln(
            '  - ${r.contact.displayName} (${r.daysOverdue}d overdue, urgency: ${r.urgencyScore.toStringAsFixed(0)})');
      }
      if (overdue.length > 5) {
        buf.writeln('  ... and ${overdue.length - 5} more');
      }
    }

    if (birthdays.isNotEmpty) {
      buf.writeln('\nUpcoming Birthdays:');
      for (final b in birthdays.take(5)) {
        final ageStr =
            b.turningAge != null ? ', turning ${b.turningAge}' : '';
        buf.writeln(
            '  - ${b.contact.displayName} in ${b.daysUntil} days$ageStr');
      }
    }

    if (health.categoryBreakdown.isNotEmpty) {
      buf.writeln('\nBy Category:');
      for (final cs in health.categoryBreakdown) {
        buf.writeln(
            '  ${cs.category.emoji} ${cs.category.label}: ${cs.count} contacts');
      }
    }

    return buf.toString();
  }
}
