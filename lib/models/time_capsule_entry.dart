import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// A time capsule: a message to your future self that unlocks on a date.
class TimeCapsuleEntry {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool isOpened;
  final DateTime? openedAt;
  final String? mood; // emoji mood when writing

  const TimeCapsuleEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.unlockAt,
    this.isOpened = false,
    this.openedAt,
    this.mood,
  });

  bool get isUnlocked => DateTime.now().isAfter(unlockAt);
  bool get canOpen => isUnlocked && !isOpened;

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(unlockAt)) return Duration.zero;
    return unlockAt.difference(now);
  }

  String get timeRemainingLabel {
    final rem = timeRemaining;
    if (rem == Duration.zero) return 'Ready to open!';
    if (rem.inDays > 365) {
      final years = (rem.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} remaining';
    }
    if (rem.inDays > 30) {
      final months = (rem.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} remaining';
    }
    if (rem.inDays > 0) return '${rem.inDays} day${rem.inDays == 1 ? '' : 's'} remaining';
    if (rem.inHours > 0) return '${rem.inHours} hour${rem.inHours == 1 ? '' : 's'} remaining';
    return '${rem.inMinutes} minute${rem.inMinutes == 1 ? '' : 's'} remaining';
  }

  TimeCapsuleEntry copyWith({
    String? title,
    String? message,
    DateTime? unlockAt,
    bool? isOpened,
    DateTime? openedAt,
    String? mood,
  }) {
    return TimeCapsuleEntry(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'unlockAt': unlockAt.toIso8601String(),
        'isOpened': isOpened,
        'openedAt': openedAt?.toIso8601String(),
        'mood': mood,
      };

  factory TimeCapsuleEntry.fromJson(Map<String, dynamic> json) {
    return TimeCapsuleEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: AppDateUtils.safeParse(json['createdAt'] as String?),
      unlockAt: AppDateUtils.safeParse(json['unlockAt'] as String?),
      isOpened: json['isOpened'] as bool? ?? false,
      openedAt: AppDateUtils.safeParseNullable(json['openedAt'] as String?),
      mood: json['mood'] as String?,
    );
  }

  static String encodeList(List<TimeCapsuleEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<TimeCapsuleEntry> decodeList(String data) {
    final list = jsonDecode(data) as List;
    return list
        .map((e) => TimeCapsuleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
