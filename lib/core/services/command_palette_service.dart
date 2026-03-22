import 'package:flutter/material.dart';

/// A quick-action that can be executed from the command palette.
class PaletteAction {
  final String id;
  final String label;
  final String? subtitle;
  final IconData icon;
  final String category;
  final List<String> keywords;
  final void Function(BuildContext context) onExecute;

  /// Pre-lowercased fields for matching — computed once at construction
  /// instead of on every [matchScore] call. With 50+ palette actions
  /// scored on every keystroke, this eliminates O(actions × fields)
  /// redundant [String.toLowerCase] allocations per input event.
  late final String _labelLower = label.toLowerCase();
  late final String _subtitleLower = (subtitle ?? '').toLowerCase();
  late final String _categoryLower = category.toLowerCase();
  late final List<String> _keywordsLower =
      keywords.map((kw) => kw.toLowerCase()).toList(growable: false);

  PaletteAction({
    required this.id,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.category,
    this.keywords = const [],
    required this.onExecute,
  });

  /// Fuzzy match against a query string.
  ///
  /// Expects [query] to already be lowercased by the caller for best
  /// performance when scoring multiple actions against the same query.
  /// Falls back to lowercasing internally if not.
  double matchScore(String query) {
    if (query.isEmpty) return 1.0;
    final q = query.toLowerCase();

    // Exact prefix match on label is highest
    if (_labelLower.startsWith(q)) return 1.0;
    // Contains in label
    if (_labelLower.contains(q)) return 0.9;
    // Keyword match
    for (final kw in _keywordsLower) {
      if (kw.startsWith(q)) return 0.85;
      if (kw.contains(q)) return 0.75;
    }
    // Category match
    if (_categoryLower.contains(q)) return 0.7;
    // Subtitle match
    if (_subtitleLower.contains(q)) return 0.6;
    // Character-by-character fuzzy
    int qi = 0;
    for (int i = 0; i < _labelLower.length && qi < q.length; i++) {
      if (_labelLower[i] == q[qi]) qi++;
    }
    if (qi == q.length) return 0.4;
    return 0.0;
  }
}

/// Service that registers all available palette actions.
class CommandPaletteService {
  CommandPaletteService._();
  static final instance = CommandPaletteService._();

  final List<String> _recentScreenIds = [];
  static const _maxRecent = 5;

  /// Record a screen visit for "recent" ordering.
  void recordVisit(String screenId) {
    _recentScreenIds.remove(screenId);
    _recentScreenIds.insert(0, screenId);
    if (_recentScreenIds.length > _maxRecent) {
      _recentScreenIds.removeLast();
    }
  }

  List<String> get recentScreenIds => List.unmodifiable(_recentScreenIds);

