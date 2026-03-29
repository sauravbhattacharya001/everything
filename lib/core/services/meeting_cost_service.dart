/// Service for calculating the real cost of meetings based on
/// attendee count, average hourly rate, and duration.
class MeetingCostService {
  MeetingCostService._();

  /// Calculate total meeting cost.
  static double totalCost({
    required int attendees,
    required double hourlyRate,
    required int durationMinutes,
  }) {
    if (attendees <= 0 || hourlyRate <= 0 || durationMinutes <= 0) return 0;
    return attendees * hourlyRate * (durationMinutes / 60.0);
  }

  /// Calculate cost per minute for the meeting.
  static double costPerMinute({
    required int attendees,
    required double hourlyRate,
  }) {
    if (attendees <= 0 || hourlyRate <= 0) return 0;
    return attendees * hourlyRate / 60.0;
  }

  /// Calculate cost per attendee.
  static double costPerAttendee({
    required double hourlyRate,
    required int durationMinutes,
  }) {
    if (hourlyRate <= 0 || durationMinutes <= 0) return 0;
    return hourlyRate * (durationMinutes / 60.0);
  }

  /// Calculate annual cost if this meeting recurs weekly.
  static double annualCostWeekly({
    required int attendees,
    required double hourlyRate,
    required int durationMinutes,
  }) {
    return totalCost(
          attendees: attendees,
          hourlyRate: hourlyRate,
          durationMinutes: durationMinutes,
        ) *
        52;
  }

  /// Calculate annual cost if this meeting recurs daily (weekdays).
  static double annualCostDaily({
    required int attendees,
    required double hourlyRate,
    required int durationMinutes,
  }) {
    return totalCost(
          attendees: attendees,
          hourlyRate: hourlyRate,
          durationMinutes: durationMinutes,
        ) *
        260; // ~260 weekdays per year
  }

  /// Format currency value.
  static String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Common meeting presets.
  static const List<MeetingPreset> presets = [
    MeetingPreset(name: 'Quick Sync', attendees: 3, durationMinutes: 15),
    MeetingPreset(name: 'Standup', attendees: 8, durationMinutes: 15),
    MeetingPreset(name: 'Sprint Planning', attendees: 6, durationMinutes: 60),
    MeetingPreset(name: 'All-Hands', attendees: 50, durationMinutes: 60),
    MeetingPreset(name: '1:1', attendees: 2, durationMinutes: 30),
    MeetingPreset(name: 'Retro', attendees: 6, durationMinutes: 45),
    MeetingPreset(name: 'Design Review', attendees: 5, durationMinutes: 60),
    MeetingPreset(name: 'Board Meeting', attendees: 10, durationMinutes: 120),
  ];
}

/// A preset meeting configuration.
class MeetingPreset {
  final String name;
  final int attendees;
  final int durationMinutes;

  const MeetingPreset({
    required this.name,
    required this.attendees,
    required this.durationMinutes,
  });
}
