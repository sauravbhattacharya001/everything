import 'dart:convert';
import '../models/event_model.dart';
import '../models/recurrence_rule.dart';

/// Service for generating iCalendar (ICS/RFC 5545) content from events.
///
/// Supports single event export, bulk export, and recurrence rules.
/// The generated .ics files can be imported into Google Calendar,
/// Apple Calendar, Outlook, and other standards-compliant clients.
class IcsExportService {
  /// PRODID identifier for the generated calendar files.
  static const String prodId = '-//Everything App//Event Export//EN';

  /// Maximum line length before folding (RFC 5545 §3.1).
  static const int _maxLineLength = 75;

  /// Exports a single event as an ICS string.
  String exportEvent(EventModel event) {
    return _wrapCalendar([_buildVEvent(event)]);
  }

  /// Exports multiple events as a single ICS string.
  String exportEvents(List<EventModel> events) {
    final vevents = events.map(_buildVEvent).toList();
    return _wrapCalendar(vevents);
  }

  /// Builds a VEVENT block for a single event.
  String _buildVEvent(EventModel event) {
    final buf = StringBuffer();
    buf.writeln('BEGIN:VEVENT');

    // UID — unique identifier (use event ID + domain)
    buf.writeln(_foldLine('UID:${_escapeText(event.id)}@everything.app'));

    // DTSTAMP — timestamp of creation (now, in UTC)
    buf.writeln('DTSTAMP:${_formatDateTimeUtc(DateTime.now().toUtc())}');

    // DTSTART — event start time
    buf.writeln('DTSTART:${_formatDateTime(event.date)}');

    // DTEND — event end time (default 1 hour duration)
    final endDate = event.date.add(const Duration(hours: 1));
    buf.writeln('DTEND:${_formatDateTime(endDate)}');

    // SUMMARY — event title
    buf.writeln(_foldLine('SUMMARY:${_escapeText(event.title)}'));

    // DESCRIPTION — event description + metadata
    if (event.description.isNotEmpty || event.tags.isNotEmpty) {
      final descParts = <String>[];
      if (event.description.isNotEmpty) {
        descParts.add(event.description);
      }
      if (event.tags.isNotEmpty) {
        descParts.add('Tags: ${event.tags.map((t) => t.name).join(", ")}');
      }
      descParts.add('Priority: ${event.priority.label}');
      buf.writeln(_foldLine('DESCRIPTION:${_escapeText(descParts.join("\\n"))}'));
    }

    // PRIORITY — RFC 5545 priority (1=highest, 9=lowest)
    buf.writeln('PRIORITY:${_mapPriority(event.priority)}');

    // CATEGORIES — tags as comma-separated categories
    if (event.tags.isNotEmpty) {
      buf.writeln(_foldLine(
        'CATEGORIES:${event.tags.map((t) => _escapeText(t.name)).join(",")}',
      ));
    }

    // RRULE — recurrence rule
    if (event.recurrence != null) {
      buf.writeln(_buildRRule(event.recurrence!));
    }

    buf.write('END:VEVENT');
    return buf.toString();
  }

  /// Wraps VEVENT blocks in a VCALENDAR container.
  String _wrapCalendar(List<String> vevents) {
    final buf = StringBuffer();
    buf.writeln('BEGIN:VCALENDAR');
    buf.writeln('VERSION:2.0');
    buf.writeln(_foldLine('PRODID:$prodId'));
    buf.writeln('CALSCALE:GREGORIAN');
    buf.writeln('METHOD:PUBLISH');

    for (final vevent in vevents) {
      buf.writeln(vevent);
    }

    buf.write('END:VCALENDAR');
    return buf.toString();
  }

  /// Converts a [RecurrenceRule] to an ICS RRULE property.
  String _buildRRule(RecurrenceRule rule) {
    final parts = <String>['RRULE:FREQ=${_mapFrequency(rule.frequency)}'];

    if (rule.interval > 1) {
      parts.add('INTERVAL=${rule.interval}');
    }

    if (rule.endDate != null) {
      parts.add('UNTIL=${_formatDateTime(rule.endDate!)}');
    }

    return parts.join(';');
  }

  /// Maps [RecurrenceFrequency] to ICS FREQ value.
  String _mapFrequency(RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }

  /// Maps [EventPriority] to RFC 5545 integer priority.
  ///
  /// RFC 5545: 1 = highest priority, 5 = medium, 9 = lowest.
  int _mapPriority(EventPriority priority) {
    switch (priority) {
      case EventPriority.urgent:
        return 1;
      case EventPriority.high:
        return 3;
      case EventPriority.medium:
        return 5;
      case EventPriority.low:
        return 9;
    }
  }

  /// Formats a DateTime as ICS datetime string (YYYYMMDDTHHMMSS).
  String _formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}'
        'T${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  /// Formats a UTC DateTime with trailing Z.
  String _formatDateTimeUtc(DateTime dt) {
    return '${_formatDateTime(dt)}Z';
  }

  /// Escapes special characters per RFC 5545 §3.3.11.
  ///
  /// Backslashes, semicolons, commas, and newlines must be escaped.
  String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
  }

  /// Folds long lines per RFC 5545 §3.1.
  ///
  /// Lines longer than 75 octets are broken with a CRLF followed by
  /// a single whitespace character (linear whitespace folding).
  String _foldLine(String line) {
    if (line.length <= _maxLineLength) return line;

    final buf = StringBuffer();
    var offset = 0;
    while (offset < line.length) {
      final end = (offset == 0)
          ? _maxLineLength
          : offset + _maxLineLength - 1; // -1 for the leading space
      if (end >= line.length) {
        buf.write(line.substring(offset));
        break;
      }
      buf.writeln(line.substring(offset, end));
      buf.write(' '); // continuation line starts with space
      offset = end;
    }
    return buf.toString();
  }

  /// Generates a filename for an event export.
  String generateFilename(EventModel event) {
    final sanitized = event.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final truncated = sanitized.length > 50
        ? sanitized.substring(0, 50)
        : sanitized;
    return '${truncated.isEmpty ? "event" : truncated}.ics';
  }

  /// Generates a filename for a bulk export.
  String generateBulkFilename() {
    final now = DateTime.now();
    return 'everything_events_'
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.ics';
  }

  /// Returns the MIME type for ICS files.
  static const String mimeType = 'text/calendar';

  /// Returns the raw bytes for sharing via platform channels.
  List<int> exportEventBytes(EventModel event) {
    return utf8.encode(exportEvent(event));
  }

  /// Returns the raw bytes for sharing multiple events.
  List<int> exportEventsBytes(List<EventModel> events) {
    return utf8.encode(exportEvents(events));
  }
}
