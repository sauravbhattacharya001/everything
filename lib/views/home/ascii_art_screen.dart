import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/ascii_art_service.dart';

/// A screen that converts text into ASCII art banners with multiple font styles.
class AsciiArtScreen extends StatefulWidget {
  const AsciiArtScreen({super.key});

  @override
  State<AsciiArtScreen> createState() => _AsciiArtScreenState();
}

class _AsciiArtScreenState extends State<AsciiArtScreen> {
  final _controller = TextEditingController(text: 'HELLO');
  String _selectedFont = 'Standard';
  String _output = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _output = '');
      return;
    }
    setState(() {
      _output = AsciiArtService.generate(text, font: _selectedFont);
    });
  }

  void _copy() {
    if (_output.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASCII Art Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: _output.isEmpty ? null : _copy,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input field
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter text',
                hintText: 'Type something...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
              ),
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _generate(),
            ),
            const SizedBox(height: 16),

            // Font selector
            Text('Font Style', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AsciiArtService.fontNames.map((font) {
                return ChoiceChip(
                  label: Text(font),
                  selected: _selectedFont == font,
                  onSelected: (_) {
                    setState(() => _selectedFont = font);
                    _generate();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Output display
            if (_output.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Output', style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Tips card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Tips', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Works best with short words or phrases'),
                    const Text('• Supports letters A-Z, numbers 0-9, and common punctuation'),
                    const Text('• Copy output for READMEs, comments, or messages'),
                    const Text('• Try each font style for different vibes!'),
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
