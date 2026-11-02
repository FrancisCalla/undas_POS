import '../../checkout/domain/tax_rate.dart';
import '../../../core/utils/tax_engine.dart';
import 'cart_item.dart';

/// Immutable domain state representing the complete active POS cart.
/// All monetary aggregates are computed strictly in integer minor units (cents).
class CartState {
  final List<CartItem> items;
  final double globalDiscountPercent;
  final TaxRate taxRate;

  const CartState({
    this.items = const [],
    this.globalDiscountPercent = 0.0,
    this.taxRate = TaxRate.standardExclusive,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Gross sum of all products before any discounts.
  int get grossSubtotalCents => items.fold(0, (sum, item) => sum + item.grossLineTotalCents);

  /// Sum of individual item-level discounts.
  int get lineItemDiscountsCents => items.fold(0, (sum, item) => sum + item.lineDiscountCents);

  /// Subtotal after item-level discounts have been subtracted.
  int get subtotalAfterLineDiscountsCents => grossSubtotalCents - lineItemDiscountsCents;

  /// Global order-level discount amount.
  int get globalDiscountCents {
    if (globalDiscountPercent <= 0) return 0;
    return ((subtotalAfterLineDiscountsCents * globalDiscountPercent) / 100.0).round();
  }

  /// Total discount combined (line-level + order-level).
  int get totalDiscountCents => lineItemDiscountsCents + globalDiscountCents;

  /// Taxable subtotal after all discounts.
  int get taxableSubtotalCents => subtotalAfterLineDiscountsCents - globalDiscountCents;

  /// Tax computation result using the selected tax regime.
  TaxCalculationResult get taxResult => TaxEngine.calculate(
    subtotalAfterDiscountCents: taxableSubtotalCents,
    taxRate: taxRate,
  );

  /// Tax payable in cents.
  int get taxCents => taxResult.taxAmountCents;

  /// Grand total payable in cents.
  int get grandTotalCents => taxResult.finalTotalCents;

  CartState copyWith({
    List<CartItem>? items,
    double? globalDiscountPercent,
    TaxRate? taxRate,
  }) {
    return CartState(
      items: items ?? this.items,
      globalDiscountPercent: globalDiscountPercent ?? this.globalDiscountPercent,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'globalDiscountPercent': globalDiscountPercent,
    'taxRate': taxRate.toJson(),
  };

  factory CartState.fromJson(Map<String, dynamic> json) {
    return CartState(
      items: (json['items'] as List?)
              ?.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      globalDiscountPercent: (json['globalDiscountPercent'] as num?)?.toDouble() ?? 0.0,
      taxRate: json['taxRate'] != null
          ? TaxRate.fromJson(Map<String, dynamic>.from(json['taxRate'] as Map))
          : TaxRate.standardExclusive,
    );
  }
}
