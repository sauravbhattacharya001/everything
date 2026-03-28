import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/cipher_tool_service.dart';

/// Encode and decode text with multiple ciphers: Caesar, ROT13,
/// Atbash, Base64, and Vigenère.
class CipherToolScreen extends StatefulWidget {
  const CipherToolScreen({super.key});

  @override
  State<CipherToolScreen> createState() => _CipherToolScreenState();
}

class _CipherToolScreenState extends State<CipherToolScreen> {
  final _inputController = TextEditingController();
  final _keyController = TextEditingController();
  final _shiftController = TextEditingController(text: '3');
  String _selectedCipher = 'Caesar';
  bool _encode = true;
  String _output = '';

  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  void _process() {
    final text = _inputController.text;
    if (text.isEmpty) {
      setState(() => _output = '');
      return;
    }

    String result;
    switch (_selectedCipher) {
      case 'Caesar':
        final shift = int.tryParse(_shiftController.text) ?? 3;
        result = _encode
            ? CipherToolService.caesarEncode(text, shift)
            : CipherToolService.caesarDecode(text, shift);
        break;
      case 'ROT13':
        result = CipherToolService.rot13(text);
        break;
      case 'Atbash':
        result = CipherToolService.atbash(text);
        break;
      case 'Base64':
        result = _encode
            ? CipherToolService.base64Encode(text)
            : CipherToolService.base64Decode(text);
        break;
      case 'Vigenère':
        final key = _keyController.text;
        if (key.isEmpty) {
          result = '[Enter a key]';
        } else {
          result = _encode
              ? CipherToolService.vigenereEncode(text, key)
              : CipherToolService.vigenereDecode(text, key);
        }
        break;
      default:
        result = text;
    }

    setState(() => _output = result);
  }

  bool get _needsShift => _selectedCipher == 'Caesar';
  bool get _needsKey => _selectedCipher == 'Vigenère';
  bool get _isSymmetric =>
      _selectedCipher == 'ROT13' || _selectedCipher == 'Atbash';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cipher Tool')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cipher selector
          DropdownButtonFormField<String>(
            value: _selectedCipher,
            decoration: const InputDecoration(
              labelText: 'Cipher',
              border: OutlineInputBorder(),
            ),
            items: CipherToolService.cipherNames
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedCipher = v!;
              _output = '';
            }),
          ),
          const SizedBox(height: 12),

          // Encode / Decode toggle (hidden for symmetric ciphers)
          if (!_isSymmetric)
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Encode'),
                  selected: _encode,
                  onSelected: (_) => setState(() => _encode = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Decode'),
                  selected: !_encode,
                  onSelected: (_) => setState(() => _encode = false),
                ),
              ],
            ),
          if (!_isSymmetric) const SizedBox(height: 12),

          // Shift input for Caesar
          if (_needsShift)
            TextField(
              controller: _shiftController,
              decoration: const InputDecoration(
                labelText: 'Shift (1-25)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          if (_needsShift) const SizedBox(height: 12),

          // Key input for Vigenère
          if (_needsKey)
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key (letters only)',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
            ),
          if (_needsKey) const SizedBox(height: 12),

          // Input text
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Input text',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),

          // Process button
          FilledButton.icon(
            onPressed: _process,
            icon: Icon(_isSymmetric
                ? Icons.swap_horiz
                : (_encode ? Icons.lock : Icons.lock_open)),
            label: Text(_isSymmetric
                ? 'Transform'
                : (_encode ? 'Encode' : 'Decode')),
          ),
          const SizedBox(height: 16),

          // Output
          if (_output.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Output',
                          style: theme.textTheme.titleSmall),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _output));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _output,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Cipher info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cipher Reference',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _infoTile('Caesar',
                      'Shifts each letter by N positions. Classic substitution cipher.'),
                  _infoTile('ROT13',
                      'Caesar with shift=13. Applying twice returns the original.'),
                  _infoTile('Atbash',
                      'Mirrors the alphabet: A↔Z, B↔Y, etc. Self-inverse.'),
                  _infoTile('Base64',
                      'Binary-to-text encoding. Not encryption — just encoding.'),
                  _infoTile('Vigenère',
                      'Polyalphabetic cipher using a keyword. Harder to break than Caesar.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(desc)),
        ],
      ),
    );
  }
}
