/// Offline currency converter with common exchange rates.
///
/// Rates are bundled so the converter works without network access.
/// Users can update rates manually or use the provided defaults.
class CurrencyConverterService {
  CurrencyConverterService._();

  /// Built-in exchange rates relative to USD (approximate, March 2026).
  static final Map<String, CurrencyInfo> currencies = {
    'USD': CurrencyInfo('US Dollar', '\$', 1.0),
    'EUR': CurrencyInfo('Euro', '€', 0.92),
    'GBP': CurrencyInfo('British Pound', '£', 0.79),
    'JPY': CurrencyInfo('Japanese Yen', '¥', 149.50),
    'CAD': CurrencyInfo('Canadian Dollar', 'C\$', 1.36),
    'AUD': CurrencyInfo('Australian Dollar', 'A\$', 1.54),
    'CHF': CurrencyInfo('Swiss Franc', 'Fr', 0.88),
    'CNY': CurrencyInfo('Chinese Yuan', '¥', 7.24),
    'INR': CurrencyInfo('Indian Rupee', '₹', 83.50),
    'MXN': CurrencyInfo('Mexican Peso', '\$', 17.15),
    'BRL': CurrencyInfo('Brazilian Real', 'R\$', 4.97),
    'KRW': CurrencyInfo('South Korean Won', '₩', 1325.0),
    'SGD': CurrencyInfo('Singapore Dollar', 'S\$', 1.34),
    'HKD': CurrencyInfo('Hong Kong Dollar', 'HK\$', 7.82),
    'SEK': CurrencyInfo('Swedish Krona', 'kr', 10.45),
    'NOK': CurrencyInfo('Norwegian Krone', 'kr', 10.60),
    'NZD': CurrencyInfo('New Zealand Dollar', 'NZ\$', 1.63),
    'THB': CurrencyInfo('Thai Baht', '฿', 35.50),
    'TRY': CurrencyInfo('Turkish Lira', '₺', 30.25),
    'ZAR': CurrencyInfo('South African Rand', 'R', 18.75),
    'PLN': CurrencyInfo('Polish Zloty', 'zł', 4.02),
    'PHP': CurrencyInfo('Philippine Peso', '₱', 55.80),
    'TWD': CurrencyInfo('Taiwan Dollar', 'NT\$', 31.50),
    'AED': CurrencyInfo('UAE Dirham', 'د.إ', 3.67),
    'SAR': CurrencyInfo('Saudi Riyal', '﷼', 3.75),
  };

  /// Convert [amount] from [fromCode] to [toCode].
  static double convert(double amount, String fromCode, String toCode) {
    final fromRate = currencies[fromCode]?.rateToUsd ?? 1.0;
    final toRate = currencies[toCode]?.rateToUsd ?? 1.0;
    return amount / fromRate * toRate;
  }

  /// Format a converted value with currency symbol and 2 decimal places.
  static String format(double amount, String currencyCode) {
    final info = currencies[currencyCode];
    final symbol = info?.symbol ?? currencyCode;
    // For currencies with large values (JPY, KRW, etc.), skip decimals
    if (amount.abs() >= 100 && (currencyCode == 'JPY' || currencyCode == 'KRW')) {
      return '$symbol${amount.round()}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get sorted list of currency codes.
  static List<String> get codes => currencies.keys.toList()..sort();
}

/// Holds metadata for a single currency.
class CurrencyInfo {
  final String name;
  final String symbol;
  final double rateToUsd;

  const CurrencyInfo(this.name, this.symbol, this.rateToUsd);
}
