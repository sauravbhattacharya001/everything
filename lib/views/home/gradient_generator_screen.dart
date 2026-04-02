import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/gradient_generator_service.dart';

/// Interactive gradient generator with live preview, color stops,
/// angle control, presets, and CSS/Flutter code export.
class GradientGeneratorScreen extends StatefulWidget {
  const GradientGeneratorScreen({super.key});

  @override
  State<GradientGeneratorScreen> createState() =>
      _GradientGeneratorScreenState();
}

class _GradientGeneratorScreenState extends State<GradientGeneratorScreen> {
  List<ColorStop> _stops = [
    ColorStop(color: const Color(0xFF2193B0), position: 0.0),
    ColorStop(color: const Color(0xFF6DD5ED), position: 1.0),
  ];
  GradientType _type = GradientType.linear;
  double _angleDeg = 90;
  int _selectedStopIndex = 0;
  bool _showCss = true;
  final List<List<ColorStop>> _history = [];

  Gradient get _gradient => GradientGeneratorService.buildGradient(
        stops: _stops,
        type: _type,
        angleDeg: _angleDeg,
      );

  String get _code => _showCss
      ? GradientGeneratorService.toCss(
          stops: _stops, type: _type, angleDeg: _angleDeg)
      : GradientGeneratorService.toFlutter(
          stops: _stops, type: _type, angleDeg: _angleDeg);

  void _saveHistory() {
    _history.add(_stops.map((s) => s.copyWith()).toList());
    if (_history.length > 20) _history.removeAt(0);
  }

  void _addStop() {
    _saveHistory();
    setState(() {
      _stops.add(ColorStop(
        color: Colors.white,
        position: 0.5,
      ));
      _selectedStopIndex = _stops.length - 1;
    });
  }

  void _removeStop(int index) {
    if (_stops.length <= 2) return;
    _saveHistory();
    setState(() {
      _stops.removeAt(index);
      if (_selectedStopIndex >= _stops.length) {
        _selectedStopIndex = _stops.length - 1;
      }
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _stops = _history.removeLast();
      if (_selectedStopIndex >= _stops.length) {
        _selectedStopIndex = _stops.length - 1;
      }
    });
  }

  void _randomize() {
    _saveHistory();
    setState(() {
      _stops = GradientGeneratorService.randomStops(count: _stops.length);
    });
  }

  void _applyPreset(GradientPreset preset) {
    _saveHistory();
    setState(() {
      _stops = preset.stops.map((s) => s.copyWith()).toList();
      _angleDeg = preset.angleDeg;
      _selectedStopIndex = 0;
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_showCss ? "CSS" : "Flutter"} code copied!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickColor(int index) async {
    final currentColor = _stops[index].color;
    Color picked = currentColor;

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(initialColor: currentColor),
    );
    if (result != null) {
      _saveHistory();
      setState(() => _stops[index].color = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gradient Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _history.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _randomize,
            tooltip: 'Randomize',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: _gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Gradient type selector
            Row(
              children: GradientType.values.map((t) {
                final selected = t == _type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 4),
                          Text(t.label),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Angle slider (only for linear)
            if (_type == GradientType.linear) ...[
              Row(
                children: [
                  const Icon(Icons.rotate_right, size: 18),
                  const SizedBox(width: 8),
                  Text('Angle: ${_angleDeg.toStringAsFixed(0)}°'),
                  Expanded(
                    child: Slider(
                      value: _angleDeg,
                      min: 0,
                      max: 360,
                      onChanged: (v) => setState(() => _angleDeg = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Color stops
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Color Stops',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: _addStop,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_stops.length, (i) {
                      final stop = _stops[i];
                      final selected = i == _selectedStopIndex;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: selected
                              ? Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2)
                              : Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          onTap: () =>
                              setState(() => _selectedStopIndex = i),
                          leading: GestureDetector(
                            onTap: () => _pickColor(i),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: stop.color,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                          title: Text(stop.hexString,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 13)),
                          subtitle: Row(
                            children: [
                              const Text('Position: ',
                                  style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  value: stop.position,
                                  min: 0,
                                  max: 1,
                                  onChanged: (v) {
                                    setState(() => stop.position = v);
                                  },
                                ),
                              ),
                              Text(
                                  '${(stop.position * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: _stops.length > 2
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20),
                                  onPressed: () => _removeStop(i),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Presets
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Presets',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: GradientPreset.all.map((p) {
                        final gradient =
                            GradientGeneratorService.buildGradient(
                          stops: p.stops,
                          type: GradientType.linear,
                          angleDeg: p.angleDeg,
                        );
                        return GestureDetector(
                          onTap: () => _applyPreset(p),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(p.name,
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Code output
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Code',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('CSS'),
                              selected: _showCss,
                              onSelected: (_) =>
                                  setState(() => _showCss = true),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Flutter'),
                              selected: !_showCss,
                              onSelected: (_) =>
                                  setState(() => _showCss = false),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple HSV color picker dialog.
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _color =>
      HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          _sliderRow('H', _hue, 0, 360, (v) => setState(() => _hue = v)),
          _sliderRow(
              'S', _saturation, 0, 1, (v) => setState(() => _saturation = v)),
          _sliderRow('V', _value, 0, 1, (v) => setState(() => _value = v)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _sliderRow(
      String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Slider(value: val, min: min, max: max, onChanged: onChanged)),
        SizedBox(
          width: 40,
          child: Text(
            max > 1 ? val.toStringAsFixed(0) : val.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
