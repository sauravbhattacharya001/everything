/// Service for BMI calculation, categorization, and history tracking.
class BmiCalculatorService {
  BmiCalculatorService._();

  /// Calculate BMI from weight (kg) and height (cm).
  static double calculate(double weightKg, double heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Calculate BMI from imperial units (lbs, feet, inches).
  static double calculateImperial(double weightLbs, int feet, double inches) {
    final totalInches = feet * 12 + inches;
    if (totalInches <= 0 || weightLbs <= 0) return 0;
    return (weightLbs * 703) / (totalInches * totalInches);
  }

  /// Get the BMI category.
  static BmiCategory categorize(double bmi) {
    if (bmi < 16) return BmiCategory.severeThinness;
    if (bmi < 17) return BmiCategory.moderateThinness;
    if (bmi < 18.5) return BmiCategory.mildThinness;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    if (bmi < 35) return BmiCategory.obeseClassI;
    if (bmi < 40) return BmiCategory.obeseClassII;
    return BmiCategory.obeseClassIII;
  }

  /// Get healthy weight range for a given height (cm).
  static (double min, double max) healthyWeightRange(double heightCm) {
    final heightM = heightCm / 100;
    return (18.5 * heightM * heightM, 24.9 * heightM * heightM);
  }

  /// Convert kg to lbs.
  static double kgToLbs(double kg) => kg * 2.20462;

  /// Convert lbs to kg.
  static double lbsToKg(double lbs) => lbs / 2.20462;

  /// Convert cm to feet and inches.
  static (int feet, double inches) cmToFeetInches(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet, double.parse(inches.toStringAsFixed(1)));
  }

  /// Convert feet and inches to cm.
  static double feetInchesToCm(int feet, double inches) {
    return (feet * 12 + inches) * 2.54;
  }
}

/// BMI category with label, color hint, and range info.
enum BmiCategory {
  severeThinness('Severe Thinness', '< 16', 0xFF9C27B0),
  moderateThinness('Moderate Thinness', '16 – 17', 0xFF2196F3),
  mildThinness('Mild Thinness', '17 – 18.5', 0xFF03A9F4),
  normal('Normal', '18.5 – 25', 0xFF4CAF50),
  overweight('Overweight', '25 – 30', 0xFFFF9800),
  obeseClassI('Obese Class I', '30 – 35', 0xFFFF5722),
  obeseClassII('Obese Class II', '35 – 40', 0xFFF44336),
  obeseClassIII('Obese Class III', '≥ 40', 0xFFB71C1C);

  final String label;
  final String range;
  final int colorValue;
  const BmiCategory(this.label, this.range, this.colorValue);
}

/// A single BMI record for history tracking.
class BmiRecord {
  final DateTime date;
  final double weightKg;
  final double heightCm;
  final double bmi;
  final BmiCategory category;

  BmiRecord({
    required this.date,
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bmi': bmi,
        'category': category.label,
      };
}
