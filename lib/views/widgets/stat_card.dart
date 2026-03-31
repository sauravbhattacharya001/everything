import 'package:flutter/material.dart';

/// Reusable stat card widget used across multiple tracker screens.
///
/// Displays an emoji icon, a bold value, and a label in a compact card.
/// Designed to be used inside a [Row] with [Expanded] wrappers for
/// equal-width stat grids:
///
/// ```dart
/// Row(children: [
///   StatCard(emoji: '📚', label: 'Total', value: '42'),
///   const SizedBox(width: 8),
///   StatCard(emoji: '✅', label: 'Done', value: '12'),
/// ])
/// ```
class StatCard extends StatelessWidget {
  /// Emoji or icon text displayed at the top.
  final String emoji;

  /// Short label below the value (e.g., "Total", "Hours").
  final String label;

  /// The prominent value string (e.g., "42", "3.5").
  final String value;

  /// Optional font size for the emoji. Defaults to 20.
  final double emojiFontSize;

  const StatCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    this.emojiFontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: TextStyle(fontSize: emojiFontSize)),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
