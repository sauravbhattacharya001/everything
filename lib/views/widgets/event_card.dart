import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../core/utils/date_utils.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onDelete;

  const EventCard({required this.event, this.onDelete, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(AppDateUtils.timeAgo(event.date)),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Event'),
                      content: Text('Delete "${event.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onDelete!();
                          },
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
