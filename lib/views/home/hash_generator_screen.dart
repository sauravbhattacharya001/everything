import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/hash_generator_service.dart';

/// Compute cryptographic hashes (MD5, SHA-1, SHA-256, etc.) of text input.
class HashGeneratorScreen extends StatefulWidget {
  const HashGeneratorScreen({super.key});

  @override
  State<HashGeneratorScreen> createState() => _HashGeneratorScreenState();
}

class _HashGeneratorScreenState extends State<HashGeneratorScreen> {
  final _inputController = TextEditingController();
  String _selectedAlgorithm = 'SHA-256';
  bool _showAll = false;
  String _singleHash = '';
  Map<String, String> _allHashes = {};

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _compute() {
    final text = _inputController.text;
    if (text.isEmpty) {
      setState(() {
        _singleHash = '';
        _allHashes = {};
      });
      return;
    }
    setState(() {
      _singleHash =
          HashGeneratorService.computeHash(text, _selectedAlgorithm);
      if (_showAll) {
        _allHashes = HashGeneratorService.computeAll(text);
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hash Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Input text',
              hintText: 'Enter text to hash…',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (_) => _compute(),
          ),
          const SizedBox(height: 16),

          // Algorithm selector row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAlgorithm,
                  decoration: const InputDecoration(
                    labelText: 'Algorithm',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: HashGeneratorService.algorithms
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedAlgorithm = v);
                      _compute();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Show all'),
                selected: _showAll,
                onSelected: (v) {
                  setState(() => _showAll = v);
                  _compute();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Single result
          if (_singleHash.isNotEmpty && !_showAll) ...[
            Text(_selectedAlgorithm,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _HashResultTile(
              hash: _singleHash,
              onCopy: () => _copyToClipboard(_singleHash),
            ),
          ],

          // All results
          if (_showAll && _allHashes.isNotEmpty)
            ..._allHashes.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _HashResultTile(
                        hash: e.value,
                        onCopy: () => _copyToClipboard(e.value),
                      ),
                    ],
                  ),
                )),

          if (_inputController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'Type something above to compute its hash',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HashResultTile extends StatelessWidget {
  const _HashResultTile({required this.hash, required this.onCopy});
  final String hash;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              hash,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopy,
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
