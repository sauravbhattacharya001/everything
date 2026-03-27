import 'package:flutter/material.dart';
import '../../core/services/color_blindness_service.dart';

/// Screen that simulates how colors appear to people with color vision deficiency.
/// Users can pick a color, enter hex codes, or browse a test palette and see
/// side-by-side simulations for all types of color blindness.
class ColorBlindnessScreen extends StatefulWidget {
  const ColorBlindnessScreen({super.key});

  @override
  State<ColorBlindnessScreen> createState() => _ColorBlindnessScreenState();
}

class _ColorBlindnessScreenState extends State<ColorBlindnessScreen> {
  Color _selectedColor = const Color(0xFFFF0000);
  final _hexController = TextEditingController(text: '#FF0000');
  double _hue = 0;
  double _saturation = 1;
  double _value = 1;

  @override
  void initState() {
    super.initState();
    _updateHSVFromColor();
  }

  void _updateHSVFromColor() {
    final hsv = HSVColor.fromColor(_selectedColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _setColor(Color c) {
    setState(() {
      _selectedColor = c;
      _hexController.text = ColorBlindnessService.toHex(c);
      _updateHSVFromColor();
    });
  }

  void _onHexSubmitted(String text) {
    final c = ColorBlindnessService.parseHex(text);
    if (c != null) _setColor(c);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Color Blindness Simulator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Color Picker Section ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pick a Color', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  // Hex input
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _hexController,
                          decoration: const InputDecoration(
                            labelText: 'Hex Code',
                            hintText: '#FF0000',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: _onHexSubmitted,
                          onEditingComplete: () =>
                              _onHexSubmitted(_hexController.text),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // HSV sliders
                  _buildSlider('Hue', _hue, 0, 360, (v) {
                    setState(() {
                      _hue = v;
                      _selectedColor =
                          HSVColor.fromAHSV(1, _hue, _saturation, _value)
                              .toColor();
                      _hexController.text =
                          ColorBlindnessService.toHex(_selectedColor);
                    });
                  }),
                  _buildSlider('Saturation', _saturation, 0, 1, (v) {
                    setState(() {
                      _saturation = v;
                      _selectedColor =
                          HSVColor.fromAHSV(1, _hue, _saturation, _value)
                              .toColor();
                      _hexController.text =
                          ColorBlindnessService.toHex(_selectedColor);
                    });
                  }),
                  _buildSlider('Brightness', _value, 0, 1, (v) {
                    setState(() {
                      _value = v;
                      _selectedColor =
                          HSVColor.fromAHSV(1, _hue, _saturation, _value)
                              .toColor();
                      _hexController.text =
                          ColorBlindnessService.toHex(_selectedColor);
                    });
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- Test Palette ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Palette', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ColorBlindnessService.testPalette.map((c) {
                      final selected = c.value == _selectedColor.value;
                      return GestureDetector(
                        onTap: () => _setColor(c),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- Simulation Results ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Simulated Vision',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'How this color appears to people with different types of color vision deficiency.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  // Normal vision first
                  _buildSimRow(
                      'Normal Vision', '', _selectedColor, theme),
                  const Divider(),
                  ...ColorBlindnessType.values.map((type) {
                    final sim = ColorBlindnessService.simulate(
                        _selectedColor, type);
                    return Column(
                      children: [
                        _buildSimRow(type.label, type.description, sim, theme),
                        if (type != ColorBlindnessType.values.last)
                          const Divider(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- Full Palette Comparison ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Palette Comparison',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'See how the full test palette looks under each vision type.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _buildPaletteRow('Normal', null, theme),
                  ...ColorBlindnessType.values
                      .map((t) => _buildPaletteRow(t.label, t, theme)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
      String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 44,
          child: Text(
            max > 1 ? value.toStringAsFixed(0) : value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSimRow(
      String label, String desc, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (desc.isNotEmpty)
                  Text(desc,
                      style:
                          theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                Text(ColorBlindnessService.toHex(color),
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteRow(
      String label, ColorBlindnessType? type, ThemeData theme) {
    final colors = ColorBlindnessService.testPalette.map((c) {
      return type == null ? c : ColorBlindnessService.simulate(c, type);
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: colors.map((c) => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.dividerColor, width: 0.5),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
