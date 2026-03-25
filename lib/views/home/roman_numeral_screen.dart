import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/roman_numeral_service.dart';

/// Converts between decimal numbers and Roman numerals with live
/// bidirectional conversion and a handy reference table.
class RomanNumeralScreen extends StatefulWidget {
  const RomanNumeralScreen({super.key});

  @override
  State<RomanNumeralScreen> createState() => _RomanNumeralScreenState();
}

class _RomanNumeralScreenState extends State<RomanNumeralScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _decimalController = TextEditingController();
  final _romanController = TextEditingController();

  String? _romanResult;
  String? _decimalResult;
  String? _decimalError;
  String? _romanError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _decimalController.dispose();
    _romanController.dispose();
    super.dispose();
  }

  void _convertToRoman() {
    final text = _decimalController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _romanResult = null;
        _decimalError = null;
      });
      return;
    }
    final num = int.tryParse(text);
    if (num == null || num < 1 || num > 3999) {
      setState(() {
        _romanResult = null;
        _decimalError = 'Enter a number between 1 and 3999';
      });
      return;
    }
    setState(() {
      _romanResult = RomanNumeralService.toRoman(num);
      _decimalError = null;
    });
  }

  void _convertToDecimal() {
    final text = _romanController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _decimalResult = null;
        _romanError = null;
      });
      return;
    }
    final result = RomanNumeralService.toDecimal(text);
    if (result == null) {
      setState(() {
        _decimalResult = null;
        _romanError = 'Not a valid Roman numeral';
      });
      return;
    }
    setState(() {
      _decimalResult = result.toString();
      _romanError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roman Numerals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'To Roman'),
            Tab(text: 'To Decimal'),
            Tab(text: 'Reference'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildToRomanTab(theme),
          _buildToDecimalTab(theme),
          _buildReferenceTab(theme),
        ],
      ),
    );
  }

  Widget _buildToRomanTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _decimalController,
          decoration: InputDecoration(
            labelText: 'Decimal number',
            hintText: 'e.g. 2024',
            border: const OutlineInputBorder(),
            errorText: _decimalError,
            suffixIcon: _decimalController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _decimalController.clear();
                      _convertToRoman();
                    },
                  )
                : null,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _convertToRoman(),
        ),
        const SizedBox(height: 24),
        if (_romanResult != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _romanResult!,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_decimalController.text.trim()} in Roman numerals',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _romanResult!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToDecimalTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _romanController,
          decoration: InputDecoration(
            labelText: 'Roman numeral',
            hintText: 'e.g. MMXXIV',
            border: const OutlineInputBorder(),
            errorText: _romanError,
            suffixIcon: _romanController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _romanController.clear();
                      _convertToDecimal();
                    },
                  )
                : null,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => _convertToDecimal(),
        ),
        const SizedBox(height: 24),
        if (_decimalResult != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _decimalResult!,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_romanController.text.trim().toUpperCase()} in decimal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _decimalResult!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReferenceTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Roman Numeral Reference',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...RomanNumeralService.referenceTable.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    e.value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '= ${e.key}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rules', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                const Text('• Symbols are added left to right (largest first)'),
                const Text('• A smaller symbol before a larger one means subtraction'),
                const Text('• Range: 1 (I) to 3999 (MMMCMXCIX)'),
                const Text('• No symbol repeats more than 3 times in a row'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
