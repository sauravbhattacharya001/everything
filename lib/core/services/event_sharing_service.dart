import '../../../models/event_model.dart';

/// Supported sharing formats for events.
enum ShareFormat {
  /// Plain text suitable for SMS/messaging.
  plainText,

  /// Markdown for rich-text contexts.
  markdown,

  /// Google Calendar "Add Event" URL.
  googleCalendarUrl,

  /// Outlook Web "Add Event" URL.
  outlookUrl,
}

/// Service that generates shareable representations of events.
///
/// Supports plain text, markdown, and deep-link URLs for Google Calendar
/// and Outlook Web. Useful for sending event details via messaging apps,
/// email, or clipboard sharing.
///
/// Usage:
/// ```dart
/// final service = EventSharingService();
/// final text = service.share(event, format: ShareFormat.plainText);
/// final url  = service.share(event, format: ShareFormat.googleCalendarUrl);
/// ```
class EventSharingService {
  const EventSharingService();

  /// Generates a shareable string for [event] in the given [format].
  String share(EventModel event, {ShareFormat format = ShareFormat.plainText}) {
    switch (format) {
      case ShareFormat.plainText:
        return _plainText(event);
      case ShareFormat.markdown:
        return _markdown(event);
      case ShareFormat.googleCalendarUrl:
        return _googleCalendarUrl(event);
      case ShareFormat.outlookUrl:
        return _outlookUrl(event);
    }
  }

  /// Generates all available share options as a map.
  Map<ShareFormat, String> shareAll(EventModel event) {
    return {
      for (final fmt in ShareFormat.values) fmt: share(event, format: fmt),
    };
  }

  // ── Plain text ──────────────────────────────────────────────────────

  String _plainText(EventModel event) {
    final buf = StringBuffer();
    buf.writeln('📅 ${event.title}');
    buf.writeln('Date: ${_formatDate(event.date)}');
    if (event.endDate != null) {
      buf.writeln('Until: ${_formatDate(event.endDate!)}');
    }
    if (event.location.isNotEmpty) {
      buf.writeln('📍 ${event.location}');
    }
    if (event.description.isNotEmpty) {
      buf.writeln();
      buf.writeln(event.description);
    }
    buf.writeln();
    buf.writeln('Priority: ${event.priority.label}');
    if (event.tags.isNotEmpty) {
      buf.writeln('Tags: ${event.tags.map((t) => '#${t.name}').join(' ')}');
    }
    return buf.toString().trimRight();
  }

  // ── Markdown ────────────────────────────────────────────────────────

  String _markdown(EventModel event) {
    final buf = StringBuffer();
    buf.writeln('## 📅 ${event.title}');
    buf.writeln();
    buf.writeln('| Field | Value |');
    buf.writeln('|-------|-------|');
    buf.writeln('| **Date** | ${_formatDate(event.date)} |');
    if (event.endDate != null) {
      buf.writeln('| **End** | ${_formatDate(event.endDate!)} |');
    }
    if (event.location.isNotEmpty) {
      buf.writeln('| **Location** | ${event.location} |');
    }
    buf.writeln('| **Priority** | ${event.priority.label} |');
    if (event.tags.isNotEmpty) {
      buf.writeln(
          '| **Tags** | ${event.tags.map((t) => '`${t.name}`').join(', ')} |');
    }
    if (event.description.isNotEmpty) {
      buf.writeln();
      buf.writeln('> ${event.description.replaceAll('\n', '\n> ')}');
    }
    return buf.toString().trimRight();
  }

  // ── Google Calendar URL ─────────────────────────────────────────────

  String _googleCalendarUrl(EventModel event) {
    final dates = _calendarDatePair(event);
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': event.title,
      'dates': '${dates.$1}/${dates.$2}',
      if (event.description.isNotEmpty) 'details': event.description,
      if (event.location.isNotEmpty) 'location': event.location,
    };
    final query =
        params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://calendar.google.com/calendar/render?$query';
  }

  // ── Outlook Web URL ─────────────────────────────────────────────────

  String _outlookUrl(EventModel event) {
    final params = <String, String>{
      'path': '/calendar/action/compose',
      'rru': 'addevent',
      'subject': event.title,
      'startdt': event.date.toUtc().toIso8601String(),
      'enddt': (event.endDate ?? event.date.add(const Duration(hours: 1)))
          .toUtc()
          .toIso8601String(),
      if (event.description.isNotEmpty) 'body': event.description,
      if (event.location.isNotEmpty) 'location': event.location,
    };
    final query =
        params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://outlook.live.com/calendar/0/deeplink/compose?$query';
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Formats a DateTime for display (e.g. "Mon, Mar 2, 2026 at 11:30 PM").
  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day, $month ${dt.day}, ${dt.year} at $hour:$minute $ampm';
  }

  /// Produces a Google Calendar date pair (start/end) in compact UTC format.
  (String, String) _calendarDatePair(EventModel event) {
    String compact(DateTime dt) {
      final u = dt.toUtc();
      return '${u.year}'
          '${u.month.toString().padLeft(2, '0')}'
          '${u.day.toString().padLeft(2, '0')}'
          'T'
          '${u.hour.toString().padLeft(2, '0')}'
          '${u.minute.toString().padLeft(2, '0')}'
          '${u.second.toString().padLeft(2, '0')}'
          'Z';
    }

    final start = compact(event.date);
    final end = compact(
        event.endDate ?? event.date.add(const Duration(hours: 1)));
    return (start, end);
  }
}