  /// Build the full action list. Call with a context that has access to
  /// navigation (e.g., from within the overlay).
  List<PaletteAction> buildActions() {
    return [
      // ── Navigation ─────────────────────────────────────────────
      _nav('nav_calendar', 'Calendar', Icons.calendar_today, 'Navigation',
          ['schedule', 'dates', 'month', 'week']),
      _nav('nav_stats', 'Stats', Icons.bar_chart, 'Navigation',
          ['statistics', 'analytics', 'charts']),
      _nav('nav_heatmap', 'Activity Heatmap', Icons.grid_on, 'Navigation',
          ['heat', 'contributions']),
      _nav('nav_countdown', 'Countdowns', Icons.timer, 'Navigation',
          ['timer', 'days until']),
      _nav('nav_agenda', 'Agenda Timeline', Icons.view_timeline, 'Navigation',
          ['agenda', 'timeline', 'today']),
      _nav('nav_weekly_report', 'Weekly Report', Icons.summarize, 'Navigation',
          ['report', 'summary']),
      _nav('nav_daily_review', 'Daily Review', Icons.rate_review, 'Navigation',
          ['review', 'reflection']),
      _nav('nav_life_dashboard', 'Life Dashboard', Icons.dashboard, 'Navigation',
          ['dashboard', 'score', 'overview']),

      // ── Trackers ───────────────────────────────────────────────
      _nav('nav_habits', 'Habit Tracker', Icons.check_circle_outline, 'Trackers',
          ['habits', 'streaks', 'daily']),
      _nav('nav_goals', 'Goals', Icons.flag, 'Trackers',
          ['goals', 'objectives', 'targets']),
      _nav('nav_mood', 'Mood Journal', Icons.mood, 'Trackers',
          ['mood', 'feelings', 'emotions']),
      _nav('nav_water', 'Water Tracker', Icons.water_drop, 'Trackers',
          ['water', 'hydration', 'drink']),
      _nav('nav_workout', 'Workout Tracker', Icons.fitness_center, 'Trackers',
          ['exercise', 'gym', 'fitness']),
      _nav('nav_meal', 'Meal Tracker', Icons.restaurant, 'Trackers',
          ['food', 'nutrition', 'calories']),
      _nav('nav_sleep', 'Sleep Tracker', Icons.bedtime, 'Trackers',
          ['sleep', 'rest', 'bedtime']),
      _nav('nav_energy', 'Energy Tracker', Icons.bolt, 'Trackers',
          ['energy', 'fatigue', 'levels']),
      _nav('nav_meditation', 'Meditation', Icons.self_improvement, 'Trackers',
          ['meditate', 'mindfulness', 'calm']),

      // ── Productivity ───────────────────────────────────────────
      _nav('nav_pomodoro', 'Pomodoro Timer', Icons.av_timer, 'Productivity',
          ['focus', 'timer', 'work']),
      _nav('nav_time_tracker', 'Time Tracker', Icons.access_time, 'Productivity',
          ['time', 'hours', 'log']),
      _nav('nav_focus', 'Focus Time', Icons.center_focus_strong, 'Productivity',
          ['focus', 'deep work', 'concentrate']),
      _nav('nav_routine', 'Routine Builder', Icons.repeat, 'Productivity',
          ['routine', 'morning', 'evening']),
      _nav('nav_chores', 'Chore Tracker', Icons.cleaning_services, 'Productivity',
          ['chores', 'tasks', 'housework']),
      _nav('nav_time_budget', 'Time Budget', Icons.pie_chart, 'Productivity',
          ['budget', 'allocation', 'balance']),
      _nav('nav_screen_time', 'Screen Time', Icons.phone_android, 'Productivity',
          ['phone', 'apps', 'digital']),
      _nav('nav_weekly_planner', 'Weekly Planner', Icons.view_week, 'Productivity',
          ['plan', 'week', 'schedule']),

      // ── Finance ────────────────────────────────────────────────
      _nav('nav_expenses', 'Expense Tracker', Icons.attach_money, 'Finance',
          ['money', 'spending', 'budget']),
      _nav('nav_subscriptions', 'Subscriptions', Icons.subscriptions, 'Finance',
          ['recurring', 'monthly', 'bills']),
      _nav('nav_savings', 'Savings Goals', Icons.savings, 'Finance',
          ['save', 'piggybank', 'target']),
      _nav('nav_budget', 'Budget Planner', Icons.account_balance_wallet, 'Finance',
          ['budget', 'plan', 'finance']),

      // ── Personal ───────────────────────────────────────────────
      _nav('nav_contacts', 'Contact Tracker', Icons.contacts, 'Personal',
          ['people', 'relationships', 'network']),
      _nav('nav_gratitude', 'Gratitude Journal', Icons.favorite, 'Personal',
          ['grateful', 'thankful', 'appreciate']),
      _nav('nav_decisions', 'Decision Journal', Icons.balance, 'Personal',
          ['decide', 'choices', 'options']),
      _nav('nav_reading', 'Reading List', Icons.book, 'Personal',
          ['books', 'read', 'library']),
      _nav('nav_skills', 'Skill Tracker', Icons.school, 'Personal',
          ['learn', 'practice', 'improve']),
      _nav('nav_pet', 'Pet Care', Icons.pets, 'Personal',
          ['pet', 'dog', 'cat', 'vet']),
      _nav('nav_plant', 'Plant Care', Icons.local_florist, 'Personal',
          ['plants', 'garden', 'watering']),
      _nav('nav_medication', 'Medication Tracker', Icons.medical_services, 'Personal',
          ['medicine', 'pills', 'health']),
      _nav('nav_commute', 'Commute Tracker', Icons.directions_car, 'Personal',
          ['travel', 'drive', 'commute']),
      _nav('nav_vehicle', 'Vehicle Maintenance', Icons.build_circle, 'Personal',
          ['car', 'vehicle', 'maintenance', 'oil', 'service']),

      // ── Lists ──────────────────────────────────────────────────
      _nav('nav_bucket_list', 'Bucket List', Icons.checklist, 'Lists',
          ['bucket', 'life goals', 'dreams']),
      _nav('nav_travel', 'Travel Log', Icons.flight, 'Lists',
          ['trips', 'vacation', 'travel']),
      _nav('nav_wishlist', 'Wishlist', Icons.card_giftcard, 'Lists',
          ['wish', 'want', 'buy']),
      _nav('nav_watchlist', 'Watchlist', Icons.movie_outlined, 'Lists',
          ['movies', 'tv', 'shows', 'watch', 'film', 'series']),
      _nav('nav_gifts', 'Gift Tracker', Icons.redeem, 'Lists',
          ['gifts', 'presents', 'birthday']),

      // ── Quick Actions ──────────────────────────────────────────
      PaletteAction(
        id: 'action_new_event',
        label: 'New Event',
        subtitle: 'Create a new event',
        icon: Icons.add_circle,
        category: 'Quick Actions',
        keywords: ['add', 'create', 'new', 'event'],
        onExecute: (_) {},  // Wired up in the overlay
      ),
      PaletteAction(
        id: 'action_log_water',
        label: 'Log Water',
        subtitle: 'Quick-add a glass of water',
        icon: Icons.water_drop,
        category: 'Quick Actions',
        keywords: ['water', 'drink', 'hydrate'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_start_pomodoro',
        label: 'Start Pomodoro',
        subtitle: 'Begin a 25-minute focus session',
        icon: Icons.play_circle_filled,
        category: 'Quick Actions',
        keywords: ['focus', 'timer', 'start', 'work'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_log_mood',
        label: 'Log Mood',
        subtitle: 'Record how you\'re feeling',
        icon: Icons.mood,
        category: 'Quick Actions',
        keywords: ['mood', 'feeling', 'emotion'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_daily_review',
        label: 'Start Daily Review',
        subtitle: 'Reflect on your day',
        icon: Icons.rate_review,
        category: 'Quick Actions',
        keywords: ['review', 'reflect', 'day'],
        onExecute: (_) {},
      ),
    ];
  }

  /// Helper to create a navigation action.
  PaletteAction _nav(String id, String label, IconData icon,
      String category, List<String> keywords) {
    return PaletteAction(
      id: id,
      label: label,
      icon: icon,
      category: category,
      keywords: keywords,
      onExecute: (_) {},  // Navigation wired in overlay
    );
  }
}
