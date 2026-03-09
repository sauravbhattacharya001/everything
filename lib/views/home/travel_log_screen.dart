import 'package:flutter/material.dart';
import '../../models/travel_entry.dart';
import '../../core/services/travel_log_service.dart';

/// Travel Log screen — 4-tab UI for logging and reviewing trips.
class TravelLogScreen extends StatefulWidget {
  const TravelLogScreen({super.key});
  @override
  State<TravelLogScreen> createState() => _TravelLogScreenState();
}

class _TravelLogScreenState extends State<TravelLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = const TravelLogService();
  final List<TravelEntry> _entries = [];
  int? _filterYear;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addEntry(TravelEntry entry) {
    setState(() => _entries.add(entry));
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✈️ Travel Log'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.add_location_alt), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'Trips'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(onAdd: _addEntry),
          _TripsTab(
            entries: _entries,
            service: _service,
            filterYear: _filterYear,
            onYearChanged: (y) => setState(() => _filterYear = y),
            onDelete: _deleteEntry,
          ),
          _StatsTab(entries: _entries, service: _service),
          _InsightsTab(entries: _entries, service: _service),
        ],
      ),
    );
  }
}

// ─── Log Tab ───────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final void Function(TravelEntry) onAdd;
  const _LogTab({required this.onAdd});
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  final _destController = TextEditingController();
  final _countryController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _highlightController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  TripType _type = TripType.leisure;
  TripTransport _transport = TripTransport.flight;
  TripRating? _rating;
  final List<String> _highlights = [];
  int _nextId = 1;

  void _addHighlight() {
    final text = _highlightController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _highlights.add(text);
        _highlightController.clear();
      });
    }
  }

  void _submit() {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    final entry = TravelEntry(
      id: 'trip_${_nextId++}',
      destination: dest,
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      type: _type,
      transport: _transport,
      rating: _rating,
      totalCost: double.tryParse(_costController.text),
      highlights: List.from(_highlights),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    widget.onAdd(entry);
    _destController.clear();
    _countryController.clear();
    _costController.clear();
    _notesController.clear();
    _highlightController.clear();
    setState(() {
      _highlights.clear();
      _rating = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trip to $dest logged! ✈️')),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _destController.dispose();
    _countryController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Destination
        TextField(
          controller: _destController,
          decoration: const InputDecoration(
            labelText: 'Destination *',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Country
        TextField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            prefixIcon: Icon(Icons.flag),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // Date row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('→'),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Trip type chips
        const Text('Trip Type',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: TripType.values.map((t) {
            return ChoiceChip(
              label: Text('${t.emoji} ${t.label}'),
              selected: _type == t,
              onSelected: (_) => setState(() => _type = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Transport chips
        const Text('Transport',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: TripTransport.values.map((t) {
            return ChoiceChip(
              label: Text('${t.emoji} ${t.label}'),
              selected: _transport == t,
              onSelected: (_) => setState(() => _transport = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Rating chips
        const Text('Rating',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: TripRating.values.map((r) {
            return ChoiceChip(
              label: Text('${r.emoji} ${r.label}'),
              selected: _rating == r,
              onSelected: (_) => setState(() => _rating = r),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Cost
        TextField(
          controller: _costController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Cost (\$)',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // Highlights
        const Text('Highlights',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _highlightController,
                decoration: const InputDecoration(
                  hintText: 'Add a highlight...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addHighlight(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addHighlight,
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
        if (_highlights.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _highlights.asMap().entries.map((e) {
              return Chip(
                label: Text(e.value),
                onDeleted: () =>
                    setState(() => _highlights.removeAt(e.key)),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        // Notes
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes',
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        // Submit
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.flight_takeoff),
          label: const Text('Log Trip'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

// ─── Trips Tab ─────────────────────────────────────────────────────────

class _TripsTab extends StatelessWidget {
  final List<TravelEntry> entries;
  final TravelLogService service;
  final int? filterYear;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<String> onDelete;

  const _TripsTab({
    required this.entries,
    required this.service,
    required this.filterYear,
    required this.onYearChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✈️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No trips logged yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Start by adding your first trip!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final years = service.getYears(entries);
    final filtered = filterYear != null
        ? service.getByYear(entries, filterYear!)
        : List<TravelEntry>.from(entries)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Column(
      children: [
        // Year filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filterYear == null,
                  onSelected: (_) => onYearChanged(null),
                ),
                const SizedBox(width: 8),
                ...years.map((y) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$y'),
                        selected: filterYear == y,
                        onSelected: (_) => onYearChanged(y),
                      ),
                    )),
              ],
            ),
          ),
        ),
        // Trip list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final e = filtered[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Text(e.type.emoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(e.destination,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.startDate.month}/${e.startDate.day} – ${e.endDate.month}/${e.endDate.day}/${e.endDate.year}  •  ${e.durationDays}d',
                      ),
                      if (e.country != null) Text('🏳️ ${e.country}'),
                      if (e.rating != null)
                        Text('${e.rating!.emoji} ${e.rating!.label}'),
                      if (e.totalCost != null)
                        Text('💰 \$${e.totalCost!.toStringAsFixed(0)}'),
                      if (e.highlights.isNotEmpty)
                        Text('✨ ${e.highlights.join(", ")}',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDelete(e.id),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Stats Tab ─────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final List<TravelEntry> entries;
  final TravelLogService service;
  const _StatsTab({required this.entries, required this.service});

  @override
  Widget build(BuildContext context) {
    final stats = service.computeStats(entries);
    if (stats.totalTrips == 0) {
      return const Center(
        child: Text('Log some trips to see stats!',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final monthlyCosts = service.getMonthlyCosts(entries);
    final maxCost = monthlyCosts.isEmpty
        ? 1.0
        : monthlyCosts.map((m) => m.total).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            _StatCard('🌍', 'Trips', '${stats.totalTrips}'),
            const SizedBox(width: 12),
            _StatCard('📅', 'Days', '${stats.totalDays}'),
            const SizedBox(width: 12),
            _StatCard('🗺️', 'Countries', '${stats.countriesVisited}'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard('💰', 'Total Spent',
                '\$${stats.totalSpent.toStringAsFixed(0)}'),
            const SizedBox(width: 12),
            _StatCard('⭐', 'Avg Rating',
                stats.avgRating > 0
                    ? stats.avgRating.toStringAsFixed(1)
                    : '—'),
            const SizedBox(width: 12),
            _StatCard('🏆', 'Longest',
                '${stats.longestTripDays}d'),
          ],
        ),
        const SizedBox(height: 24),
        // Trip type breakdown
        const Text('By Trip Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...stats.typeBreakdown.entries.map((e) {
          final pct = e.value / stats.totalTrips;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text('${e.key.emoji} ${e.key.label}')),
                Expanded(
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}'),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        // Transport breakdown
        const Text('By Transport',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...stats.transportBreakdown.entries.map((e) {
          final pct = e.value / stats.totalTrips;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text('${e.key.emoji} ${e.key.label}')),
                Expanded(
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}'),
              ],
            ),
          );
        }),
        if (monthlyCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Monthly Spending',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...monthlyCosts.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(m.label)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: m.total / maxCost,
                      minHeight: 14,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('\$${m.total.toStringAsFixed(0)}'),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _StatCard(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Insights Tab ──────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final List<TravelEntry> entries;
  final TravelLogService service;
  const _InsightsTab({required this.entries, required this.service});

  @override
  Widget build(BuildContext context) {
    final insights = service.generateInsights(entries);
    final upcoming = service.getUpcoming(entries);

    if (insights.isEmpty && upcoming.isEmpty) {
      return const Center(
        child: Text('Log some trips to see insights!',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          const Text('🗓️ Upcoming Trips',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...upcoming.map((e) => Card(
                child: ListTile(
                  leading: Text(e.type.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(e.destination),
                  subtitle: Text(
                    '${e.startDate.month}/${e.startDate.day}/${e.startDate.year} • ${e.durationDays} days',
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
        if (insights.isNotEmpty) ...[
          const Text('📊 Travel Insights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...insights.map((i) => Card(
                child: ListTile(
                  leading: Text(i.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(i.title),
                  subtitle: Text(i.value),
                ),
              )),
        ],
      ],
    );
  }
}
