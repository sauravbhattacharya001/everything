import 'dart:convert';

/// Relationship category for classifying contacts.
enum RelationshipCategory {
  family,
  friend,
  colleague,
  mentor,
  mentee,
  client,
  neighbor,
  acquaintance,
  other;

  String get label {
    switch (this) {
      case RelationshipCategory.family:
        return 'Family';
      case RelationshipCategory.friend:
        return 'Friend';
      case RelationshipCategory.colleague:
        return 'Colleague';
      case RelationshipCategory.mentor:
        return 'Mentor';
      case RelationshipCategory.mentee:
        return 'Mentee';
      case RelationshipCategory.client:
        return 'Client';
      case RelationshipCategory.neighbor:
        return 'Neighbor';
      case RelationshipCategory.acquaintance:
        return 'Acquaintance';
      case RelationshipCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipCategory.family:
        return '👨‍👩‍👧‍👦';
      case RelationshipCategory.friend:
        return '🤝';
      case RelationshipCategory.colleague:
        return '💼';
      case RelationshipCategory.mentor:
        return '🎓';
      case RelationshipCategory.mentee:
        return '📚';
      case RelationshipCategory.client:
        return '🤵';
      case RelationshipCategory.neighbor:
        return '🏘️';
      case RelationshipCategory.acquaintance:
        return '👋';
      case RelationshipCategory.other:
        return '👤';
    }
  }
}

/// Preferred contact method.
enum ContactMethod {
  phone,
  email,
  text,
  inPerson,
  videoCall,
  socialMedia,
  other;

  String get label {
    switch (this) {
      case ContactMethod.phone:
        return 'Phone';
      case ContactMethod.email:
        return 'Email';
      case ContactMethod.text:
        return 'Text';
      case ContactMethod.inPerson:
        return 'In Person';
      case ContactMethod.videoCall:
        return 'Video Call';
      case ContactMethod.socialMedia:
        return 'Social Media';
      case ContactMethod.other:
        return 'Other';
    }
  }
}

/// Desired contact frequency for follow-up reminders.
enum ContactFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  asNeeded;

  String get label {
    switch (this) {
      case ContactFrequency.daily:
        return 'Daily';
      case ContactFrequency.weekly:
        return 'Weekly';
      case ContactFrequency.biweekly:
        return 'Every 2 Weeks';
      case ContactFrequency.monthly:
        return 'Monthly';
      case ContactFrequency.quarterly:
        return 'Quarterly';
      case ContactFrequency.yearly:
        return 'Yearly';
      case ContactFrequency.asNeeded:
        return 'As Needed';
    }
  }

  /// Returns the number of days in this frequency cycle, or null for asNeeded.
  int? get days {
    switch (this) {
      case ContactFrequency.daily:
        return 1;
      case ContactFrequency.weekly:
        return 7;
      case ContactFrequency.biweekly:
        return 14;
      case ContactFrequency.monthly:
        return 30;
      case ContactFrequency.quarterly:
        return 90;
      case ContactFrequency.yearly:
        return 365;
      case ContactFrequency.asNeeded:
        return null;
    }
  }
}

/// A single interaction log entry with a contact.
class Interaction {
  final String id;
  final DateTime date;
  final String note;
  final ContactMethod method;
  final Duration? duration;

  const Interaction({
    required this.id,
    required this.date,
    required this.note,
    required this.method,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'note': note,
        'method': method.name,
        if (duration != null) 'durationMinutes': duration!.inMinutes,
      };

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String,
        method: ContactMethod.values.byName(json['method'] as String),
        duration: json['durationMinutes'] != null
            ? Duration(minutes: json['durationMinutes'] as int)
            : null,
      );
}

/// A contact/person entry.
class Contact {
  final String id;
  final String name;
  final String? nickname;
  final RelationshipCategory category;
  final ContactMethod preferredMethod;
  final ContactFrequency desiredFrequency;
  final String? email;
  final String? phone;
  final String? company;
  final String? notes;
  final List<String> tags;
  final List<Interaction> interactions;
  final DateTime? birthday;
  final DateTime createdAt;
  final bool archived;

