import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/morse_code_service.dart';

/// Morse Code Translator — encode text to Morse and decode Morse to text.
class MorseCodeScreen extends StatefulWidget {
  const MorseCodeScreen({super.key});

  @override
  State<MorseCodeScreen> createState() => _MorseCodeScreenState();
}

class _MorseCodeScreenState extends State<MorseCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _encodeController = TextEditingController();
  final _decodeController = TextEditingController();
  String _encodedResult = '';
  String _decodedResult = '';
  bool _showReference = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _encodeController.dispose();
    _decodeController.dispose();
    super.dispose();
  }

  void _encode() {
    setState(() {
      _encodedResult = MorseCodeService.encode(_encodeController.text);
    });
  }

  void _decode() {
    setState(() {
      _decodedResult = MorseCodeService.decode(_decodeController.text);
    });
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
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
      appBar: AppBar(
        title: const Text('Morse Code'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Encode', icon: Icon(Icons.arrow_forward)),
            Tab(text: 'Decode', icon: Icon(Icons.arrow_back)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showReference ? Icons.close : Icons.table_chart),
            tooltip: 'Reference Table',
            onPressed: () => setState(() => _showReference = !_showReference),
          ),
        ],
      ),
      body: _showReference ? _buildReference(theme) : _buildTabs(theme),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEncodeTab(theme),
        _buildDecodeTab(theme),
      ],
    );
  }

  Widget _buildEncodeTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _encodeController,
            decoration: const InputDecoration(
              labelText: 'Enter text',
              hintText: 'Hello World',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _encode(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Morse Code', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (_encodedResult.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(_encodedResult),
                  tooltip: 'Copy',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _encodedResult.isEmpty ? '...' : _encodedResult,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    letterSpacing: 2,
                    color: _encodedResult.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecodeTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _decodeController,
            decoration: const InputDecoration(
              labelText: 'Enter Morse code',
              hintText: '.... . .-.. .-.. --- / .-- --- .-. .-.. -..',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _decode(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Decoded Text', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (_decodedResult.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(_decodedResult),
                  tooltip: 'Copy',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _decodedResult.isEmpty ? '...' : _decodedResult,
                  style: TextStyle(
                    fontSize: 20,
                    color: _decodedResult.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReference(ThemeData theme) {
    final entries = MorseCodeService.referenceTable;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return Card(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(e.value,
                    style: const TextStyle(
                        fontFamily: 'monospace', letterSpacing: 2)),
              ],
            ),
          ),
        );
      },
    );
  }
}
