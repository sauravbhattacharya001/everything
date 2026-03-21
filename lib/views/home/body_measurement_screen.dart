import 'package:flutter/material.dart';
import '../../core/services/body_measurement_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/body_measurement_entry.dart';

/// Screen for tracking body measurements over time.
class BodyMeasurementScreen extends StatefulWidget {
  const BodyMeasurementScreen({super.key});

  @override
  State<BodyMeasurementScreen> createState() => _BodyMeasurementScreenState();
}

class _BodyMeasurementScreenState extends State<BodyMeasurementScreen>
    with PersistentStateMixin {
  final _service = BodyMeasurementService();

  @override
  String get storageKey => 'body_measurement_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  @override
  void initState() {
    super.initState();
    initPersistence();
  }

  // ── Helpers ──

  static const _fields = <String, String>{
    'weightKg': 'Weight (kg)',
    'heightCm': 'Height (cm)',
    'waistCm': 'Waist (cm)',
    'chestCm': 'Chest (cm)',
    'hipsCm': 'Hips (cm)',
    'bicepCm': 'Bicep (cm)',
    'thighCm': 'Thigh (cm)',
    'neckCm': 'Neck (cm)',
    'bodyFatPercent': 'Body Fat %',
  };

  double? _fieldValue(BodyMeasurementEntry e, String key) {
    switch (key) {
      case 'weightKg':
        return e.weightKg;
      case 'heightCm':
        return e.heightCm;
      case 'waistCm':
        return e.waistCm;
      case 'chestCm':
        return e.chestCm;
      case 'hipsCm':
        return e.hipsCm;
      case 'bicepCm':
        return e.bicepCm;
      case 'thighCm':
        return e.thighCm;
      case 'neckCm':
        return e.neckCm;
      case 'bodyFatPercent':
        return e.bodyFatPercent;
      default:
        return null;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Add / Edit Dialog ──

  Future<void> _showEntryDialog([BodyMeasurementEntry? existing]) async {
    final controllers = <String, TextEditingController>{};
    for (final key in _fields.keys) {
      final val = existing != null ? _fieldValue(existing, key) : null;
      controllers[key] =
          TextEditingController(text: val != null ? val.toString() : '');
    }
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
    var date = existing?.date ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'New Measurement' : 'Edit Measurement'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_formatDate(date)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => date = picked);
                      }
                    },
                  ),
                  ..._fields.entries.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: controllers[f.key],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: f.value,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result == true) {
      double? parse(String key) {
        final t = controllers[key]!.text.trim();
        return t.isEmpty ? null : double.tryParse(t);
      }

      final entry = BodyMeasurementEntry(
        id: existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        weightKg: parse('weightKg'),
        heightCm: parse('heightCm'),
        waistCm: parse('waistCm'),
        chestCm: parse('chestCm'),
        hipsCm: parse('hipsCm'),
        bicepCm: parse('bicepCm'),
        thighCm: parse('thighCm'),
        neckCm: parse('neckCm'),
        bodyFatPercent: parse('bodyFatPercent'),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );

      setState(() {
        if (existing == null) {
          _service.add(entry);
        } else {
          _service.update(entry);
        }
      });
      saveData();
    }

    for (final c in controllers.values) {
      c.dispose();
    }
    notesCtrl.dispose();
  }

  void _delete(String id) {
    setState(() => _service.delete(id));
    saveData();
  }

  // ── Build ──

  Widget _buildChangeIndicator(double? change) {
    if (change == null) return const SizedBox.shrink();
    final isPositive = change > 0;
    final color = isPositive ? Colors.red : Colors.green;
    final arrow = isPositive ? '▲' : '▼';
    return Text(
      '$arrow ${change.abs().toStringAsFixed(1)}',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _service.entries;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Body Measurements')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(),
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.straighten, size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No measurements yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap + to record your first measurement',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final e = entries[i];
                final prev = _service.previousBefore(e);
                // Build subtitle chips for non-null fields
                final chips = <Widget>[];
                for (final f in _fields.entries) {
                  final val = _fieldValue(e, f.key);
                  if (val == null) continue;
                  double? change;
                  if (prev != null) {
                    final prevVal = _fieldValue(prev, f.key);
                    if (prevVal != null) change = val - prevVal;
                  }
                  chips.add(Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${f.value}: ',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        Text(val.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12)),
                        if (change != null) ...[
                          const SizedBox(width: 4),
                          _buildChangeIndicator(change),
                        ],
                      ],
                    ),
                  ));
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showEntryDialog(e),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.straighten,
                                  size: 20,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(_formatDate(e.date),
                                  style: theme.textTheme.titleSmall),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                onPressed: () => _delete(e.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(children: chips),
                          if (e.notes != null && e.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(e.notes!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
