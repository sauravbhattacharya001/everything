import 'dart:convert';

/// Common intermittent fasting protocols.
enum FastingProtocol {
  f16_8,
  f18_6,
  f20_4,
  f5_2,
  omad,
  custom;

  String get label {
    switch (this) {
      case FastingProtocol.f16_8:
        return '16:8';
      case FastingProtocol.f18_6:
        return '18:6';
      case FastingProtocol.f20_4:
        return '20:4';
      case FastingProtocol.f5_2:
        return '5:2';
      case FastingProtocol.omad:
        return 'OMAD';
      case FastingProtocol.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case FastingProtocol.f16_8:
        return '16h fast, 8h eating window';
      case FastingProtocol.f18_6:
        return '18h fast, 6h eating window';
      case FastingProtocol.f20_4:
        return '20h fast, 4h eating window';
      case FastingProtocol.f5_2:
        return '5 normal days, 2 restricted days';
      case FastingProtocol.omad:
        return 'One Meal A Day (~23h fast)';
      case FastingProtocol.custom:
        return 'Custom duration';
    }
  }

  /// Target fasting hours for this protocol.
  int get targetHours {
    switch (this) {
      case FastingProtocol.f16_8:
        return 16;
      case FastingProtocol.f18_6:
        return 18;
      case FastingProtocol.f20_4:
        return 20;
      case FastingProtocol.f5_2:
        return 24;
      case FastingProtocol.omad:
        return 23;
      case FastingProtocol.custom:
        return 16;
    }
  }

  String get emoji {
    switch (this) {
      case FastingProtocol.f16_8:
        return '⏰';
      case FastingProtocol.f18_6:
        return '🕐';
      case FastingProtocol.f20_4:
        return '🔥';
      case FastingProtocol.f5_2:
        return '📅';
      case FastingProtocol.omad:
        return '🍽️';
      case FastingProtocol.custom:
        return '⚙️';
    }
  }
}

/// Status of a fasting session.
enum FastingStatus {
  active,
  completed,
  broken;

  String get label {
    switch (this) {
      case FastingStatus.active:
        return 'Active';
      case FastingStatus.completed:
        return 'Completed';
      case FastingStatus.broken:
        return 'Broken';
    }
  }

  String get emoji {
    switch (this) {
      case FastingStatus.active:
        return '⏳';
      case FastingStatus.completed:
        return '✅';
      case FastingStatus.broken:
        return '❌';
    }
  }
}

/// A single fasting session entry.
class FastingEntry {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final FastingProtocol protocol;
  final int targetHours;
  final FastingStatus status;
  final String? note;
  final int? moodBefore; // 1-5
  final int? moodAfter; // 1-5

  const FastingEntry({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.protocol,
    required this.targetHours,
    this.status = FastingStatus.active,
    this.note,
    this.moodBefore,
    this.moodAfter,
  });

  /// Duration of the fast in hours (or elapsed if still active).
  double get durationHours {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes / 60.0;
  }

  /// Progress towards the target (0.0 - 1.0+).
  double get progress =>
      targetHours > 0 ? (durationHours / targetHours).clamp(0.0, 2.0) : 0.0;

  /// Whether the target was reached.
  bool get targetReached => durationHours >= targetHours;

  /// Formatted duration string.
  String get durationFormatted {
    final dur = endTime != null
        ? endTime!.difference(startTime)
        : DateTime.now().difference(startTime);
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  FastingEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    FastingProtocol? protocol,
    int? targetHours,
    FastingStatus? status,
    String? note,
    int? moodBefore,
    int? moodAfter,
  }) {
    return FastingEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      protocol: protocol ?? this.protocol,
      targetHours: targetHours ?? this.targetHours,
      status: status ?? this.status,
      note: note ?? this.note,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'protocol': protocol.name,
      'targetHours': targetHours,
      'status': status.name,
      'note': note,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
    };
  }

  factory FastingEntry.fromJson(Map<String, dynamic> json) {
    return FastingEntry(
      id: json['id'] as String,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      protocol: FastingProtocol.values.firstWhere(
        (v) => v.name == json['protocol'],
        orElse: () => FastingProtocol.f16_8,
      ),
      targetHours: json['targetHours'] as int? ?? 16,
      status: FastingStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => FastingStatus.active,
      ),
      note: json['note'] as String?,
      moodBefore: json['moodBefore'] as int?,
      moodAfter: json['moodAfter'] as int?,
    );
  }

  static String encodeList(List<FastingEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<FastingEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => FastingEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
