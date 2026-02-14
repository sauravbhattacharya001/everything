import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/providers/event_provider.dart';
import '../../models/event_model.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: ListView.builder(
        itemCount: eventProvider.events.length,
        itemBuilder: (context, index) {
          return EventCard(event: eventProvider.events[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a sample event
          eventProvider.addEvent(
            EventModel(
              id: DateTime.now().toString(),
              title: 'New Event',
              date: DateTime.now(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
