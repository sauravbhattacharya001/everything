/// Service for managing countdown timers to specific events or deadlines.
class CountdownTimerService {
  CountdownTimerService._();

  /// Preset countdown categories for quick creation.
  static const List<String> presets = [
    'Birthday',
    'Vacation',
    'Deadline',
    'Holiday',
    'Wedding',
    'Exam',
    'Launch Day',
    'New Year',
  ];

  /// Calculate the remaining duration until the target date.
  static Duration remaining(DateTime target) {
    final now = DateTime.now();
    return target.isAfter(now) ? target.difference(now) : Duration.zero;
  }

  /// Format a duration into a human-readable breakdown.
  static String formatRemaining(Duration d) {
    if (d == Duration.zero) return 'Arrived!';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (parts.isEmpty || days == 0) parts.add('${seconds}s');
    return parts.join(' ');
  }
}

/// A single countdown entry with a name and target date/time.
class CountdownEntry {
  final String id;
  final String name;
  final DateTime targetDate;
  final String? category;
  final DateTime createdAt;

  CountdownEntry({
    String? id,
    required this.name,
    required this.targetDate,
    this.category,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Duration get remaining => CountdownTimerService.remaining(targetDate);
  bool get isExpired => remaining == Duration.zero;
  String get formattedRemaining =>
      CountdownTimerService.formatRemaining(remaining);

  /// Progress from creation to target (0.0 = just created, 1.0 = arrived).
  double get progress {
    final total = targetDate.difference(createdAt).inSeconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetDate': targetDate.toIso8601String(),
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CountdownEntry.fromJson(Map<String, dynamic> json) => CountdownEntry(
        id: json['id'] as String?,
        name: json['name'] as String,
        targetDate: DateTime.parse(json['targetDate'] as String),
        category: json['category'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
