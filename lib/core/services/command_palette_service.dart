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
  /// instead of on every [matchScore] call. With 100+ palette actions
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
/// Navigation actions are auto-generated from [FeatureRegistry] so that
/// adding a new feature screen requires only a single entry in the
/// registry — both the navigation drawer and the command palette pick
/// it up automatically. Previously, ~40 screens were hardcoded here
/// while the registry had 100+, leaving 60+ features undiscoverable
/// from the palette.
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

  /// Cached action list — rebuilt only when the feature count changes
  /// (which in practice means never at runtime, since [FeatureRegistry]
  /// is static).
  List<PaletteAction>? _cachedActions;
  int _cachedFeatureCount = -1;

  /// Build the full action list from [FeatureRegistry] + quick actions.
  ///
  /// Navigation entries are derived automatically from
  /// [FeatureRegistry.features], so every registered feature is
  /// searchable from the command palette without manual maintenance.
  List<PaletteAction> buildActions() {
    if (_cachedActions != null &&
        _cachedFeatureCount == FeatureRegistry.features.length) {
      return _cachedActions!;
    }

    final actions = <PaletteAction>[];

    // ── Auto-generate navigation actions from FeatureRegistry ────
    for (int i = 0; i < FeatureRegistry.features.length; i++) {
      final feature = FeatureRegistry.features[i];
      // Derive a stable id from the label (e.g. "Mood Journal" → "nav_mood_journal")
      final id = 'nav_${feature.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '')}';
      actions.add(PaletteAction(
        id: id,
        label: feature.label,
        icon: feature.icon,
        category: feature.category.label,
        // Split label words as keywords for better fuzzy matching
        keywords: feature.label.toLowerCase().split(RegExp(r'\s+')),
        onExecute: (_) {},  // Navigation wired in overlay via FeatureRegistry
      ));
    }

    // ── Quick Actions (not tied to FeatureRegistry) ──────────────
    actions.addAll([
      PaletteAction(
        id: 'action_new_event',
        label: 'New Event',
        subtitle: 'Create a new event',
        icon: Icons.add_circle,
        category: 'Quick Actions',
        keywords: const ['add', 'create', 'new', 'event'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_log_water',
        label: 'Log Water',
        subtitle: 'Quick-add a glass of water',
        icon: Icons.water_drop,
        category: 'Quick Actions',
        keywords: const ['water', 'drink', 'hydrate'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_start_pomodoro',
        label: 'Start Pomodoro',
        subtitle: 'Begin a 25-minute focus session',
        icon: Icons.play_circle_filled,
        category: 'Quick Actions',
        keywords: const ['focus', 'timer', 'start', 'work'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_log_mood',
        label: 'Log Mood',
        subtitle: 'Record how you\'re feeling',
        icon: Icons.mood,
        category: 'Quick Actions',
        keywords: const ['mood', 'feeling', 'emotion'],
        onExecute: (_) {},
      ),
      PaletteAction(
        id: 'action_daily_review',
        label: 'Start Daily Review',
        subtitle: 'Reflect on your day',
        icon: Icons.rate_review,
        category: 'Quick Actions',
        keywords: const ['review', 'reflect', 'day'],
        onExecute: (_) {},
      ),
    ]);

    _cachedActions = actions;
    _cachedFeatureCount = FeatureRegistry.features.length;
    return actions;
  }
}
