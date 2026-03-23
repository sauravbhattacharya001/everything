import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/ambient_sound_service.dart';

/// Ambient Sound Mixer — combine multiple ambient sounds at individual
/// volumes to create a personalised atmosphere for focus, sleep, or
/// relaxation.
///
/// Features:
/// - 20+ built-in sounds across Nature, Urban, Noise, and Mechanical categories
/// - Per-sound volume sliders with quick toggle
/// - Save / load custom mix presets
/// - Optional sleep timer
/// - Master volume control
class AmbientSoundScreen extends StatefulWidget {
  const AmbientSoundScreen({super.key});

  @override
  State<AmbientSoundScreen> createState() => _AmbientSoundScreenState();
}

class _AmbientSoundScreenState extends State<AmbientSoundScreen> {
  final _service = AmbientSoundService();
  double _masterVolume = 0.8;
  Timer? _timerCheck;

  @override
  void dispose() {
    _timerCheck?.cancel();
    super.dispose();
  }

  void _startTimerCheck() {
    _timerCheck?.cancel();
    _timerCheck = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_service.hasTimer && _service.timerEnd!.isBefore(DateTime.now())) {
        setState(() {
          _service.stopAll();
          _service.clearTimer();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sleep timer ended — all sounds stopped')),
        );
        _timerCheck?.cancel();
      }
    });
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final options = [15, 30, 45, 60, 90, 120];
        return SimpleDialog(
          title: const Text('Sleep Timer'),
          children: [
            if (_service.hasTimer)
              SimpleDialogOption(
                onPressed: () {
                  setState(() => _service.clearTimer());
                  _timerCheck?.cancel();
                  Navigator.pop(ctx);
                },
                child: const ListTile(
                  leading: Icon(Icons.timer_off, color: Colors.red),
                  title: Text('Cancel Timer'),
                ),
              ),
            ...options.map((min) => SimpleDialogOption(
                  onPressed: () {
                    setState(() => _service.setTimer(Duration(minutes: min)));
                    _startTimerCheck();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sounds will stop in $min minutes')),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(Icons.timer),
                    title: Text('$min minutes'),
                  ),
                )),
          ],
        );
      },
    );
  }

  void _showSavePresetDialog() {
    if (_service.activeSounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activate at least one sound first')),
      );
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Preset name',
            hintText: 'e.g. Rainy Café',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _service.savePreset(name));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPresetsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final presets = _service.presets;
        if (presets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No saved presets yet')),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: presets.length,
          itemBuilder: (_, i) {
            final p = presets[i];
            return ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(p.name),
              subtitle: Text('${p.volumes.length} sounds'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => _service.deletePreset(i));
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                setState(() => _service.loadPreset(p));
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _service.categories;
    final activeCount = _service.activeSounds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambient Sounds'),
        actions: [
          if (activeCount > 0)
            IconButton(
              icon: Icon(_service.hasTimer ? Icons.timer : Icons.timer_outlined),
              tooltip: 'Sleep Timer',
              onPressed: _showTimerDialog,
            ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Save Preset',
            onPressed: _showSavePresetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Load Preset',
            onPressed: _showPresetsSheet,
          ),
          if (activeCount > 0)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Stop All',
              onPressed: () => setState(() => _service.stopAll()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Master volume + active indicator
          if (activeCount > 0)
            Container(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.volume_up, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Master', style: theme.textTheme.labelLarge),
                  Expanded(
                    child: Slider(
                      value: _masterVolume,
                      onChanged: (v) => setState(() => _masterVolume = v),
                    ),
                  ),
                  Text(
                    '${(100 * _masterVolume).round()}%',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          if (_service.hasTimer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Timer: stops at ${TimeOfDay.fromDateTime(_service.timerEnd!).format(context)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          // Sound grid by category
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: categories.length,
              itemBuilder: (context, catIdx) {
                final cat = categories[catIdx];
                final sounds = _service.soundsInCategory(cat);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        cat,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: sounds.length,
                      itemBuilder: (context, i) =>
                          _SoundTile(
                            sound: sounds[i],
                            masterVolume: _masterVolume,
                            onToggle: () => setState(
                                () => _service.toggleSound(sounds[i].id)),
                            onVolumeChanged: (v) => setState(
                                () => _service.setVolume(sounds[i].id, v)),
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  final AmbientSound sound;
  final double masterVolume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  const _SoundTile({
    required this.sound,
    required this.masterVolume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = sound.active;
    final effectiveVolume = sound.volume * masterVolume;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sound.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              sound.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 16,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor:
                        theme.colorScheme.primary.withOpacity(0.2),
                    thumbColor: theme.colorScheme.primary,
                  ),
                  child: Slider(
                    value: sound.volume,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              Text(
                '${(100 * effectiveVolume).round()}%',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
