import '../../features/checkout/domain/tax_rate.dart';

/// Calculation result encapsulating exact minor-unit tax breakdowns.
class TaxCalculationResult {
  final int netSubtotalCents;
  final int taxAmountCents;
  final int finalTotalCents;
  final TaxRate taxRate;

  const TaxCalculationResult({
    required this.netSubtotalCents,
    required this.taxAmountCents,
    required this.finalTotalCents,
    required this.taxRate,
  });
}

/// Robust retail tax engine supporting Inclusive VAT, Exclusive VAT, and Regional Sales Tax.
/// Ensures all intermediate and final figures are rounded cleanly to integer minor units (cents).
class TaxEngine {
  TaxEngine._();

  /// Computes tax breakdown from a given subtotal after discounts in cents.
  static TaxCalculationResult calculate({
    required int subtotalAfterDiscountCents,
    required TaxRate taxRate,
  }) {
    if (subtotalAfterDiscountCents <= 0 || taxRate.ratePercent <= 0) {
      return TaxCalculationResult(
        netSubtotalCents: subtotalAfterDiscountCents,
        taxAmountCents: 0,
        finalTotalCents: subtotalAfterDiscountCents,
        taxRate: taxRate,
      );
    }

    switch (taxRate.type) {
      case TaxType.inclusiveVat:
        // Price already incorporates VAT.
        // Base = Subtotal / (1 + Rate / 100)
        // Tax = Subtotal - Base
        final base = subtotalAfterDiscountCents / (1.0 + (taxRate.ratePercent / 100.0));
        final taxCents = (subtotalAfterDiscountCents - base).round();
        final netCents = subtotalAfterDiscountCents - taxCents;
        return TaxCalculationResult(
          netSubtotalCents: netCents,
          taxAmountCents: taxCents,
          finalTotalCents: subtotalAfterDiscountCents,
          taxRate: taxRate,
        );

      case TaxType.exclusiveVat:
      case TaxType.flatRegional:
        // Tax is added on top of the net subtotal.
        // Tax = Subtotal * (Rate / 100)
        // Total = Subtotal + Tax
        final taxCents = (subtotalAfterDiscountCents * (taxRate.ratePercent / 100.0)).round();
        final totalCents = subtotalAfterDiscountCents + taxCents;
        return TaxCalculationResult(
          netSubtotalCents: subtotalAfterDiscountCents,
          taxAmountCents: taxCents,
          finalTotalCents: totalCents,
          taxRate: taxRate,
        );
    }
  }
}
