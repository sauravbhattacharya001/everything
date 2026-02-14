import 'package:flutter/material.dart';

/// A circular avatar that loads a user's profile image from a network URL.
///
/// Handles loading errors gracefully by showing the user's initials
/// (if [fallbackInitials] is provided) or a generic person icon.
///
/// Example:
/// ```dart
/// UserAvatar(imageUrl: 'https://example.com/photo.jpg', fallbackInitials: 'SB')
/// ```
class UserAvatar extends StatelessWidget {
  /// The network URL of the user's profile image.
  final String imageUrl;

  /// Optional initials to display when the image fails to load.
  /// If null, a generic person icon is shown instead.
  final String? fallbackInitials;

  /// The radius of the avatar circle. Defaults to 24.
  final double radius;

  const UserAvatar({
    required this.imageUrl,
    this.fallbackInitials,
    this.radius = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      onBackgroundImageError: imageUrl.isNotEmpty
          ? (_, __) {
              // Silently handle broken image URLs — the fallback child
              // (initials or icon) will be visible instead.
            }
          : null,
      child: imageUrl.isEmpty || fallbackInitials != null
          ? _buildFallback()
          : null,
    );
  }

  Widget _buildFallback() {
    if (fallbackInitials != null && fallbackInitials!.isNotEmpty) {
      return Text(
        fallbackInitials!.substring(0, fallbackInitials!.length.clamp(0, 2)),
        style: TextStyle(fontSize: radius * 0.6, fontWeight: FontWeight.w600),
      );
    }
    return Icon(Icons.person, size: radius);
  }
}
