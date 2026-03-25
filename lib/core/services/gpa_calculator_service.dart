/// Service for GPA (Grade Point Average) calculations.
///
/// Supports both US 4.0 scale and weighted GPA with custom credit hours.
class GpaCalculatorService {
  GpaCalculatorService._();

  /// Standard US letter grades mapped to grade points.
  static const Map<String, double> gradePoints = {
    'A+': 4.0,
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D+': 1.3,
    'D': 1.0,
    'D-': 0.7,
    'F': 0.0,
  };

  /// All available letter grades in order.
  static List<String> get letterGrades => gradePoints.keys.toList();

  /// Calculate GPA from a list of courses.
  static GpaResult calculate(List<CourseEntry> courses) {
    if (courses.isEmpty) {
      return const GpaResult(gpa: 0, totalCredits: 0, totalPoints: 0, courses: []);
    }

    double totalPoints = 0;
    double totalCredits = 0;

    for (final course in courses) {
      final points = gradePoints[course.grade] ?? 0.0;
      totalPoints += points * course.credits;
      totalCredits += course.credits;
    }

    final gpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;

    return GpaResult(
      gpa: gpa,
      totalCredits: totalCredits,
      totalPoints: totalPoints,
      courses: courses,
    );
  }

  /// Calculate cumulative GPA combining current and prior.
  static double cumulativeGpa({
    required double priorGpa,
    required double priorCredits,
    required double currentGpa,
    required double currentCredits,
  }) {
    final totalCredits = priorCredits + currentCredits;
    if (totalCredits == 0) return 0;
    return (priorGpa * priorCredits + currentGpa * currentCredits) / totalCredits;
  }

  /// Get a text classification for a GPA.
  static String classify(double gpa) {
    if (gpa >= 3.9) return 'Summa Cum Laude';
    if (gpa >= 3.7) return 'Magna Cum Laude';
    if (gpa >= 3.5) return 'Cum Laude';
    if (gpa >= 3.0) return 'Good Standing';
    if (gpa >= 2.0) return 'Satisfactory';
    if (gpa >= 1.0) return 'Probation';
    return 'Academic Warning';
  }

  /// Get color suggestion based on GPA.
  static String colorForGpa(double gpa) {
    if (gpa >= 3.5) return 'green';
    if (gpa >= 3.0) return 'blue';
    if (gpa >= 2.0) return 'orange';
    return 'red';
  }
}

/// A single course entry for GPA calculation.
class CourseEntry {
  final String name;
  final String grade;
  final double credits;

  const CourseEntry({
    required this.name,
    required this.grade,
    required this.credits,
  });

  CourseEntry copyWith({String? name, String? grade, double? credits}) {
    return CourseEntry(
      name: name ?? this.name,
      grade: grade ?? this.grade,
      credits: credits ?? this.credits,
    );
  }
}

/// Result of a GPA calculation.
class GpaResult {
  final double gpa;
  final double totalCredits;
  final double totalPoints;
  final List<CourseEntry> courses;

  const GpaResult({
    required this.gpa,
    required this.totalCredits,
    required this.totalPoints,
    required this.courses,
  });
}