  const Contact({
    required this.id,
    required this.name,
    this.nickname,
    required this.category,
    this.preferredMethod = ContactMethod.text,
    this.desiredFrequency = ContactFrequency.monthly,
    this.email,
    this.phone,
    this.company,
    this.notes,
    this.tags = const [],
    this.interactions = const [],
    this.birthday,
    required this.createdAt,
    this.archived = false,
  });

  /// Display name (nickname if set, otherwise name).
  String get displayName => nickname ?? name;

  /// Most recent interaction, or null if none logged.
  Interaction? get lastInteraction =>
      interactions.isEmpty ? null : interactions.last;

  /// Number of days since last contact, or null if never contacted.
  int? daysSinceLastContact(DateTime now) {
    if (interactions.isEmpty) return null;
    return now.difference(interactions.last.date).inDays;
  }

  /// Whether the contact is overdue for follow-up based on desired frequency.
  bool isOverdue(DateTime now) {
    final cycleDays = desiredFrequency.days;
    if (cycleDays == null) return false;
    final daysSince = daysSinceLastContact(now);
    if (daysSince == null) return true;
    return daysSince >= cycleDays;
  }

  /// Days until next follow-up is due, or null for asNeeded.
  int? daysUntilDue(DateTime now) {
    final cycleDays = desiredFrequency.days;
    if (cycleDays == null) return null;
    final daysSince = daysSinceLastContact(now);
    if (daysSince == null) return 0;
    return cycleDays - daysSince;
  }

  /// Whether this contact has an upcoming birthday within the next N days.
  bool hasBirthdaySoon(DateTime now, {int withinDays = 30}) {
    if (birthday == null) return false;
    final thisYear = DateTime(now.year, birthday!.month, birthday!.day);
    final nextYear = DateTime(now.year + 1, birthday!.month, birthday!.day);
    final upcoming = thisYear.isAfter(now) || thisYear.isAtSameMomentAs(now)
        ? thisYear
        : nextYear;
    return upcoming.difference(now).inDays <= withinDays;
  }

  /// Days until next birthday, or null if no birthday set.
  int? daysUntilBirthday(DateTime now) {
    if (birthday == null) return null;
    final thisYear = DateTime(now.year, birthday!.month, birthday!.day);
    if (thisYear.isAfter(now) || thisYear.isAtSameMomentAs(now)) {
      return thisYear.difference(now).inDays;
    }
    final nextYear = DateTime(now.year + 1, birthday!.month, birthday!.day);
    return nextYear.difference(now).inDays;
  }

  Contact copyWith({
    String? id,
    String? name,
    String? nickname,
    RelationshipCategory? category,
    ContactMethod? preferredMethod,
    ContactFrequency? desiredFrequency,
    String? email,
    String? phone,
    String? company,
    String? notes,
    List<String>? tags,
    List<Interaction>? interactions,
    DateTime? birthday,
    DateTime? createdAt,
    bool? archived,
  }) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        nickname: nickname ?? this.nickname,
        category: category ?? this.category,
        preferredMethod: preferredMethod ?? this.preferredMethod,
        desiredFrequency: desiredFrequency ?? this.desiredFrequency,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        company: company ?? this.company,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        interactions: interactions ?? this.interactions,
        birthday: birthday ?? this.birthday,
        createdAt: createdAt ?? this.createdAt,
        archived: archived ?? this.archived,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nickname != null) 'nickname': nickname,
        'category': category.name,
        'preferredMethod': preferredMethod.name,
        'desiredFrequency': desiredFrequency.name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (company != null) 'company': company,
        if (notes != null) 'notes': notes,
        'tags': tags,
        'interactions': interactions.map((i) => i.toJson()).toList(),
        if (birthday != null) 'birthday': birthday!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        category:
            RelationshipCategory.values.byName(json['category'] as String),
        preferredMethod:
            ContactMethod.values.byName(json['preferredMethod'] as String),
        desiredFrequency:
            ContactFrequency.values.byName(json['desiredFrequency'] as String),
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        company: json['company'] as String?,
        notes: json['notes'] as String?,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        interactions: (json['interactions'] as List<dynamic>?)
                ?.map((e) => Interaction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        birthday: json['birthday'] != null
            ? DateTime.parse(json['birthday'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        archived: json['archived'] as bool? ?? false,
      );

  @override
  String toString() =>
      'Contact(id: $id, name: $name, category: ${category.label})';
}
