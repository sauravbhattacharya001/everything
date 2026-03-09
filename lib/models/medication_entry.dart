import 'dart:convert';

/// Medication frequency schedule.
enum MedFrequency {
  onceDaily, twiceDaily, thriceDaily, fourTimesDaily, everyOtherDay, weekly, asNeeded;

  String get label {
    switch (this) {
      case MedFrequency.onceDaily: return 'Once daily';
      case MedFrequency.twiceDaily: return 'Twice daily';
      case MedFrequency.thriceDaily: return '3x daily';
      case MedFrequency.fourTimesDaily: return '4x daily';
      case MedFrequency.everyOtherDay: return 'Every other day';
      case MedFrequency.weekly: return 'Weekly';
      case MedFrequency.asNeeded: return 'As needed';
    }
  }

  int get dailyDoses {
    switch (this) {
      case MedFrequency.onceDaily: return 1;
      case MedFrequency.twiceDaily: return 2;
      case MedFrequency.thriceDaily: return 3;
      case MedFrequency.fourTimesDaily: return 4;
      case MedFrequency.everyOtherDay: return 1;
      case MedFrequency.weekly: return 1;
      case MedFrequency.asNeeded: return 0;
    }
  }
}

/// Form in which medication is taken.
enum MedForm {
  tablet, capsule, liquid, injection, topical, inhaler, drops, patch, other;

  String get label {
    switch (this) {
      case MedForm.tablet: return 'Tablet';
      case MedForm.capsule: return 'Capsule';
      case MedForm.liquid: return 'Liquid';
      case MedForm.injection: return 'Injection';
      case MedForm.topical: return 'Topical';
      case MedForm.inhaler: return 'Inhaler';
      case MedForm.drops: return 'Drops';
      case MedForm.patch: return 'Patch';
      case MedForm.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case MedForm.tablet: return '💊';
      case MedForm.capsule: return '💊';
      case MedForm.liquid: return '🧴';
      case MedForm.injection: return '💉';
      case MedForm.topical: return '🧴';
      case MedForm.inhaler: return '🫁';
      case MedForm.drops: return '💧';
      case MedForm.patch: return '🩹';
      case MedForm.other: return '💊';
    }
  }
}

/// Time of day for scheduled doses.
enum DoseTime {
  morning, afternoon, evening, bedtime;

  String get label {
    switch (this) {
      case DoseTime.morning: return 'Morning';
      case DoseTime.afternoon: return 'Afternoon';
      case DoseTime.evening: return 'Evening';
      case DoseTime.bedtime: return 'Bedtime';
    }
  }

  String get emoji {
    switch (this) {
      case DoseTime.morning: return '🌅';
      case DoseTime.afternoon: return '☀️';
      case DoseTime.evening: return '🌆';
      case DoseTime.bedtime: return '🌙';
    }
  }

  int get defaultHour {
    switch (this) {
      case DoseTime.morning: return 8;
      case DoseTime.afternoon: return 13;
      case DoseTime.evening: return 18;
      case DoseTime.bedtime: return 22;
    }
  }
}

/// A medication profile.
class Medication {
  final String id;
  final String name;
  final String dosage;
  final MedForm form;
  final MedFrequency frequency;
  final List<DoseTime> scheduledTimes;
  final String? notes;
  final String? prescribedBy;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  final String color;

  const Medication({
    required this.id, required this.name, required this.dosage,
    required this.form, required this.frequency, required this.scheduledTimes,
    this.notes, this.prescribedBy, required this.startDate,
    this.endDate, this.active = true, this.color = '#2196F3',
  });

  Medication copyWith({
    String? name, String? dosage, MedForm? form, MedFrequency? frequency,
    List<DoseTime>? scheduledTimes, String? notes, String? prescribedBy,
    DateTime? startDate, DateTime? endDate, bool? active, String? color,
  }) => Medication(
    id: id, name: name ?? this.name, dosage: dosage ?? this.dosage,
    form: form ?? this.form, frequency: frequency ?? this.frequency,
    scheduledTimes: scheduledTimes ?? this.scheduledTimes,
    notes: notes ?? this.notes, prescribedBy: prescribedBy ?? this.prescribedBy,
    startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
    active: active ?? this.active, color: color ?? this.color,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'dosage': dosage, 'form': form.name,
    'frequency': frequency.name,
    'scheduledTimes': scheduledTimes.map((t) => t.name).toList(),
    'notes': notes, 'prescribedBy': prescribedBy,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'active': active, 'color': color,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String, name: json['name'] as String,
    dosage: json['dosage'] as String,
    form: MedForm.values.byName(json['form'] as String),
    frequency: MedFrequency.values.byName(json['frequency'] as String),
    scheduledTimes: (json['scheduledTimes'] as List)
        .map((t) => DoseTime.values.byName(t as String)).toList(),
    notes: json['notes'] as String?,
    prescribedBy: json['prescribedBy'] as String?,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    active: json['active'] as bool? ?? true,
    color: json['color'] as String? ?? '#2196F3',
  );
}

/// A dose log entry.
class DoseLog {
  final String id;
  final String medicationId;
  final DateTime timestamp;
  final DoseTime scheduledTime;
  final bool taken;
  final bool skipped;
  final String? skipReason;
  final String? sideEffects;

  const DoseLog({
    required this.id, required this.medicationId, required this.timestamp,
    required this.scheduledTime, this.taken = true, this.skipped = false,
    this.skipReason, this.sideEffects,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'medicationId': medicationId,
    'timestamp': timestamp.toIso8601String(),
    'scheduledTime': scheduledTime.name,
    'taken': taken, 'skipped': skipped,
    'skipReason': skipReason, 'sideEffects': sideEffects,
  };

  factory DoseLog.fromJson(Map<String, dynamic> json) => DoseLog(
    id: json['id'] as String,
    medicationId: json['medicationId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    scheduledTime: DoseTime.values.byName(json['scheduledTime'] as String),
    taken: json['taken'] as bool? ?? true,
    skipped: json['skipped'] as bool? ?? false,
    skipReason: json['skipReason'] as String?,
    sideEffects: json['sideEffects'] as String?,
  );
}
