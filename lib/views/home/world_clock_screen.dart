import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/world_clock_service.dart';
import '../../models/world_clock_entry.dart';

/// Screen displaying saved time zones as live-updating clock cards.
///
/// Users can add zones from a curated preset list, reorder via drag,
/// and remove zones with a swipe.
class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  final _service = WorldClockService.instance;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    if (!mounted) return;
    setState(() => _loading = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Clock'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add time zone',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _service.clocks.isEmpty
              ? _buildEmpty()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemCount: _service.clocks.length,
                  onReorder: (oldIdx, newIdx) async {
                    await _service.reorder(oldIdx, newIdx);
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final entry = _service.clocks[index];
                    return _ClockCard(
                      key: ValueKey(entry.id),
                      entry: entry,
                      onRemove: () async {
                        await _service.removeClock(entry.id);
                        setState(() {});
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No time zones added',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Tap + to add a city', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final existing = _service.clocks.map((c) => c.id).toSet();
    final available = WorldClockService.presets.where((p) => !existing.contains(p.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All preset time zones already added')),
      );
      return;
    }

    final query = ValueNotifier<String>('');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Time Zone'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search cities…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => query.value = v.toLowerCase(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: query,
                  builder: (_, q, __) {
                    final filtered = q.isEmpty
                        ? available
                        : available.where((e) =>
                            e.label.toLowerCase().contains(q) ||
                            e.timeZoneName.toLowerCase().contains(q)).toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final preset = filtered[i];
                        return ListTile(
                          leading: Text(preset.emoji ?? '🌍', style: const TextStyle(fontSize: 24)),
                          title: Text(preset.label),
                          subtitle: Text('${preset.timeZoneName}  •  ${WorldClockService.formatOffset(preset.utcOffset)}'),
                          onTap: () async {
                            await _service.addClock(preset);
                            Navigator.of(ctx).pop();
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Individual clock card ──

class _ClockCard extends StatelessWidget {
  final WorldClockEntry entry;
  final VoidCallback onRemove;

  const _ClockCard({super.key, required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = WorldClockService.nowIn(entry.utcOffset);
    final hour = now.hour;
    final minute = now.minute;
    final second = now.second;
    final timeStr = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')}';
    final dateStr = _formatDate(now);
    final period = hour >= 6 && hour < 18;
    final diffStr = WorldClockService.timeDiffFromLocal(entry.utcOffset);

    return Dismissible(
      key: ValueKey('dismiss_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Emoji + day/night indicator
              Column(
                children: [
                  Text(entry.emoji ?? '🌍', style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Icon(
                    period ? Icons.wb_sunny : Icons.nightlight_round,
                    size: 16,
                    color: period ? Colors.orange : Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // City info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.timeZoneName}  •  ${WorldClockService.formatOffset(entry.utcOffset)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      diffStr,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.drag_handle, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  static final _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _formatDate(DateTime dt) {
    return '${_weekdays[dt.weekday - 1]}, ${_months[dt.month - 1]} ${dt.day}';
  }
}
