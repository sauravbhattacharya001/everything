/// A single body measurement recording.
class BodyMeasurementEntry {
  final String id;
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? bicepCm;
  final double? thighCm;
  final double? neckCm;
  final double? bodyFatPercent;
  final String? notes;

  const BodyMeasurementEntry({
    required this.id,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.bicepCm,
    this.thighCm,
    this.neckCm,
    this.bodyFatPercent,
    this.notes,
  });

  /// Returns true if at least one measurement is recorded.
  bool get hasAnyMeasurement =>
      weightKg != null ||
      heightCm != null ||
      waistCm != null ||
      chestCm != null ||
      hipsCm != null ||
      bicepCm != null ||
      thighCm != null ||
      neckCm != null ||
      bodyFatPercent != null;

  BodyMeasurementEntry copyWith({
    DateTime? date,
    double? Function()? weightKg,
    double? Function()? heightCm,
    double? Function()? waistCm,
    double? Function()? chestCm,
    double? Function()? hipsCm,
    double? Function()? bicepCm,
    double? Function()? thighCm,
    double? Function()? neckCm,
    double? Function()? bodyFatPercent,
    String? Function()? notes,
  }) =>
      BodyMeasurementEntry(
        id: id,
        date: date ?? this.date,
        weightKg: weightKg != null ? weightKg() : this.weightKg,
        heightCm: heightCm != null ? heightCm() : this.heightCm,
        waistCm: waistCm != null ? waistCm() : this.waistCm,
        chestCm: chestCm != null ? chestCm() : this.chestCm,
        hipsCm: hipsCm != null ? hipsCm() : this.hipsCm,
        bicepCm: bicepCm != null ? bicepCm() : this.bicepCm,
        thighCm: thighCm != null ? thighCm() : this.thighCm,
        neckCm: neckCm != null ? neckCm() : this.neckCm,
        bodyFatPercent:
            bodyFatPercent != null ? bodyFatPercent() : this.bodyFatPercent,
        notes: notes != null ? notes() : this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        if (weightKg != null) 'weightKg': weightKg,
        if (heightCm != null) 'heightCm': heightCm,
        if (waistCm != null) 'waistCm': waistCm,
        if (chestCm != null) 'chestCm': chestCm,
        if (hipsCm != null) 'hipsCm': hipsCm,
        if (bicepCm != null) 'bicepCm': bicepCm,
        if (thighCm != null) 'thighCm': thighCm,
        if (neckCm != null) 'neckCm': neckCm,
        if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
        if (notes != null) 'notes': notes,
      };

  factory BodyMeasurementEntry.fromJson(Map<String, dynamic> json) =>
      BodyMeasurementEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        chestCm: (json['chestCm'] as num?)?.toDouble(),
        hipsCm: (json['hipsCm'] as num?)?.toDouble(),
        bicepCm: (json['bicepCm'] as num?)?.toDouble(),
        thighCm: (json['thighCm'] as num?)?.toDouble(),
        neckCm: (json['neckCm'] as num?)?.toDouble(),
        bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}
