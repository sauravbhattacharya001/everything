/// Event Search Service — full-text search and advanced filtering for events.
///
/// Provides fuzzy text matching across event titles, descriptions, and locations,
/// combined with structured filters for priority, tags, date ranges, and more.
/// Results are ranked by relevance and returned with match highlights.
///
/// Usage:
/// ```dart
/// final search = EventSearchService();
/// final results = search.search(
///   events,
///   query: 'meeting',
///   filters: SearchFilters(
///     priorities: {EventPriority.high, EventPriority.urgent},
///     dateRange: DateTimeRange(start: start, end: end),
///   ),
/// );
/// for (final r in results) {
///   print('${r.event.title} — score: ${r.score}');
/// }
/// ```

import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/event_tag.dart';

/// Defines which fields to search in.
enum SearchField {
  title,
  description,
  location,
  tags,
  checklist,
}

/// Structured filters that can be combined with text search.
class SearchFilters {
  /// Only include events with these priorities.
  final Set<EventPriority>? priorities;

  /// Only include events within this date range.
  final DateTimeRange? dateRange;

  /// Only include events that have ALL of these tag names.
  final Set<String>? requiredTags;

  /// Only include events that have ANY of these tag names.
  final Set<String>? anyTags;

  /// Only include events with a non-empty location.
  final bool? hasLocation;

  /// Only include recurring events (true) or non-recurring (false).
  final bool? isRecurring;

  /// Only include events with checklist items.
  final bool? hasChecklist;

  /// Only include events with attachments.
  final bool? hasAttachments;

  /// Which fields to search text in. Null means all fields.
  final Set<SearchField>? searchFields;

  const SearchFilters({
    this.priorities,
    this.dateRange,
    this.requiredTags,
    this.anyTags,
    this.hasLocation,
    this.isRecurring,
    this.hasChecklist,
    this.hasAttachments,
    this.searchFields,
  });

  /// Returns true if no filters are set.
  bool get isEmpty =>
      priorities == null &&
      dateRange == null &&
      requiredTags == null &&
      anyTags == null &&
      hasLocation == null &&
      isRecurring == null &&
      hasChecklist == null &&
      hasAttachments == null &&
      searchFields == null;
}

/// How to sort search results.
enum SearchSort {
  relevance,
  dateAscending,
  dateDescending,
  priorityDescending,
  titleAscending,
}

/// A single text match within a search result.
class SearchMatch {
  final SearchField field;
  final String snippet;
  final int start;
  final int length;

  const SearchMatch({
    required this.field,
    required this.snippet,
    required this.start,
    required this.length,
  });
}

/// A search result containing the matched event, relevance score, and
/// details about where matches occurred.
class SearchResult {
  final EventModel event;
  final double score;
  final List<SearchMatch> matches;

  const SearchResult({
    required this.event,
    required this.score,
    this.matches = const [],
  });
}

/// Pre-processed filter state to avoid repeated computation per event.
///
/// Tag names from [SearchFilters.requiredTags] and [SearchFilters.anyTags]
/// are lowercased once and stored here so [_passesFilters] never calls
/// [String.toLowerCase] inside its per-event loop.
class _PreparedFilters {
  final SearchFilters raw;

  /// Pre-lowercased required tag names (null when filter absent).
  final Set<String>? requiredTagsLower;

  /// Pre-lowercased "any" tag names (null when filter absent).
  final Set<String>? anyTagsLower;

  /// Whether any tag-based filter is active — avoids building the
  /// per-event lowercase tag set when no tag filters are in use.
  final bool hasTagFilter;

  _PreparedFilters(this.raw)
      : requiredTagsLower = raw.requiredTags?.map((t) => t.toLowerCase()).toSet(),
        anyTagsLower = raw.anyTags?.map((t) => t.toLowerCase()).toSet(),
        hasTagFilter = raw.requiredTags != null || raw.anyTags != null;
}

/// Performs search and filtering across a list of events.
class EventSearchService {
  static const Map<SearchField, double> _fieldWeights = {
    SearchField.title: 1.0,
    SearchField.description: 0.6,
    SearchField.location: 0.7,
    SearchField.tags: 0.8,
    SearchField.checklist: 0.4,
  };

  /// Compiled once instead of per-[_tokenize] call.
  static final RegExp _whitespace = RegExp(r'\s+');

  const EventSearchService();

