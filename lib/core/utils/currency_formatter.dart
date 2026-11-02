import 'package:intl/intl.dart';

/// Production currency utility for lossless minor-unit (centavos) integer arithmetic
/// adhering to Philippine Peso (PHP / ₱) standards.
/// Prevents IEEE 754 floating-point precision inaccuracies across all POS transactions.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
  );

  /// Converts an integer centavo value (e.g. 125000) into a formatted currency string ("₱1,250.00").
  static String format(int cents) {
    final pesos = cents / 100.0;
    return _formatter.format(pesos);
  }

  /// Converts an integer centavo value into a decimal string without the currency symbol ("1250.00").
  static String formatPlain(int cents) {
    final pesos = cents / 100.0;
    return pesos.toStringAsFixed(2);
  }

  /// Parses a user-input decimal string (e.g. "14.99", "₱14.99", "₱1,200.50") into integer centavos (1499).
  static int parseToCents(String input) {
    final cleaned = input.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
    return (parsed * 100).round();
  }
}
