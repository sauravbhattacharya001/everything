import 'package:flutter/material.dart';
import '../../core/services/birthday_tracker_service.dart';

/// Birthdays & Anniversaries tracker — never forget an important date.
class BirthdayTrackerScreen extends StatefulWidget {
  const BirthdayTrackerScreen({super.key});

  @override
  State<BirthdayTrackerScreen> createState() => _BirthdayTrackerScreenState();
}

class _BirthdayTrackerScreenState extends State<BirthdayTrackerScreen>
    with SingleTickerProviderStateMixin {
  final List<Occasion> _occasions = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _addOccasion() => _showEditDialog(null);

  void _editOccasion(Occasion o) => _showEditDialog(o);

  void _deleteOccasion(Occasion o) {
    setState(() => _occasions.removeWhere((x) => x.id == o.id));
  }

  void _showEditDialog(Occasion? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final yearCtrl = TextEditingController(
        text: existing?.year?.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final giftCtrl = TextEditingController(text: existing?.giftIdeas ?? '');
    var type = existing?.type ?? OccasionType.birthday;
    var month = existing?.month ?? DateTime.now().month;
    var day = existing?.day ?? DateTime.now().day;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(existing == null ? 'Add Occasion' : 'Edit Occasion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Mom, Wedding',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<OccasionType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: OccasionType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          ))
                      .toList(),
                  onChanged: (v) => setDlg(() => type = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: month,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_monthName(i + 1)),
                          ),
                        ),
                        onChanged: (v) => setDlg(() => month = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: day,
                        decoration: const InputDecoration(labelText: 'Day'),
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (v) => setDlg(() => day = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Year (optional)',
                    hintText: 'e.g. 1990',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: giftCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gift Ideas',
                    hintText: 'Books, watch, flowers...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final yearText = yearCtrl.text.trim();
                final year = yearText.isNotEmpty ? int.tryParse(yearText) : null;
                final occasion = Occasion(
                  id: existing?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  type: type,
                  month: month,
                  day: day,
                  year: year,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                  giftIdeas: giftCtrl.text.trim().isEmpty
                      ? null
                      : giftCtrl.text.trim(),
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                setState(() {
                  if (existing != null) {
                    final idx =
                        _occasions.indexWhere((x) => x.id == existing.id);
                    if (idx >= 0) _occasions[idx] = occasion;
                  } else {
                    _occasions.add(occasion);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = BirthdayTrackerService.getUpcoming(_occasions, now);
    final today = BirthdayTrackerService.todayOccasions(_occasions, now);
    final months = BirthdayTrackerService.byMonth(_occasions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎂 Birthdays & Anniversaries'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Calendar'),
            Tab(text: 'All'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOccasion,
        child: const Icon(Icons.add),
      ),
      body: _occasions.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cake, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No occasions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add a birthday or anniversary',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildUpcomingTab(upcoming, today, now),
                _buildCalendarTab(months),
                _buildAllTab(),
              ],
            ),
    );
  }

  Widget _buildUpcomingTab(
      List<UpcomingOccasion> upcoming, List<Occasion> today, DateTime now) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (today.isNotEmpty) ...[
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 Today!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...today.map((o) {
                    final age = o.ageOn(now);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${o.type.emoji} ${o.name}'
                        '${age != null ? ' — turning $age!' : ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (upcoming.isEmpty && today.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No upcoming occasions in the next 30 days'),
            ),
          ),
        ...upcoming.where((u) => u.daysUntil > 0).map(
              (u) => ListTile(
                leading: CircleAvatar(
                  child: Text(u.occasion.type.emoji),
                ),
                title: Text(u.occasion.name),
                subtitle: Text(
                  '${_monthName(u.occasion.month)} ${u.occasion.day}'
                  '${u.turningAge != null ? ' — turning ${u.turningAge}' : ''}'
                  ' • in ${u.daysUntil} day${u.daysUntil == 1 ? '' : 's'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editOccasion(u.occasion),
              ),
            ),
      ],
    );
  }

  Widget _buildCalendarTab(List<MonthSummary> months) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 12,
      itemBuilder: (ctx, i) {
        final ms = months[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                ms.monthName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ms.occasions.isEmpty ? Colors.grey : null,
                ),
              ),
            ),
            if (ms.occasions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child: Text('—', style: TextStyle(color: Colors.grey)),
              ),
            ...ms.occasions.map(
              (o) => ListTile(
                dense: true,
                leading: Text(o.type.emoji, style: const TextStyle(fontSize: 20)),
                title: Text('${o.day} — ${o.name}'),
                subtitle: o.year != null
                    ? Text('Since ${o.year}')
                    : null,
                onTap: () => _editOccasion(o),
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildAllTab() {
    final sorted = List<Occasion>.from(_occasions)
      ..sort((a, b) => a.name.compareTo(b.name));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final o = sorted[i];
        return Dismissible(
          key: ValueKey(o.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteOccasion(o),
          child: ListTile(
            leading: CircleAvatar(child: Text(o.type.emoji)),
            title: Text(o.name),
            subtitle: Text(
              '${_monthName(o.month)} ${o.day}'
              '${o.year != null ? ', ${o.year}' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (o.giftIdeas != null)
                  const Icon(Icons.card_giftcard, size: 18, color: Colors.pink),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _editOccasion(o),
          ),
        );
      },
    );
  }
}
