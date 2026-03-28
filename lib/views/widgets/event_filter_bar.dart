import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/event_tag.dart';

/// A reusable search + filter bar for events.
///
/// Displays a search field, priority filter chips, and tag filter chips.
/// This widget is stateless — all filter state is owned by the parent
/// and communicated via callbacks, following Flutter's "state up" pattern.
class EventFilterBar extends StatelessWidget {
  /// Controller for the search text field.
  final TextEditingController searchController;

  /// Current search query (lowercased, trimmed).
  final String searchQuery;

  /// Currently active priority filters.
  final Set<EventPriority> activePriorityFilters;

  /// Currently active tag filters (lowercased tag names).
  final Set<String> activeTagFilters;

  /// Pre-computed priority counts from the full (unfiltered) event list.
  final Map<EventPriority, int> priorityCounts;

  /// Pre-computed tag objects keyed by lowercased name.
  final Map<String, EventTag> allTags;

  /// Pre-computed tag counts from the full (unfiltered) event list.
  final Map<String, int> tagCounts;

  /// Called when a priority filter is toggled.
  final void Function(EventPriority priority, bool selected) onPriorityToggled;

  /// Called when a tag filter is toggled.
  final void Function(String tagKey, bool selected) onTagToggled;

  const EventFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.activePriorityFilters,
    required this.activeTagFilters,
    required this.priorityCounts,
    required this.allTags,
    required this.tagCounts,
    required this.onPriorityToggled,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildPriorityChips(),
          if (allTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildTagChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search events...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPriorityChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Priority:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          ...EventPriority.values.map((priority) {
            final isSelected = activePriorityFilters.contains(priority);
            final count = priorityCounts[priority] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priority.icon,
                      size: 14,
                      color: isSelected ? Colors.white : priority.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${priority.label} ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : priority.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: priority.color,
                backgroundColor: priority.color.withAlpha(20),
                checkmarkColor: Colors.white,
                onSelected: (selected) =>
                    onPriorityToggled(priority, selected),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTagChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Tags:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          ...allTags.entries.map((entry) {
            final tag = entry.value;
            final key = entry.key;
            final isSelected = activeTagFilters.contains(key);
            final count = tagCounts[key] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : tag.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tag.name} ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : tag.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: tag.color,
                backgroundColor: tag.color.withAlpha(20),
                checkmarkColor: Colors.white,
                onSelected: (selected) => onTagToggled(key, selected),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }
}
