import 'dart:convert';

/// Category for quick-capture items.
enum CaptureCategory {
  idea,
  task,
  note,
  reminder,
  question,
  link,
  quote,
  other;

  String get label {
    switch (this) {
      case CaptureCategory.idea:
        return 'Idea';
      case CaptureCategory.task:
        return 'Task';
      case CaptureCategory.note:
        return 'Note';
      case CaptureCategory.reminder:
        return 'Reminder';
      case CaptureCategory.question:
        return 'Question';
      case CaptureCategory.link:
        return 'Link';
      case CaptureCategory.quote:
        return 'Quote';
      case CaptureCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case CaptureCategory.idea:
        return '\u{1F4A1}';
      case CaptureCategory.task:
        return '\u2705';
      case CaptureCategory.note:
        return '\u{1F4DD}';
      case CaptureCategory.reminder:
        return '\u23F0';
      case CaptureCategory.question:
        return '\u2753';
      case CaptureCategory.link:
        return '\u{1F517}';
      case CaptureCategory.quote:
        return '\u{1F4AC}';
      case CaptureCategory.other:
        return '\u{1F4CC}';
    }
  }
}

/// Priority of a capture item.
enum CapturePriority {
  none,
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case CapturePriority.none:
        return 'None';
      case CapturePriority.low:
        return 'Low';
      case CapturePriority.medium:
        return 'Medium';
      case CapturePriority.high:
        return 'High';
      case CapturePriority.urgent:
        return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case CapturePriority.none:
        return '\u26AA';
      case CapturePriority.low:
        return '\u{1F7E2}';
      case CapturePriority.medium:
        return '\u{1F7E1}';
      case CapturePriority.high:
        return '\u{1F7E0}';
      case CapturePriority.urgent:
        return '\u{1F534}';
    }
  }

  int get sortOrder {
    switch (this) {
      case CapturePriority.urgent:
        return 0;
      case CapturePriority.high:
        return 1;
      case CapturePriority.medium:
        return 2;
      case CapturePriority.low:
        return 3;
      case CapturePriority.none:
        return 4;
    }
  }
}

/// Processing status of a capture item.
enum CaptureStatus {
  inbox,
  processed,
  archived,
  deleted;

  String get label {
    switch (this) {
      case CaptureStatus.inbox:
        return 'Inbox';
      case CaptureStatus.processed:
        return 'Processed';
      case CaptureStatus.archived:
        return 'Archived';
      case CaptureStatus.deleted:
        return 'Deleted';
    }
  }
}

/// Where a capture item was processed/moved to.
enum ProcessedDestination {
  habit,
  goal,
  event,
  expense,
  reading,
  wishlist,
  bucketList,
  decision,
  contact,
  manual,
  discarded;

  String get label {
    switch (this) {
      case ProcessedDestination.habit:
        return 'Habit Tracker';
      case ProcessedDestination.goal:
        return 'Goals';
      case ProcessedDestination.event:
        return 'Calendar Event';
      case ProcessedDestination.expense:
        return 'Expense Tracker';
      case ProcessedDestination.reading:
        return 'Reading List';
      case ProcessedDestination.wishlist:
        return 'Wishlist';
      case ProcessedDestination.bucketList:
        return 'Bucket List';
      case ProcessedDestination.decision:
        return 'Decision Journal';
      case ProcessedDestination.contact:
        return 'Contact Tracker';
      case ProcessedDestination.manual:
        return 'Manual';
      case ProcessedDestination.discarded:
        return 'Discarded';
    }
  }
}

/// A single quick-capture inbox item.
///
/// Captures are designed for minimal friction: text + optional category.
/// They live in the inbox until the user processes them into the right
/// tracker or archives/discards them.
class CaptureItem {
  final String id;
  final DateTime capturedAt;
  final String text;
  final CaptureCategory category;
  final CapturePriority priority;
  final CaptureStatus status;
  final List<String> tags;
  final String? note;
  final DateTime? processedAt;
  final ProcessedDestination? destination;
  final bool isPinned;

  CaptureItem({
    required this.id,
    required this.capturedAt,
    required this.text,
    this.category = CaptureCategory.note,
    this.priority = CapturePriority.none,
    this.status = CaptureStatus.inbox,
    this.tags = const [],
    this.note,
    this.processedAt,
    this.destination,
    this.isPinned = false,
  });

  /// How long this item has been in the inbox.
  Duration get age => DateTime.now().difference(capturedAt);

  /// Whether this item is stale (more than 3 days old and still in inbox).
  bool get isStale =>
      status == CaptureStatus.inbox &&
      age > const Duration(days: 3);

  /// Whether this item is aging (more than 1 day old and still in inbox).
  bool get isAging =>
      status == CaptureStatus.inbox &&
      age > const Duration(days: 1) &&
      !isStale;

  /// Human-readable age description.
  String get ageLabel {
    final days = age.inDays;
    if (days == 0) {
      final hours = age.inHours;
      if (hours == 0) {
        final minutes = age.inMinutes;
        return minutes <= 1 ? 'just now' : '$minutes min ago';
      }
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) {
      final weeks = days ~/ 7;
      return '$weeks weeks ago';
    }
    final months = days ~/ 30;
    return '$months months ago';
  }

  CaptureItem copyWith({
    String? id,
    DateTime? capturedAt,
    String? text,
    CaptureCategory? category,
    CapturePriority? priority,
    CaptureStatus? status,
    List<String>? tags,
    String? note,
    DateTime? processedAt,
    ProcessedDestination? destination,
    bool? isPinned,
  }) {
    return CaptureItem(
      id: id ?? this.id,
      capturedAt: capturedAt ?? this.capturedAt,
      text: text ?? this.text,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? List.from(this.tags),
      note: note ?? this.note,
      processedAt: processedAt ?? this.processedAt,
      destination: destination ?? this.destination,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capturedAt': capturedAt.toIso8601String(),
      'text': text,
      'category': category.index,
      'priority': priority.index,
      'status': status.index,
      'tags': tags,
      'note': note,
      'processedAt': processedAt?.toIso8601String(),
      'destination': destination?.index,
      'isPinned': isPinned,
    };
  }

  factory CaptureItem.fromJson(Map<String, dynamic> json) {
    return CaptureItem(
      id: json['id'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      text: json['text'] as String,
      category: CaptureCategory.values[json['category'] as int? ?? 2],
      priority: CapturePriority.values[json['priority'] as int? ?? 0],
      status: CaptureStatus.values[json['status'] as int? ?? 0],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      note: json['note'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      destination: json['destination'] != null
          ? ProcessedDestination.values[json['destination'] as int]
          : null,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CaptureItem.fromJsonString(String s) =>
      CaptureItem.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  String toString() =>
      '${category.emoji} ${priority.emoji} $text (${status.label}) - $ageLabel';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CaptureItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
