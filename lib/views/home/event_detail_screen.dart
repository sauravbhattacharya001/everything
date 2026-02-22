import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/event_service.dart';
import '../../core/services/ics_export_service.dart';
import '../../models/event_model.dart';
import '../../models/recurrence_rule.dart';
import '../../state/providers/event_provider.dart';
import '../widgets/event_form_dialog.dart';

/// Full-screen detail view for a single event.
///
/// Displays the event's title, description, date/time, and priority
/// with a colored header. Provides edit and delete actions.
///
/// Receives an [EventService] from the parent screen to ensure all
/// mutations go through a single coordinated service layer rather
/// than creating separate [EventRepository] instances.
class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final EventService eventService;

  const EventDetailScreen({
    required this.event,
    required this.eventService,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Watch provider to get the latest version of this event.
    // Uses O(1) index lookup instead of O(n) linear scan.
    final eventProvider = Provider.of<EventProvider>(context);
    final currentEvent = eventProvider.getEventById(event.id) ?? event;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: currentEvent.priority.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => _exportEvent(context, currentEvent),
            tooltip: 'Export as calendar event',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editEvent(context, currentEvent),
            tooltip: 'Edit event',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, currentEvent),
            tooltip: 'Delete event',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored header section
            Container(
              color: currentEvent.priority.color,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentEvent.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        currentEvent.priority.icon,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentEvent.priority.label} Priority',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: currentEvent.priority.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: currentEvent.priority.color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy')
                                  .format(currentEvent.date),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(currentEvent.date),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Description card (only if description exists)
            if (currentEvent.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes,
                                size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentEvent.description,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Tags card (only if tags exist)
            if (currentEvent.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.label_outline,
                                size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Tags',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: currentEvent.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: tag.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tag.color.withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: tag.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tag.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tag.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Recurrence card (only if recurring)
            if (currentEvent.isRecurring) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.repeat,
                                size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Recurrence',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.repeat,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentEvent.recurrence!.summary,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Next 3 occurrences preview
                        _buildNextOccurrences(currentEvent),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Time until/since event
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          currentEvent.date.isAfter(DateTime.now())
                              ? Icons.upcoming
                              : Icons.history,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _timeDescription(currentEvent.date),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNextOccurrences(EventModel event) {
    final occurrences = event.generateOccurrences(maxOccurrences: 4);
    if (occurrences.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show at most the next 3 occurrences
    final previewOccurrences = occurrences.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next occurrences',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        ...previewOccurrences.map((occ) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM dd, yyyy – h:mm a')
                        .format(occ.date),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            )),
        if (occurrences.length < (event.recurrence!.endDate != null ? 100 : 4))
          const SizedBox.shrink()
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '…and more',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[500],
              ),
            ),
          ),
      ],
    );
  }

  String _timeDescription(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      final past = now.difference(date);
      if (past.inDays > 30) {
        return '${(past.inDays / 30).floor()} month(s) ago';
      }
      if (past.inDays > 0) {
        return '${past.inDays} day${past.inDays == 1 ? '' : 's'} ago';
      }
      if (past.inHours > 0) {
        return '${past.inHours} hour${past.inHours == 1 ? '' : 's'} ago';
      }
      return '${past.inMinutes} minute${past.inMinutes == 1 ? '' : 's'} ago';
    }

    if (diff.inDays > 30) {
      return 'In ${(diff.inDays / 30).floor()} month(s)';
    }
    if (diff.inDays > 0) {
      return 'In ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    }
    if (diff.inHours > 0) {
      return 'In ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    }
    return 'In ${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}';
  }

  Future<void> _exportEvent(BuildContext context, EventModel event) async {
    try {
      final icsService = IcsExportService();
      final icsContent = icsService.exportEvent(event);
      final filename = icsService.generateFilename(event);

      // Write to temp directory for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(icsContent);

      // Share via platform share sheet
      await Share.shareXFiles(
        [XFile(file.path, mimeType: IcsExportService.mimeType)],
        subject: event.title,
        text: 'Event: ${event.title}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editEvent(BuildContext context, EventModel event) async {
    final edited = await EventFormDialog.show(context, event: event);
    if (edited != null && context.mounted) {
      await eventService.updateEvent(edited);
    }
  }

  Future<void> _confirmDelete(BuildContext context, EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await eventService.deleteEvent(event.id);
      Navigator.of(context).pop();
    }
  }
}
