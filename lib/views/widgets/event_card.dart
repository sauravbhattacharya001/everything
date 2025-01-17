import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;

  EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(event.date),
      ),
    );
  }
}
