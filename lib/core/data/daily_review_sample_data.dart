import '../models/event_model.dart';
import '../services/daily_review_service.dart';

/// Shared sample data for daily review screens and tests.
///
/// Centralised here to avoid 130+ lines of hardcoded data in the
/// screen widget.  Call [sampleEvents] and [sampleReviews] to get
/// consistent sample data across screens.
class DailyReviewSampleData {
  DailyReviewSampleData._();

  /// Nine sample events spread across yesterday, today, and tomorrow.
  static List<EventModel> sampleEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    return [
      EventModel(
        id: 'dr1',
        title: 'Morning Standup',
        description: 'Daily team sync',
        date: today.add(const Duration(hours: 9)),
        endDate: today.add(const Duration(hours: 9, minutes: 15)),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
        checklist: EventChecklist(items: [
          EventChecklistItem(text: 'Update status', isChecked: true),
          EventChecklistItem(text: 'Share blockers', isChecked: true),
        ]),
      ),
      EventModel(
        id: 'dr2',
        title: 'Design Review',
        description: 'Review new feature designs',
        date: today.add(const Duration(hours: 10)),
        endDate: today.add(const Duration(hours: 11)),
        priority: EventPriority.high,
        tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
      ),
      EventModel(
        id: 'dr3',
        title: 'Lunch Break',
        description: '',
        date: today.add(const Duration(hours: 12)),
        endDate: today.add(const Duration(hours: 13)),
        priority: EventPriority.low,
        tags: [const EventTag(name: 'personal', color: 0xFF4CAF50)],
      ),
      EventModel(
        id: 'dr4',
        title: 'Sprint Planning',
        description: 'Plan next sprint tasks',
        date: today.add(const Duration(hours: 14)),
        endDate: today.add(const Duration(hours: 15, minutes: 30)),
        priority: EventPriority.high,
        tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
        checklist: EventChecklist(items: [
          EventChecklistItem(text: 'Review backlog', isChecked: true),
          EventChecklistItem(text: 'Estimate stories', isChecked: false),
          EventChecklistItem(text: 'Assign tasks', isChecked: false),
        ]),
      ),
      EventModel(
        id: 'dr5',
        title: 'Gym Session',
        description: 'Upper body workout',
        date: today.add(const Duration(hours: 18)),
        endDate: today.add(const Duration(hours: 19)),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'health', color: 0xFFE91E63)],
      ),
      // Yesterday events
      EventModel(
        id: 'dr6',
        title: 'Code Review',
        description: '',
        date: yesterday.add(const Duration(hours: 10)),
        endDate: yesterday.add(const Duration(hours: 11)),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
      ),
      EventModel(
        id: 'dr7',
        title: 'Team Retro',
        description: '',
        date: yesterday.add(const Duration(hours: 15)),
        endDate: yesterday.add(const Duration(hours: 16)),
        priority: EventPriority.high,
        tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
      ),
      // Tomorrow events
      EventModel(
        id: 'dr8',
        title: 'Morning Run',
        description: '5km jog',
        date: tomorrow.add(const Duration(hours: 7)),
        endDate: tomorrow.add(const Duration(hours: 7, minutes: 45)),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'health', color: 0xFFE91E63)],
      ),
      EventModel(
        id: 'dr9',
        title: 'Product Demo',
        description: 'Show new features to stakeholders',
        date: tomorrow.add(const Duration(hours: 14)),
        endDate: tomorrow.add(const Duration(hours: 15)),
        priority: EventPriority.urgent,
        tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
      ),
    ];
  }

  /// Sample daily reviews for the last 3 days.
  static List<DailyReview> sampleReviews() {
    final now = DateTime.now();
    return [
      DailyReview(
        date: now.subtract(const Duration(days: 1)),
        rating: 4,
        mood: 4,
        energy: 3,
        notes: 'Productive day, got through sprint planning well.',
        highlights: ['Finished code review early', 'Good retro feedback'],
        lowlights: ['Skipped gym'],
        tomorrowFocus: 'Complete design review',
      ),
      DailyReview(
        date: now.subtract(const Duration(days: 2)),
        rating: 3,
        mood: 3,
        energy: 4,
        notes: 'Average day. Too many meetings.',
        highlights: ['Resolved a tricky bug'],
        lowlights: ['3 back-to-back meetings', 'No deep work time'],
        tomorrowFocus: 'Block focus time in calendar',
      ),
      DailyReview(
        date: now.subtract(const Duration(days: 3)),
        rating: 5,
        mood: 5,
        energy: 5,
        notes: 'Best day this week! Shipped the feature.',
        highlights: ['Feature shipped!', 'Got great feedback'],
        lowlights: [],
        tomorrowFocus: 'Start on next feature',
      ),
    ];
  }
}
