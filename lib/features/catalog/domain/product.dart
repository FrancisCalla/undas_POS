/// Domain entity representing a retail catalog product.
/// Encapsulates inventory counts, minor-unit prices, and barcode identifiers.
class Product {
  final String id;
  final String sku;
  final String barcode;
  final String name;
  final int priceCents;
  final int stockQty;
  final String categoryId;
  final String description;
  final int colorValue;

  const Product({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.name,
    required this.priceCents,
    required this.stockQty,
    required this.categoryId,
    this.description = '',
    this.colorValue = 0xFF0F766E,
  });

  bool get isOutOfStock => stockQty <= 0;
  bool get isLowStock => stockQty > 0 && stockQty <= 5;

  Product copyWith({
    String? id,
    String? sku,
    String? barcode,
    String? name,
    int? priceCents,
    int? stockQty,
    String? categoryId,
    String? description,
    int? colorValue,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      stockQty: stockQty ?? this.stockQty,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'barcode': barcode,
    'name': name,
    'priceCents': priceCents,
    'stockQty': stockQty,
    'categoryId': categoryId,
    'description': description,
    'colorValue': colorValue,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String,
      priceCents: json['priceCents'] as int,
      stockQty: json['stockQty'] as int,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF0F766E,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
