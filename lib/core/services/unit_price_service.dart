/// Service for comparing unit prices across products.
class UnitPriceService {
  UnitPriceService._();

  /// Calculate price per unit for a product.
  static UnitPriceResult calculate({
    required double price,
    required double quantity,
    required String unit,
  }) {
    assert(quantity > 0);
    final pricePerUnit = price / quantity;
    return UnitPriceResult(
      price: price,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
    );
  }

  /// Compare multiple products and return them sorted by best value.
  static List<UnitPriceResult> compare(List<UnitPriceResult> items) {
    final sorted = List<UnitPriceResult>.from(items);
    sorted.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    return sorted;
  }

  /// Calculate savings between worst and best deal.
  static double savingsPercent(List<UnitPriceResult> items) {
    if (items.length < 2) return 0;
    final sorted = compare(items);
    final best = sorted.first.pricePerUnit;
    final worst = sorted.last.pricePerUnit;
    if (worst == 0) return 0;
    return ((worst - best) / worst) * 100;
  }

  /// Common unit types for quick selection.
  static const List<String> commonUnits = [
    'oz',
    'lb',
    'g',
    'kg',
    'ml',
    'L',
    'fl oz',
    'gal',
    'ct',
    'pack',
    'roll',
    'sheet',
    'sq ft',
  ];
}

class UnitPriceResult {
  final double price;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String? label;

  const UnitPriceResult({
    required this.price,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    this.label,
  });

  UnitPriceResult copyWith({String? label}) => UnitPriceResult(
        price: price,
        quantity: quantity,
        unit: unit,
        pricePerUnit: pricePerUnit,
        label: label ?? this.label,
      );
}
