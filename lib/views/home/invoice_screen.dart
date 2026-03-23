import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/invoice_service.dart';

/// A simple invoice generator with line items, tax, discount, and
/// copy-to-clipboard output.
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _invoiceNumberController = TextEditingController(text: 'INV-001');
  final _clientController = TextEditingController();
  final _taxController = TextEditingController(text: '10');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  final List<InvoiceLineItem> _items = [
    InvoiceLineItem(description: '', unitPrice: 0),
  ];

  // Controllers for each line item (kept in sync with _items list).
  final List<_LineControllers> _lineControllers = [];

  @override
  void initState() {
    super.initState();
    _lineControllers.add(_LineControllers());
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _clientController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    for (final lc in _lineControllers) {
      lc.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceLineItem(description: '', unitPrice: 0));
      _lineControllers.add(_LineControllers());
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index);
      _lineControllers[index].dispose();
      _lineControllers.removeAt(index);
    });
  }

  void _syncItem(int index) {
    final lc = _lineControllers[index];
    _items[index]
      ..description = lc.desc.text
      ..quantity = int.tryParse(lc.qty.text) ?? 1
      ..unitPrice = double.tryParse(lc.price.text) ?? 0;
    setState(() {});
  }

  double get _taxPercent => double.tryParse(_taxController.text) ?? 0;
  double get _discountPercent =>
      double.tryParse(_discountController.text) ?? 0;

  InvoiceResult get _totals => InvoiceService.calculate(
        items: _items,
        taxPercent: _taxPercent,
        discountPercent: _discountPercent,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _copyInvoice() {
    final text = InvoiceService.formatInvoice(
      invoiceNumber: _invoiceNumberController.text.trim(),
      clientName: _clientController.text.trim().isEmpty
          ? 'N/A'
          : _clientController.text.trim(),
      date: _date,
      items: _items.where((i) => i.description.isNotEmpty).toList(),
      totals: _totals,
      taxPercent: _taxPercent,
      discountPercent: _discountPercent,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _totals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy invoice to clipboard',
            onPressed: _copyInvoice,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header fields ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice #',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  '${_date.year}-${_pad(_date.month)}-${_pad(_date.day)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientController,
            decoration: const InputDecoration(
              labelText: 'Client Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Line items ──
          Text('Line Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final lc = _lineControllers[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: lc.desc,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Item ${i + 1}',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _syncItem(i),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: lc.qty,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _syncItem(i),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: lc.price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$ ',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _syncItem(i),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 60,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _fmt(_items[i].total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (_items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeItem(i),
                      padding: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ),
          const Divider(height: 32),

          // ── Tax & Discount ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tax %',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Discount %',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Notes ──
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Totals ──
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Subtotal', _fmt(totals.subtotal)),
                  if (_discountPercent > 0)
                    _row('Discount (${_discountPercent.toStringAsFixed(1)}%)',
                        '-${_fmt(totals.discountAmount)}'),
                  _row('Tax (${_taxPercent.toStringAsFixed(1)}%)',
                      _fmt(totals.taxAmount)),
                  const Divider(),
                  _row(
                    'Total',
                    _fmt(totals.grandTotal),
                    bold: true,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Copy button ──
          FilledButton.icon(
            onPressed: _copyInvoice,
            icon: const Icon(Icons.copy),
            label: const Text('Copy Invoice to Clipboard'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Controllers for a single line item row.
class _LineControllers {
  final TextEditingController desc = TextEditingController();
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController price = TextEditingController();

  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
  }
}
