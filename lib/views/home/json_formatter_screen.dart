import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/json_formatter_service.dart';

/// JSON Formatter & Validator — format, minify, validate JSON with
/// syntax error highlighting, stats, and an interactive tree view.
class JsonFormatterScreen extends StatefulWidget {
  const JsonFormatterScreen({super.key});

  @override
  State<JsonFormatterScreen> createState() => _JsonFormatterScreenState();
}

class _JsonFormatterScreenState extends State<JsonFormatterScreen>
    with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  late TabController _tabController;
  JsonFormatResult? _result;
  int _indent = 2;

  final _sampleJson = '''{
  "name": "BioBots",
  "version": "1.1.0",
  "features": ["bioprinting", "rheology", "gcode"],
  "config": {
    "temperature": 37.0,
    "pressure": 1.2,
    "nozzle": {"diameter": 0.4, "type": "conical"}
  },
  "active": true,
  "notes": null
}''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _process() {
    setState(() {
      _result = JsonFormatterService.process(
        _inputController.text,
        indent: _indent,
      );
    });
  }

  void _loadSample() {
    _inputController.text = _sampleJson;
    _process();
  }

  void _clear() {
    _inputController.clear();
    setState(() => _result = null);
  }

  void _copyFormatted() {
    if (_result?.formatted != null) {
      Clipboard.setData(ClipboardData(text: _result!.formatted!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formatted JSON copied!')),
      );
    }
  }

  void _copyMinified() {
    if (_result?.minified != null) {
      Clipboard.setData(ClipboardData(text: _result!.minified!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minified JSON copied!')),
      );
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _inputController.text = data!.text!;
      _process();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Formatter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: 'Paste from clipboard',
            onPressed: _pasteFromClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Load sample',
            onPressed: _loadSample,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear',
            onPressed: _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _inputController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste or type JSON here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => _process(),
            ),
          ),

          // Controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Validity indicator
                if (_result != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _result!.isValid
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _result!.isValid
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _result!.isValid ? Icons.check_circle : Icons.error,
                          size: 16,
                          color:
                              _result!.isValid ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _result!.isValid ? 'Valid' : 'Invalid',
                          style: TextStyle(
                            color:
                                _result!.isValid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Indent selector
                const Text('Indent: ', style: TextStyle(fontSize: 13)),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 4, label: Text('4')),
                  ],
                  selected: {_indent},
                  onSelectionChanged: (v) {
                    setState(() => _indent = v.first);
                    if (_inputController.text.isNotEmpty) _process();
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Format'),
                  onPressed: _result?.isValid == true ? _copyFormatted : null,
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.compress, size: 16),
                  label: const Text('Minify'),
                  onPressed: _result?.isValid == true ? _copyMinified : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Error message
          if (_result != null && !_result!.isValid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _result!.errorMessage ?? 'Unknown error',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Tabs for output
          if (_result?.isValid == true) ...[
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Formatted'),
                Tab(text: 'Tree View'),
                Tab(text: 'Stats'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormattedTab(),
                  _buildTreeTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
          ] else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildFormattedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        _result?.formatted ?? '',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  Widget _buildTreeTab() {
    if (_result?.tree.isEmpty ?? true) return const SizedBox();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _result!.tree
          .expand((node) => _buildTreeNodes(node))
          .toList(),
    );
  }

  List<Widget> _buildTreeNodes(JsonPathNode node) {
    final widgets = <Widget>[];
    final color = _typeColor(node.type);

    widgets.add(
      Padding(
        padding: EdgeInsets.only(left: node.depth * 20.0),
        child: Row(
          children: [
            if (node.children.isNotEmpty)
              Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600])
            else
              const SizedBox(width: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                node.type,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              node.key,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (node.valuePreview != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  node.valuePreview!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    for (final child in node.children) {
      widgets.addAll(_buildTreeNodes(child));
    }

    return widgets;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'object':
        return Colors.blue;
      case 'array':
        return Colors.purple;
      case 'string':
        return Colors.green;
      case 'number':
        return Colors.orange;
      case 'boolean':
        return Colors.teal;
      case 'null':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildStatsTab() {
    final stats = _result?.stats;
    if (stats == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statTile(Icons.vpn_key, 'Total Keys', stats.totalKeys.toString()),
        _statTile(Icons.data_object, 'Total Values', stats.totalValues.toString()),
        _statTile(Icons.layers, 'Max Depth', stats.maxDepth.toString()),
        const Divider(height: 24),
        _statTile(Icons.data_object, 'Objects', stats.objectCount.toString(),
            color: Colors.blue),
        _statTile(Icons.data_array, 'Arrays', stats.arrayCount.toString(),
            color: Colors.purple),
        _statTile(Icons.text_fields, 'Strings', stats.stringCount.toString(),
            color: Colors.green),
        _statTile(Icons.numbers, 'Numbers', stats.numberCount.toString(),
            color: Colors.orange),
        _statTile(Icons.toggle_on, 'Booleans', stats.boolCount.toString(),
            color: Colors.teal),
        _statTile(Icons.block, 'Nulls', stats.nullCount.toString(),
            color: Colors.grey),
        const Divider(height: 24),
        _statTile(
          Icons.straighten,
          'Formatted Size',
          '${_result!.formatted!.length} chars',
        ),
        _statTile(
          Icons.compress,
          'Minified Size',
          '${_result!.minified!.length} chars',
        ),
        if (_result!.formatted!.length > 0)
          _statTile(
            Icons.savings,
            'Compression',
            '${(100 - (_result!.minified!.length / _result!.formatted!.length * 100)).toStringAsFixed(1)}%',
          ),
      ],
    );
  }

  Widget _statTile(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
