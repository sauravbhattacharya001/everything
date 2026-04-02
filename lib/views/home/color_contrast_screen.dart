import 'package:flutter/material.dart';
import '../../core/services/color_contrast_service.dart';

/// WCAG Color Contrast Checker — pick foreground and background colors,
/// see the contrast ratio and WCAG AA/AAA pass/fail status.
class ColorContrastScreen extends StatefulWidget {
  const ColorContrastScreen({super.key});

  @override
  State<ColorContrastScreen> createState() => _ColorContrastScreenState();
}

class _ColorContrastScreenState extends State<ColorContrastScreen> {
  final _service = ColorContrastService();
  final _fgController = TextEditingController(text: '#333333');
  final _bgController = TextEditingController(text: '#FFFFFF');

  Color _fgColor = const Color(0xFF333333);
  Color _bgColor = const Color(0xFFFFFFFF);
  ContrastResult? _result;
  List<int>? _suggestion;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _fgController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _calculate() {
    final fg = _service.parseHex(_fgController.text);
    final bg = _service.parseHex(_bgController.text);
    if (fg == null || bg == null) {
      setState(() {
        _result = null;
        _suggestion = null;
      });
      return;
    }
    setState(() {
      _fgColor = Color.fromARGB(255, fg[0], fg[1], fg[2]);
      _bgColor = Color.fromARGB(255, bg[0], bg[1], bg[2]);
      _result = _service.check(fg[0], fg[1], fg[2], bg[0], bg[1], bg[2]);
      if (_result != null && !_result!.passesAA) {
        _suggestion = _service.suggestAccessibleColor(
            fg[0], fg[1], fg[2], bg[0], bg[1], bg[2]);
      } else {
        _suggestion = null;
      }
    });
  }

  void _swap() {
    final tmp = _fgController.text;
    _fgController.text = _bgController.text;
    _bgController.text = tmp;
    _calculate();
  }

  void _pickPreset(String fg, String bg) {
    _fgController.text = fg;
    _bgController.text = bg;
    _calculate();
  }

  Widget _badge(String label, bool passes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: passes ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: passes ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passes ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: passes ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: passes ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color Contrast Checker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                'Sample Text Preview',
                style: TextStyle(
                  color: _fgColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fgController,
                    decoration: InputDecoration(
                      labelText: 'Foreground',
                      prefixIcon: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _fgColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Swap colors',
                  onPressed: _swap,
                ),
                Expanded(
                  child: TextField(
                    controller: _bgController,
                    decoration: InputDecoration(
                      labelText: 'Background',
                      prefixIcon: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ratio display
            if (_result != null) ...[
              Center(
                child: Text(
                  '${_result!.ratio.toStringAsFixed(2)} : 1',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _result!.passesAA
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // WCAG badges
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _badge('AA Normal', _result!.passesAA),
                  _badge('AA Large', _result!.passesAALarge),
                  _badge('AAA Normal', _result!.passesAAA),
                  _badge('AAA Large', _result!.passesAAALarge),
                ],
              ),
              const SizedBox(height: 12),

              // Explanation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('WCAG 2.1 Requirements',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('• AA Normal text: 4.5:1 minimum'),
                      Text('• AA Large text (18pt+): 3.0:1 minimum'),
                      Text('• AAA Normal text: 7.0:1 minimum'),
                      Text('• AAA Large text (18pt+): 4.5:1 minimum'),
                    ],
                  ),
                ),
              ),

              // Suggestion
              if (_suggestion != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(
                                255, _suggestion![0], _suggestion![1], _suggestion![2]),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Suggested foreground: #${_suggestion![0].toRadixString(16).padLeft(2, '0')}${_suggestion![1].toRadixString(16).padLeft(2, '0')}${_suggestion![2].toRadixString(16).padLeft(2, '0').toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _fgController.text =
                                '#${_suggestion![0].toRadixString(16).padLeft(2, '0')}${_suggestion![1].toRadixString(16).padLeft(2, '0')}${_suggestion![2].toRadixString(16).padLeft(2, '0')}';
                            _calculate();
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Enter valid hex colors (e.g. #FF5500)',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),

            const SizedBox(height: 20),

            // Presets
            const Text('Quick Presets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetChip('Dark on White', '#333333', '#FFFFFF'),
                _presetChip('White on Blue', '#FFFFFF', '#0055CC'),
                _presetChip('Red on White', '#CC0000', '#FFFFFF'),
                _presetChip('Gray on White', '#767676', '#FFFFFF'),
                _presetChip('Green on Black', '#00CC66', '#000000'),
                _presetChip('Yellow on White', '#FFCC00', '#FFFFFF'),
                _presetChip('Navy on Cream', '#003366', '#FFFDD0'),
                _presetChip('Purple on Gray', '#6B21A8', '#E5E7EB'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String fg, String bg) {
    return ActionChip(
      label: Text(label),
      avatar: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse('FF${fg.replaceFirst('#', '')}', radix: 16)),
              Color(int.parse('FF${bg.replaceFirst('#', '')}', radix: 16)),
            ],
          ),
          shape: BoxShape.circle,
        ),
      ),
      onPressed: () => _pickPreset(fg, bg),
    );
  }
}
