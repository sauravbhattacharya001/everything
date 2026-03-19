/// A saved time zone entry for the World Clock feature.
class WorldClockEntry {
  final String id;
  final String label;
  final String timeZoneName;
  final Duration utcOffset;
  final String? emoji;

  const WorldClockEntry({
    required this.id,
    required this.label,
    required this.timeZoneName,
    required this.utcOffset,
    this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'timeZoneName': timeZoneName,
        'utcOffsetMinutes': utcOffset.inMinutes,
        'emoji': emoji,
      };

  factory WorldClockEntry.fromJson(Map<String, dynamic> json) {
    return WorldClockEntry(
      id: json['id'] as String,
      label: json['label'] as String,
      timeZoneName: json['timeZoneName'] as String,
      utcOffset: Duration(minutes: json['utcOffsetMinutes'] as int),
      emoji: json['emoji'] as String?,
    );
  }
}
