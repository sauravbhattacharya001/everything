import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/subnet_calculator_service.dart';

/// IPv4 Subnet Calculator with CIDR input, subnet details,
/// network subdivision, and copy-to-clipboard.
class SubnetCalculatorScreen extends StatefulWidget {
  const SubnetCalculatorScreen({super.key});

  @override
  State<SubnetCalculatorScreen> createState() => _SubnetCalculatorScreenState();
}

class _SubnetCalculatorScreenState extends State<SubnetCalculatorScreen> {
  final _ipController = TextEditingController(text: '192.168.1.0');
  int _prefix = 24;
  SubnetResult? _result;
  List<SubnetResult> _subnets = [];
  bool _showSubnets = false;
  int _subdivideCount = 4;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _calculate() {
    final r = SubnetCalculatorService.calculate(_ipController.text, _prefix);
    setState(() {
      _result = r;
      _subnets = [];
      _showSubnets = false;
    });
  }

  void _doSubdivide() {
    final subs = SubnetCalculatorService.subdivide(
      _ipController.text,
      _prefix,
      _subdivideCount,
    );
    setState(() {
      _subnets = subs;
      _showSubnets = true;
    });
  }

  void _copyResult() {
    if (_result == null) return;
    final r = _result!;
    final text = '''
IP Address:      ${r.ipAddress}
Network:         ${r.networkAddress}/${r.prefix}
Broadcast:       ${r.broadcastAddress}
Subnet Mask:     ${r.subnetMask}
Wildcard Mask:   ${r.wildcardMask}
Host Range:      ${r.firstHost} – ${r.lastHost}
Usable Hosts:    ${r.usableHosts}
Total Addresses: ${r.totalAddresses}
IP Class:        ${r.ipClass}
Private:         ${r.isPrivate ? 'Yes' : 'No'}
Binary Mask:     ${r.binaryMask}
''';
    Clipboard.setData(ClipboardData(text: text.trim()));
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
      appBar: AppBar(title: const Text('Subnet Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // IP input
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'IPv4 Address',
              hintText: '192.168.1.0',
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),

          // CIDR slider
          Text('CIDR Prefix: /$_prefix', style: theme.textTheme.titleSmall),
          Slider(
            value: _prefix.toDouble(),
            min: 0,
            max: 32,
            divisions: 32,
            label: '/$_prefix',
            onChanged: (v) {
              _prefix = v.round();
              _calculate();
            },
          ),

          // Quick prefix chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [8, 16, 24, 25, 26, 27, 28, 30, 32].map((p) {
              return ActionChip(
                label: Text('/$p', style: const TextStyle(fontSize: 12)),
                backgroundColor:
                    _prefix == p ? theme.colorScheme.primaryContainer : null,
                onPressed: () {
                  _prefix = p;
                  _calculate();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Results
          if (_result != null) ...[
            _buildResultCard(_result!),
            const SizedBox(height: 16),

            // Subdivide section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subdivide Network',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Split into '),
                        DropdownButton<int>(
                          value: _subdivideCount,
                          items: [2, 4, 8, 16, 32, 64]
                              .map((n) => DropdownMenuItem(
                                  value: n, child: Text('$n')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _subdivideCount = v);
                            }
                          },
                        ),
                        const Text(' subnets'),
                        const Spacer(),
                        FilledButton.tonal(
                          onPressed: _doSubdivide,
                          child: const Text('Split'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Subnet list
            if (_showSubnets && _subnets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${_subnets.length} Subnets',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._subnets.asMap().entries.map((e) => _buildSubnetTile(e.key, e.value)),
            ],
            if (_showSubnets && _subnets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Cannot subdivide further with this prefix.'),
              ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Enter a valid IPv4 address',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SubnetResult r) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Icon(Icons.hub, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${r.networkAddress}/${r.prefix}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (r.isPrivate)
                Chip(
                  label: const Text('Private',
                      style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              const SizedBox(width: 4),
              Chip(
                label: Text('Class ${r.ipClass}',
                    style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const Divider(height: 20),
          _infoRow('Network', r.networkAddress),
          _infoRow('Broadcast', r.broadcastAddress),
          _infoRow('Subnet Mask', r.subnetMask),
          _infoRow('Wildcard', r.wildcardMask),
          _infoRow('Host Range', '${r.firstHost} – ${r.lastHost}'),
          _infoRow('Usable Hosts', '${r.usableHosts}'),
          _infoRow('Total Addresses', '${r.totalAddresses}'),
          const SizedBox(height: 8),
          // Binary mask
          Text('Binary Mask', style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            r.binaryMask,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _copyResult,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubnetTile(int index, SubnetResult r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
        ),
        title: Text('${r.networkAddress}/${r.prefix}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Text('${r.firstHost} – ${r.lastHost}  (${r.usableHosts} hosts)',
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
