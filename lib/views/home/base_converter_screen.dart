import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/base_converter_service.dart';

/// A number base converter supporting binary, octal, decimal, hex,
/// and arbitrary bases 2–36 with live conversion and formatted output.
class BaseConverterScreen extends StatefulWidget {
  const BaseConverterScreen({super.key});

  @override
  State<BaseConverterScreen> createState() => _BaseConverterScreenState();
}

class _BaseConverterScreenState extends State<BaseConverterScreen> {
  final _inputController = TextEditingController();
  int _fromBase = 10;
  Map<String, String>? _results;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _results = null;
        _error = null;
      });
      return;
    }
    if (!BaseConverterService.isValid(input, _fromBase)) {
      setState(() {
        _results = null;
        _error =
            'Invalid input for base $_fromBase. Valid characters: ${BaseConverterService.validChars(_fromBase)}';
      });
      return;
    }
    setState(() {
      _results = BaseConverterService.convertToAll(input, _fromBase);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Base Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input field
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              labelText: 'Enter number',
              hintText: _fromBase == 16
                  ? 'e.g. 1A3F'
                  : _fromBase == 2
                      ? 'e.g. 10110'
                      : 'e.g. 255',
              border: const OutlineInputBorder(),
              suffixIcon: _inputController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _inputController.clear();
                        _convert();
                      },
                    )
                  : null,
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => _convert(),
          ),
          const SizedBox(height: 16),

          // From-base selector
          Text('Input Base', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BaseConverterService.namedBases.entries.map((e) {
              final selected = _fromBase == e.value;
              return ChoiceChip(
                label: Text(e.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : null,
                    )),
                selected: selected,
                selectedColor: theme.colorScheme.primary,
                onSelected: (_) {
                  setState(() => _fromBase = e.value);
                  _convert();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Valid characters hint
          Text(
            'Valid: ${BaseConverterService.validChars(_fromBase)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style:
                        TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            ),
          ],

          if (_results != null) ...[
            const Divider(height: 32),
            Text('Converted Values', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._results!.entries.map((e) => _resultCard(theme, e.key, e.value)),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(ThemeData theme, String label, String value) {
    // Format binary and hex for readability
    String displayValue = value;
    if (label.contains('Binary')) {
      displayValue = BaseConverterService.formatBinary(value);
    } else if (label.contains('Hex')) {
      displayValue = BaseConverterService.formatHex(value);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: theme.textTheme.bodySmall),
        subtitle: SelectableText(
          displayValue,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copy',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }
}
