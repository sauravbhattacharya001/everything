/// Service for creating and managing simple invoices.
class InvoiceService {
  InvoiceService._();

  /// Calculate invoice totals from line items.
  static InvoiceResult calculate({
    required List<InvoiceLineItem> items,
    required double taxPercent,
    double discountPercent = 0,
  }) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    final discountAmount = subtotal * (discountPercent / 100);
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * (taxPercent / 100);
    final grandTotal = afterDiscount + taxAmount;
    return InvoiceResult(
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
    );
  }

  /// Format an invoice as shareable plain text.
  static String formatInvoice({
    required String invoiceNumber,
    required String clientName,
    required DateTime date,
    required List<InvoiceLineItem> items,
    required InvoiceResult totals,
    required double taxPercent,
    double discountPercent = 0,
    String? notes,
  }) {
    final buf = StringBuffer();
    buf.writeln('INVOICE #$invoiceNumber');
    buf.writeln('Date: ${date.year}-${_pad(date.month)}-${_pad(date.day)}');
    buf.writeln('Client: $clientName');
    buf.writeln('${'─' * 40}');
    buf.writeln('${'Item'.padRight(20)} ${'Qty'.padLeft(4)} ${'Price'.padLeft(8)} ${'Total'.padLeft(8)}');
    buf.writeln('${'─' * 40}');
    for (final item in items) {
      buf.writeln(
        '${item.description.padRight(20).substring(0, 20)} '
        '${item.quantity.toString().padLeft(4)} '
        '${_money(item.unitPrice).padLeft(8)} '
        '${_money(item.total).padLeft(8)}',
      );
    }
    buf.writeln('${'─' * 40}');
    buf.writeln('${'Subtotal:'.padRight(34)} ${_money(totals.subtotal).padLeft(8)}');
    if (discountPercent > 0) {
      buf.writeln('${'Discount ($discountPercent%):'.padRight(34)} -${_money(totals.discountAmount).padLeft(7)}');
    }
    buf.writeln('${'Tax ($taxPercent%):'.padRight(34)} ${_money(totals.taxAmount).padLeft(8)}');
    buf.writeln('${'═' * 40}');
    buf.writeln('${'TOTAL:'.padRight(34)} ${_money(totals.grandTotal).padLeft(8)}');
    if (notes != null && notes.isNotEmpty) {
      buf.writeln('');
      buf.writeln('Notes: $notes');
    }
    return buf.toString();
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
  static String _money(double v) => '\$${v.toStringAsFixed(2)}';
}

/// A single line item on an invoice.
class InvoiceLineItem {
  String description;
  int quantity;
  double unitPrice;

  InvoiceLineItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItem(
        description: json['description'] as String,
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );
}

/// Computed totals for an invoice.
class InvoiceResult {
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;

  const InvoiceResult({
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.grandTotal,
  });
}
