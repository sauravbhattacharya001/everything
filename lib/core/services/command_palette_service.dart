import 'package:flutter/material.dart';
import '../utils/feature_registry.dart';

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
///
/// Navigation actions are derived from [FeatureRegistry] — the single
/// source of truth for all app features. This eliminates the previous
/// duplication where a parallel hardcoded list of ~50 navigation entries
/// had to be manually kept in sync with the registry.
class CommandPaletteService {
  CommandPaletteService._();
  static final instance = CommandPaletteService._();

  final List<String> _recentScreenIds = [];
  static const _maxRecent = 5;

  /// Maps [FeatureCategory] to command palette category labels.
  static const _categoryLabels = <FeatureCategory, String>{
    FeatureCategory.planning: 'Navigation',
    FeatureCategory.productivity: 'Productivity',
    FeatureCategory.health: 'Trackers',
    FeatureCategory.finance: 'Finance',
    FeatureCategory.lifestyle: 'Personal',
    FeatureCategory.organization: 'Lists',
    FeatureCategory.tracking: 'Tracking',
  };

  /// Record a screen visit for "recent" ordering.
  void recordVisit(String screenId) {
    _recentScreenIds.remove(screenId);
    _recentScreenIds.insert(0, screenId);
    if (_recentScreenIds.length > _maxRecent) {
      _recentScreenIds.removeLast();
    }
  }

  List<String> get recentScreenIds => List.unmodifiable(_recentScreenIds);

  /// Build the full action list from [FeatureRegistry] plus quick actions.
  ///
  /// Each [FeatureEntry] becomes a navigation action with an id derived
  /// from its label (e.g. "Habit Tracker" → "nav_habit_tracker"). The
  /// onExecute callback navigates to the feature's screen.
  List<PaletteAction> buildActions() {
    final actions = <PaletteAction>[];

    // ── Navigation actions derived from FeatureRegistry ──────────
    for (final feature in FeatureRegistry.features) {
      final id = 'nav_${feature.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+\$'), '')}';
      final category = _categoryLabels[feature.category] ?? feature.category.label;

      actions.add(PaletteAction(
        id: id,
        label: feature.label,
        icon: feature.icon,
        category: category,
        keywords: _deriveKeywords(feature.label),
        onExecute: (_) {},  // Navigation wired in overlay via FeatureRegistry
      ));
    }

    // ── Quick Actions (not derivable from FeatureRegistry) ───────
    actions.addAll([
      PaletteAction(
        id: 'action_new_event',
        label: 'New Event',
        subtitle: 'Create a new event',
        icon: Icons.add_circle,
        category: 'Quick Actions',
        keywords: ['add', 'create', 'new', 'event'],
        onExecute: (_) {},
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
    ]);

    return actions;
  }

  /// Derive search keywords from a feature label by splitting into
  /// individual words. Augmented with common synonyms for better
  /// discoverability.
  static List<String> _deriveKeywords(String label) {
    final words = label.toLowerCase().split(RegExp(r'\s+'));
    // Add common synonyms
    final synonyms = <String, List<String>>{
      'tracker': ['log', 'track', 'monitor'],
      'journal': ['diary', 'log', 'write'],
      'calculator': ['calc', 'compute'],
      'planner': ['plan', 'schedule'],
      'generator': ['create', 'make'],
      'converter': ['convert', 'transform'],
    };
    final result = <String>[...words];
    for (final word in words) {
      if (synonyms.containsKey(word)) {
        result.addAll(synonyms[word]!);
      }
    }
    return result;
  }
}
