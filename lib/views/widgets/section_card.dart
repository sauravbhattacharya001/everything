import 'package:flutter/material.dart';

/// Reusable section card widget used across multiple tracker screens.
///
/// Wraps content in a [Card] with a title header and consistent padding.
/// Common pattern across 20+ screens in the app.
///
/// ```dart
/// SectionCard(
///   title: '📊 Genre Breakdown',
///   child: Column(children: [...]),
/// )
/// ```
class SectionCard extends StatelessWidget {
  /// Section title displayed at the top (e.g., "🔥 Reading Streak").
  final String title;

  /// Content widget displayed below the title.
  final Widget child;

  /// Optional padding override. Defaults to 16 on all sides.
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
