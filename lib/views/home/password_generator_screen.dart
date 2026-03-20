import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/password_generator_service.dart';

/// A password generator with configurable length, character sets,
/// passphrase mode, strength indicator, and copy-to-clipboard.
class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  PasswordConfig _config = const PasswordConfig();
  PasswordResult? _result;
  bool _passphraseMode = false;
  int _wordCount = 4;
  String _separator = '-';
  bool _capitalize = true;
  final List<PasswordResult> _history = [];

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      if (_passphraseMode) {
        _result = PasswordGeneratorService.generatePassphrase(
          wordCount: _wordCount,
          separator: _separator,
          capitalize: _capitalize,
        );
      } else {
        _result = PasswordGeneratorService.generate(_config);
      }
      _history.insert(0, _result!);
      if (_history.length > 20) _history.removeLast();
    });
  }

  void _copy() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!.password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _strengthColor(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.amber;
      case PasswordStrength.strong:
        return Colors.lightGreen;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  double _strengthValue(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return 0.2;
      case PasswordStrength.fair:
        return 0.4;
      case PasswordStrength.good:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Generated password display
          if (_result != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SelectableText(
                      _result!.password,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _strengthValue(_result!.strength),
                            backgroundColor: Colors.grey.shade300,
                            color: _strengthColor(_result!.strength),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _result!.strengthLabel,
                          style: TextStyle(
                            color: _strengthColor(_result!.strength),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_result!.entropy.toStringAsFixed(1)} bits of entropy',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Mode toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Password')),
              ButtonSegment(value: true, label: Text('Passphrase')),
            ],
            selected: {_passphraseMode},
            onSelectionChanged: (v) {
              setState(() => _passphraseMode = v.first);
              _generate();
            },
          ),
          const SizedBox(height: 16),

          if (!_passphraseMode) ...[
            // Length slider
            Text(
              'Length: ${_config.length}',
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: _config.length.toDouble(),
              min: 4,
              max: 64,
              divisions: 60,
              label: _config.length.toString(),
              onChanged: (v) {
                setState(
                  () => _config = _config.copyWith(length: v.round()),
                );
                _generate();
              },
            ),
            const SizedBox(height: 8),

            // Character toggles
            SwitchListTile(
              title: const Text('Uppercase (A-Z)'),
              value: _config.uppercase,
              onChanged: (v) {
                setState(() => _config = _config.copyWith(uppercase: v));
                _generate();
              },
            ),
            SwitchListTile(
              title: const Text('Lowercase (a-z)'),
              value: _config.lowercase,
              onChanged: (v) {
                setState(() => _config = _config.copyWith(lowercase: v));
                _generate();
              },
            ),
            SwitchListTile(
              title: const Text('Digits (0-9)'),
              value: _config.digits,
              onChanged: (v) {
                setState(() => _config = _config.copyWith(digits: v));
                _generate();
              },
            ),
            SwitchListTile(
              title: const Text('Symbols (!@#\$...)'),
              value: _config.symbols,
              onChanged: (v) {
                setState(() => _config = _config.copyWith(symbols: v));
                _generate();
              },
            ),
            SwitchListTile(
              title: const Text('Exclude ambiguous (I, l, 1, O, 0)'),
              value: _config.excludeAmbiguous,
              onChanged: (v) {
                setState(
                  () => _config = _config.copyWith(excludeAmbiguous: v),
                );
                _generate();
              },
            ),
          ] else ...[
            // Passphrase options
            Text(
              'Words: $_wordCount',
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: _wordCount.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: _wordCount.toString(),
              onChanged: (v) {
                setState(() => _wordCount = v.round());
                _generate();
              },
            ),
            const SizedBox(height: 8),
            Text('Separator', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['-', '.', '_', ' ', '/'].map((s) {
                final selected = _separator == s;
                return ChoiceChip(
                  label: Text(s == ' ' ? 'space' : s),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _separator = s);
                    _generate();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Capitalize words'),
              value: _capitalize,
              onChanged: (v) {
                setState(() => _capitalize = v);
                _generate();
              },
            ),
          ],

          const SizedBox(height: 20),

          // History
          if (_history.length > 1) ...[
            Text('Recent Passwords', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._history.skip(1).take(10).map(
                  (r) => ListTile(
                    dense: true,
                    title: Text(
                      r.password,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${r.strengthLabel} · ${r.entropy.toStringAsFixed(0)} bits',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: r.password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
