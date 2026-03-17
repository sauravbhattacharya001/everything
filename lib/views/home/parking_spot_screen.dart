import 'dart:async';
import 'package:flutter/material.dart';

/// A saved parking spot with location details and optional meter timer.
class ParkingSpot {
  final String id;
  String locationName;
  String level;
  String spotNumber;
  String notes;
  DateTime savedAt;
  DateTime? meterExpiry;

  ParkingSpot({
    required this.id,
    required this.locationName,
    this.level = '',
    this.spotNumber = '',
    this.notes = '',
    required this.savedAt,
    this.meterExpiry,
  });

  bool get hasMeter => meterExpiry != null;

  bool get isMeterExpired =>
      hasMeter && meterExpiry!.isBefore(DateTime.now());

  Duration get timeRemaining {
    if (!hasMeter) return Duration.zero;
    final remaining = meterExpiry!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Parking Spot Saver — save where you parked with level, spot number,
/// notes, and an optional meter countdown timer.
///
/// Features:
/// - Save current parking with location, level, spot, and notes
/// - Optional meter timer with countdown and expiry warning
/// - History of past parking spots
/// - Quick "I found my car" to clear active spot
class ParkingSpotScreen extends StatefulWidget {
  const ParkingSpotScreen({super.key});

  @override
  State<ParkingSpotScreen> createState() => _ParkingSpotScreenState();
}

class _ParkingSpotScreenState extends State<ParkingSpotScreen> {
  ParkingSpot? _activeSpot;
  final List<ParkingSpot> _history = [];
  Timer? _timer;
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activeSpot?.hasMeter == true) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _nextId() => 'parking_${++_idCounter}';

  void _saveSpot() {
    showDialog(
      context: context,
      builder: (ctx) => _SaveSpotDialog(
        onSave: (name, level, spot, notes, meterMinutes) {
          setState(() {
            if (_activeSpot != null) {
              _history.insert(0, _activeSpot!);
            }
            _activeSpot = ParkingSpot(
              id: _nextId(),
              locationName: name,
              level: level,
              spotNumber: spot,
              notes: notes,
              savedAt: DateTime.now(),
              meterExpiry: meterMinutes > 0
                  ? DateTime.now().add(Duration(minutes: meterMinutes))
                  : null,
            );
          });
        },
      ),
    );
  }

  void _foundCar() {
    if (_activeSpot == null) return;
    setState(() {
      _history.insert(0, _activeSpot!);
      _activeSpot = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Great, you found your car!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addMeterTime() {
    if (_activeSpot == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _AddTimeDialog(
        onAdd: (minutes) {
          setState(() {
            final base = _activeSpot!.isMeterExpired
                ? DateTime.now()
                : (_activeSpot!.meterExpiry ?? DateTime.now());
            _activeSpot!.meterExpiry = base.add(Duration(minutes: minutes));
          });
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m $ampm';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Spot'),
        elevation: 0,
        actions: [
          if (_activeSpot != null)
            TextButton.icon(
              onPressed: _foundCar,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Found Car',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSpot,
        icon: const Icon(Icons.local_parking),
        label: Text(_activeSpot == null ? 'Save Spot' : 'New Spot'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_activeSpot != null) ...[
            _buildActiveSpotCard(),
            const SizedBox(height: 24),
          ] else ...[
            _buildEmptyState(),
            const SizedBox(height: 24),
          ],
          if (_history.isNotEmpty) ...[
            Text(
              'History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._history.map(_buildHistoryTile),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.local_parking, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No active parking spot',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Save Spot" to remember where you parked',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSpotCard() {
    final spot = _activeSpot!;
    final meterExpired = spot.isMeterExpired;
    final meterColor = !spot.hasMeter
        ? Colors.blue
        : meterExpired
            ? Colors.red
            : (spot.timeRemaining.inMinutes < 10
                ? Colors.orange
                : Colors.green);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: meterColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    spot.locationName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Level & Spot
            if (spot.level.isNotEmpty || spot.spotNumber.isNotEmpty)
              Row(
                children: [
                  if (spot.level.isNotEmpty)
                    _infoChip(Icons.layers, 'Level ${spot.level}'),
                  if (spot.level.isNotEmpty && spot.spotNumber.isNotEmpty)
                    const SizedBox(width: 8),
                  if (spot.spotNumber.isNotEmpty)
                    _infoChip(Icons.tag, 'Spot ${spot.spotNumber}'),
                ],
              ),

            if (spot.level.isNotEmpty || spot.spotNumber.isNotEmpty)
              const SizedBox(height: 12),

            // Parked at time
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Parked at ${_formatTime(spot.savedAt)} · ${_timeSince(spot.savedAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            // Meter section
            if (spot.hasMeter) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    meterExpired ? Icons.warning : Icons.timer,
                    color: meterColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meterExpired ? 'METER EXPIRED' : 'Meter Time Left',
                          style: TextStyle(
                            color: meterColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          meterExpired
                              ? 'Expired at ${_formatTime(spot.meterExpiry!)}'
                              : _formatDuration(spot.timeRemaining),
                          style: TextStyle(
                            fontSize: meterExpired ? 16 : 24,
                            fontWeight: FontWeight.bold,
                            color: meterColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addMeterTime,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
            ],

            // Notes
            if (spot.notes.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(spot.notes,
                        style: TextStyle(color: Colors.grey[700])),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ParkingSpot spot) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_parking, color: Colors.grey),
        title: Text(spot.locationName),
        subtitle: Text(
          [
            if (spot.level.isNotEmpty) 'Level ${spot.level}',
            if (spot.spotNumber.isNotEmpty) 'Spot ${spot.spotNumber}',
            '${_formatDate(spot.savedAt)} at ${_formatTime(spot.savedAt)}',
          ].join(' · '),
        ),
        trailing: Text(_timeSince(spot.savedAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ),
    );
  }
}

/// Dialog for saving a new parking spot.
class _SaveSpotDialog extends StatefulWidget {
  final void Function(
      String name, String level, String spot, String notes, int meterMinutes)
      onSave;

  const _SaveSpotDialog({required this.onSave});

  @override
  State<_SaveSpotDialog> createState() => _SaveSpotDialogState();
}

class _SaveSpotDialogState extends State<_SaveSpotDialog> {
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  final _spotController = TextEditingController();
  final _notesController = TextEditingController();
  bool _hasMeter = false;
  int _meterMinutes = 60;

  static const _presetMinutes = [15, 30, 60, 90, 120];

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _spotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Parking Spot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                hintText: 'e.g. Westfield Mall, Street on 5th Ave',
                prefixIcon: Icon(Icons.location_on),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _levelController,
                    decoration: const InputDecoration(
                      labelText: 'Level/Floor',
                      hintText: 'e.g. P2, B1',
                      prefixIcon: Icon(Icons.layers),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _spotController,
                    decoration: const InputDecoration(
                      labelText: 'Spot #',
                      hintText: 'e.g. A-42',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Near elevator, red pillar, etc.',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Parking Meter'),
              subtitle: const Text('Set a countdown timer'),
              value: _hasMeter,
              onChanged: (v) => setState(() => _hasMeter = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasMeter) ...[
              Wrap(
                spacing: 8,
                children: _presetMinutes.map((m) {
                  final selected = _meterMinutes == m;
                  return ChoiceChip(
                    label: Text(m < 60 ? '${m}m' : '${m ~/ 60}h${m % 60 > 0 ? ' ${m % 60}m' : ''}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _meterMinutes = m),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            widget.onSave(
              _nameController.text.trim(),
              _levelController.text.trim(),
              _spotController.text.trim(),
              _notesController.text.trim(),
              _hasMeter ? _meterMinutes : 0,
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog for adding time to an existing meter.
class _AddTimeDialog extends StatefulWidget {
  final void Function(int minutes) onAdd;

  const _AddTimeDialog({required this.onAdd});

  @override
  State<_AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends State<_AddTimeDialog> {
  int _minutes = 30;
  static const _options = [15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Meter Time'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _options.map((m) {
          final selected = _minutes == m;
          return ChoiceChip(
            label: Text(m < 60 ? '${m}m' : '${m ~/ 60}h${m % 60 > 0 ? ' ${m % 60}m' : ''}'),
            selected: selected,
            onSelected: (_) => setState(() => _minutes = m),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onAdd(_minutes);
            Navigator.pop(context);
          },
          child: Text('Add $_minutes min'),
        ),
      ],
    );
  }
}
