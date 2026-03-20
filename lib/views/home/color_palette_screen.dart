import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/color_palette_service.dart';

/// An interactive color palette generator with harmony rules,
/// hue slider, copy-to-clipboard, and favorites.
class ColorPaletteScreen extends StatefulWidget {
  const ColorPaletteScreen({super.key});

  @override
  State<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<ColorPaletteScreen> {
  double _baseHue = ColorPaletteService.randomHue();
  HarmonyType _harmony = HarmonyType.analogous;
  int _colorCount = 5;
  late List<Color> _colors;
  final List<ColorPalette> _saved = [];

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() {
      _colors = ColorPaletteService.generate(
        baseHue: _baseHue,
        harmony: _harmony,
        count: _colorCount,
      );
    });
  }

  void _randomize() {
    setState(() {
      _baseHue = ColorPaletteService.randomHue();
    });
    _regenerate();
  }

  void _savePalette() {
    final palette = ColorPalette(
      name: '${_harmony.label} #${_saved.length + 1}',
      harmony: _harmony,
      colors: List.of(_colors),
      created: DateTime.now(),
    );
    setState(() => _saved.insert(0, palette));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Palette saved!'), duration: Duration(seconds: 1)),
    );
  }

  void _copyAll() {
    final hex = _colors.map(ColorPaletteService.colorToHex).join(', ');
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $hex'), duration: const Duration(seconds: 1)),
    );
  }

  void _copyColor(Color c) {
    final hex = ColorPaletteService.colorToHex(c);
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $hex'), duration: const Duration(seconds: 1)),
    );
  }

  void _toggleFavorite(int index) {
    setState(() {
      _saved[index] = _saved[index].copyWith(isFavorite: !_saved[index].isFavorite);
    });
  }

  Color _textColorFor(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palette'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Randomize',
            onPressed: _randomize,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all hex codes',
            onPressed: _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save palette',
            onPressed: _savePalette,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Color swatches ──
          SizedBox(
            height: 120,
            child: Row(
              children: _colors.map((c) {
                final hex = ColorPaletteService.colorToHex(c);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _copyColor(c),
                    onLongPress: () => _showColorDetail(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: c,
                      child: Center(
                        child: Text(
                          hex,
                          style: TextStyle(
                            color: _textColorFor(c),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Hue slider ──
          Text('Base Hue: ${_baseHue.round()}°', style: theme.textTheme.titleSmall),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 12,
              activeTrackColor: HSLColor.fromAHSL(1, _baseHue, 0.7, 0.5).toColor(),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: HSLColor.fromAHSL(1, _baseHue, 0.8, 0.5).toColor(),
            ),
            child: Slider(
              value: _baseHue,
              min: 0,
              max: 360,
              onChanged: (v) {
                _baseHue = v;
                _regenerate();
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Harmony selector ──
          Text('Harmony', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HarmonyType.values.map((h) {
              final selected = h == _harmony;
              return ChoiceChip(
                label: Text(h.label),
                selected: selected,
                onSelected: (_) {
                  setState(() => _harmony = h);
                  _regenerate();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Color count ──
          Row(
            children: [
              Text('Colors: $_colorCount', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _colorCount > 2
                    ? () {
                        _colorCount--;
                        _regenerate();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _colorCount < 10
                    ? () {
                        _colorCount++;
                        _regenerate();
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Color details ──
          ...List.generate(_colors.length, (i) {
            final c = _colors[i];
            return ListTile(
              leading: CircleAvatar(backgroundColor: c),
              title: Text(ColorPaletteService.colorToHex(c)),
              subtitle: Text(
                '${ColorPaletteService.colorToRgb(c)}  •  ${ColorPaletteService.colorToHsl(c)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyColor(c),
              ),
            );
          }),

          // ── Saved palettes ──
          if (_saved.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Saved Palettes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._saved.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Row(
                        children: p.colors
                            .map((c) => Expanded(
                                  child: Container(color: c),
                                ))
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text(p.harmony.label,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              p.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: p.isFavorite ? Colors.red : null,
                              size: 20,
                            ),
                            onPressed: () => _toggleFavorite(idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () =>
                                setState(() => _saved.removeAt(idx)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showColorDetail(Color c) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('HEX', ColorPaletteService.colorToHex(c)),
            _detailRow('RGB', ColorPaletteService.colorToRgb(c)),
            _detailRow('HSL', ColorPaletteService.colorToHsl(c)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $value'), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }
}
