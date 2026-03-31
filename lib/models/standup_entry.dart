/// A single daily standup entry capturing quick morning planning.
class StandupEntry {
  final String id;
  final DateTime date;

  /// What the user accomplished yesterday.
  String yesterday;

  /// What the user plans to do today.
  String today;

  /// Any blockers or impediments.
  String blockers;

  /// Optional mood/energy indicator (1-5).
  int energy;

  /// Whether the user marked today's goals as completed (end-of-day).
  bool goalsCompleted;

  StandupEntry({
    required this.id,
    required this.date,
    this.yesterday = '',
    this.today = '',
    this.blockers = '',
    this.energy = 3,
    this.goalsCompleted = false,
  });

  bool get hasBlockers => blockers.trim().isNotEmpty;

  /// Whether this entry has meaningful content.
  bool get isComplete =>
      yesterday.trim().isNotEmpty || today.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'yesterday': yesterday,
        'today': today,
        'blockers': blockers,
        'energy': energy,
        'goalsCompleted': goalsCompleted,
      };

  factory StandupEntry.fromJson(Map<String, dynamic> json) => StandupEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        yesterday: json['yesterday'] as String? ?? '',
        today: json['today'] as String? ?? '',
        blockers: json['blockers'] as String? ?? '',
        energy: json['energy'] as int? ?? 3,
        goalsCompleted: json['goalsCompleted'] as bool? ?? false,
      );
}
