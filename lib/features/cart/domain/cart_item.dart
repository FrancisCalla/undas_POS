import '../../catalog/domain/product.dart';

/// Domain entity representing a line item inside an active retail cart.
class CartItem {
  final Product product;
  final int quantity;
  final double discountPercent; // 0.0 to 100.0%
  final List<String> selectedModifiers;
  final String notes;

  const CartItem({
    required this.product,
    this.quantity = 1,
    this.discountPercent = 0.0,
    this.selectedModifiers = const [],
    this.notes = '',
  });

  /// Base total before item-level discount in minor units (cents).
  int get grossLineTotalCents => product.priceCents * quantity;

  /// Line-item discount amount in minor units (cents).
  int get lineDiscountCents {
    if (discountPercent <= 0) return 0;
    return ((grossLineTotalCents * discountPercent) / 100.0).round();
  }

  /// Final payable amount for this line item in minor units (cents).
  int get netLineTotalCents => grossLineTotalCents - lineDiscountCents;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discountPercent,
    List<String>? selectedModifiers,
    String? notes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'discountPercent': discountPercent,
    'selectedModifiers': selectedModifiers,
    'notes': notes,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      quantity: json['quantity'] as int? ?? 1,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      selectedModifiers: (json['selectedModifiers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'] as String? ?? '',
    );
  }
}