  /// Search events with an optional text query and structured filters.
  List<SearchResult> search(
    List<EventModel> events, {
    String query = '',
    SearchFilters filters = const SearchFilters(),
    SearchSort? sort,
    int? limit,
  }) {
    final prepared = _PreparedFilters(filters);
    var filtered = events.where((e) => _passesFilters(e, prepared)).toList();

    final normalizedQuery = query.trim().toLowerCase();
    List<SearchResult> results;

    if (normalizedQuery.isEmpty) {
      results = filtered.map((e) => SearchResult(event: e, score: 1.0)).toList();
    } else {
      results = <SearchResult>[];
      final queryTerms = _tokenize(normalizedQuery);
      final searchFields = filters.searchFields ?? SearchField.values.toSet();

      for (final event in filtered) {
        final matches = <SearchMatch>[];
        double totalScore = 0.0;

        for (final field in searchFields) {
          final text = _getFieldText(event, field);
          if (text.isEmpty) continue;
          final fieldScore = _scoreField(text, queryTerms, field, matches);
          totalScore += fieldScore * (_fieldWeights[field] ?? 0.5);
        }

        if (totalScore > 0) {
          results.add(SearchResult(
            event: event,
            score: totalScore.clamp(0.0, 1.0),
            matches: matches,
          ));
        }
      }
    }

    final effectiveSort =
        sort ?? (normalizedQuery.isEmpty ? SearchSort.dateAscending : SearchSort.relevance);
    _sortResults(results, effectiveSort);

    if (limit != null && limit < results.length) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  /// Returns suggested search terms based on existing event data.
  List<String> suggest(
    List<EventModel> events, {
    required String partial,
    int limit = 5,
  }) {
    if (partial.trim().isEmpty) return const [];
    final lower = partial.trim().toLowerCase();
    final suggestions = <String, int>{};

    for (final event in events) {
      _addSuggestion(suggestions, event.title, lower);
      if (event.location.isNotEmpty) {
        _addSuggestion(suggestions, event.location, lower);
      }
      for (final tag in event.tags) {
        _addSuggestion(suggestions, tag.name, lower);
      }
    }

    final sorted = suggestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Check whether [event] passes all active filters.
  ///
  /// Uses [_PreparedFilters] so that tag name lowercasing is done once
  /// per search call rather than once per event.
  bool _passesFilters(EventModel event, _PreparedFilters pf) {
    final filters = pf.raw;
    if (filters.priorities != null && !filters.priorities!.contains(event.priority)) return false;
    if (filters.dateRange != null) {
      if (event.date.isAfter(filters.dateRange!.end) || event.date.isBefore(filters.dateRange!.start)) return false;
    }

    // Build the per-event lowercase tag set at most once, only when
    // a tag filter is actually active.
    if (pf.hasTagFilter) {
      final eventTagsLower = event.tags.map((t) => t.name.toLowerCase()).toSet();

      if (pf.requiredTagsLower != null) {
        for (final req in pf.requiredTagsLower!) {
          if (!eventTagsLower.contains(req)) return false;
        }
      }
      if (pf.anyTagsLower != null) {
        if (!pf.anyTagsLower!.any((t) => eventTagsLower.contains(t))) return false;
      }
    }

    if (filters.hasLocation == true && event.location.isEmpty) return false;
    if (filters.hasLocation == false && event.location.isNotEmpty) return false;
    if (filters.isRecurring == true && !event.isRecurring) return false;
    if (filters.isRecurring == false && event.isRecurring) return false;
    if (filters.hasChecklist == true && !event.checklist.hasItems) return false;
    if (filters.hasChecklist == false && event.checklist.hasItems) return false;
    if (filters.hasAttachments == true && !event.attachments.hasAttachments) return false;
    if (filters.hasAttachments == false && event.attachments.hasAttachments) return false;
    return true;
  }

  /// Tokenize text by whitespace using the pre-compiled [_whitespace] regex.
  List<String> _tokenize(String text) => text.split(_whitespace).where((t) => t.isNotEmpty).toList();

  String _getFieldText(EventModel event, SearchField field) {
    switch (field) {
      case SearchField.title: return event.title;
      case SearchField.description: return event.description;
      case SearchField.location: return event.location;
      case SearchField.tags: return event.tags.map((t) => t.name).join(' ');
      case SearchField.checklist:
        return event.checklist.hasItems ? event.checklist.items.map((i) => i.text).join(' ') : '';
    }
  }

  double _scoreField(String text, List<String> queryTerms, SearchField field, List<SearchMatch> matches) {
    final lower = text.toLowerCase();
    double score = 0.0;
    int matchedTerms = 0;

    for (final term in queryTerms) {
      final index = lower.indexOf(term);
      if (index >= 0) {
        matchedTerms++;
        if (lower == term) {
          score += 1.0;
        } else if (lower.startsWith(term)) {
          score += 0.8;
        } else {
          score += 0.5;
        }
        final snippetStart = (index - 20).clamp(0, lower.length);
        final snippetEnd = (index + term.length + 20).clamp(0, text.length);
        matches.add(SearchMatch(field: field, snippet: text.substring(snippetStart, snippetEnd), start: index, length: term.length));
      }
    }
    if (queryTerms.isNotEmpty) score *= matchedTerms / queryTerms.length;
    return score;
  }

  /// Sort results, using a Schwartzian transform for [titleAscending]
  /// to avoid calling [String.toLowerCase] O(n log n) times.
  void _sortResults(List<SearchResult> results, SearchSort sort) {
    switch (sort) {
      case SearchSort.relevance:
        results.sort((a, b) => b.score.compareTo(a.score));
      case SearchSort.dateAscending:
        results.sort((a, b) => a.event.date.compareTo(b.event.date));
      case SearchSort.dateDescending:
        results.sort((a, b) => b.event.date.compareTo(a.event.date));
      case SearchSort.priorityDescending:
        results.sort((a, b) => b.event.priority.index.compareTo(a.event.priority.index));
      case SearchSort.titleAscending:
        // Pre-compute lowercased titles once (O(n)) instead of
        // calling toLowerCase() inside the comparator (O(n log n)).
        final keys = {for (final r in results) r: r.event.title.toLowerCase()};
        results.sort((a, b) => keys[a]!.compareTo(keys[b]!));
    }
  }

  void _addSuggestion(Map<String, int> suggestions, String text, String partial) {
    final lower = text.toLowerCase();
    if (lower.contains(partial) && lower != partial) {
      suggestions[text] = (suggestions[text] ?? 0) + 1;
    }
  }
}
