import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/color_mixer_service.dart';

/// A color mixer screen where users can add colors, adjust weights,
/// and see the mixed result in real-time with different blend modes.
class ColorMixerScreen extends StatefulWidget {
  const ColorMixerScreen({super.key});

  @override
  State<ColorMixerScreen> createState() => _ColorMixerScreenState();
}

class _ColorMixerScreenState extends State<ColorMixerScreen> {
  final _service = ColorMixerService();
  MixMode _mode = MixMode.average;
  final List<MixerColor> _colors = [
    MixerColor(color: Colors.red, weight: 1.0, name: 'Red'),
    MixerColor(color: Colors.blue, weight: 1.0, name: 'Blue'),
  ];

  static const _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.white,
    Colors.black,
  ];

  Color get _mixedColor => _service.mix(_colors, _mode);

  void _addColor() {
    if (_colors.length >= 8) return;
    // Pick a color not already in the list, or default to green
    final used = _colors.map((c) => c.color.value).toSet();
    final next = _presetColors.firstWhere(
      (c) => !used.contains(c.value),
      orElse: () => Colors.green,
    );
    setState(() {
      _colors.add(MixerColor(
        color: next,
        weight: 1.0,
        name: _service.suggestName(next),
      ));
    });
  }

  void _removeColor(int index) {
    if (_colors.length <= 2) return;
    setState(() => _colors.removeAt(index));
  }

  void _updateWeight(int index, double weight) {
    setState(() {
      _colors[index] = _colors[index].copyWith(weight: weight);
    });
  }

  void _pickColor(int index) {
    showDialog(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        initialColor: _colors[index].color,
        presets: _presetColors,
        onPick: (color) {
          setState(() {
            _colors[index] = _colors[index].copyWith(
              color: color,
              name: _service.suggestName(color),
            );
          });
        },
      ),
    );
  }

  void _copyHex() {
    final hex = _service.toHex(_mixedColor);
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $hex'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mixed = _mixedColor;
    final isDark = mixed.computeLuminance() < 0.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Mixer'),
        actions: [
          PopupMenuButton<MixMode>(
            icon: const Icon(Icons.tune),
            tooltip: 'Blend mode',
            onSelected: (mode) => setState(() => _mode = mode),
            itemBuilder: (_) => MixMode.values
                .map((m) => PopupMenuItem(
                      value: m,
                      child: ListTile(
                        title: Text(m.label),
                        subtitle: Text(m.description, style: theme.textTheme.bodySmall),
                        trailing: _mode == m ? const Icon(Icons.check) : null,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Result preview
          GestureDetector(
            onTap: _copyHex,
            child: Container(
              width: double.infinity,
              height: 160,
              color: mixed,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _service.suggestName(mixed),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _service.toHex(mixed),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _service.toRgb(mixed),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black38,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _service.toHsl(mixed),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black38,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.copy, size: 16,
                        color: isDark ? Colors.white38 : Colors.black26),
                  ],
                ),
              ),
            ),
          ),
          // Mode indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.blender, size: 16),
                const SizedBox(width: 8),
                Text(_mode.label, style: theme.textTheme.labelLarge),
                const Spacer(),
                Text('${_colors.length}/8 colors',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          // Color list
          Expanded(
            child: ListView.builder(
              itemCount: _colors.length,
              padding: const EdgeInsets.only(bottom: 80),
              itemBuilder: (context, index) {
                final mc = _colors[index];
                final colorIsDark = mc.color.computeLuminance() < 0.5;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Color swatch + label
                        InkWell(
                          onTap: () => _pickColor(index),
                          child: Container(
                            height: 48,
                            color: mc.color,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Text(
                                  mc.name ?? 'Color ${index + 1}',
                                  style: TextStyle(
                                    color: colorIsDark
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _service.toHex(mc.color),
                                  style: TextStyle(
                                    color: colorIsDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                                if (_colors.length > 2)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: InkWell(
                                      onTap: () => _removeColor(index),
                                      child: Icon(Icons.close,
                                          size: 18,
                                          color: colorIsDark
                                              ? Colors.white70
                                              : Colors.black54),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Weight slider
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Text('Weight', style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  value: mc.weight,
                                  min: 0,
                                  max: 3,
                                  divisions: 30,
                                  label: mc.weight.toStringAsFixed(1),
                                  onChanged: (v) => _updateWeight(index, v),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  mc.weight.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _colors.length < 8
          ? FloatingActionButton(
              onPressed: _addColor,
              tooltip: 'Add color',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Simple color picker dialog with preset grid and custom hex input.
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final List<Color> presets;
  final ValueChanged<Color> onPick;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.presets,
    required this.onPick,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selected;
  final _hexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
    _hexController.text = _toHex(widget.initialColor);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _toHex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}'
      '${c.green.toRadixString(16).padLeft(2, '0')}'
      '${c.blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  void _parseHex() {
    var text = _hexController.text.trim().replaceFirst('#', '');
    if (text.length == 3) {
      text = text.split('').map((c) => '$c$c').join();
    }
    if (text.length == 6) {
      final value = int.tryParse(text, radix: 16);
      if (value != null) {
        setState(() => _selected = Color(0xFF000000 | value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a Color'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _selected,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 12),
            // Hex input
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                labelText: 'Hex',
                hintText: '#FF0000',
                isDense: true,
              ),
              onChanged: (_) => _parseHex(),
            ),
            const SizedBox(height: 12),
            // Preset grid
            SizedBox(
              height: 160,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: widget.presets.length,
                itemBuilder: (_, i) {
                  final c = widget.presets[i];
                  final isSelected = c.value == _selected.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = c;
                        _hexController.text = _toHex(c);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              size: 16,
                              color: c.computeLuminance() < 0.5
                                  ? Colors.white
                                  : Colors.black)
                          : null,
                    ),
                  );
                },
              ),
            ),
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
            widget.onPick(_selected);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
