enum TaxType {
  exclusiveVat,
  inclusiveVat,
  flatRegional;

  String get displayName {
    switch (this) {
      case TaxType.exclusiveVat:
        return 'Exclusive VAT (Added on top)';
      case TaxType.inclusiveVat:
        return 'Inclusive VAT (Included in price)';
      case TaxType.flatRegional:
        return 'Regional Sales Tax';
    }
  }
}

/// Domain entity representing a tax configuration rate and calculation regime.
class TaxRate {
  final String id;
  final String name;
  final double ratePercent;
  final TaxType type;

  const TaxRate({
    required this.id,
    required this.name,
    required this.ratePercent,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ratePercent': ratePercent,
    'type': type.name,
  };

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id'] as String,
      name: json['name'] as String,
      ratePercent: (json['ratePercent'] as num).toDouble(),
      type: TaxType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaxType.exclusiveVat,
      ),
    );
  }

  // Common enterprise presets
  static const standardExclusive = TaxRate(
    id: 'tax_exclusive_10',
    name: 'Standard VAT 10% (Exclusive)',
    ratePercent: 10.0,
    type: TaxType.exclusiveVat,
  );

  static const standardInclusive = TaxRate(
    id: 'tax_inclusive_10',
    name: 'Standard VAT 10% (Inclusive)',
    ratePercent: 10.0,
    type: TaxType.inclusiveVat,
  );

  static const regionalSales = TaxRate(
    id: 'tax_regional_7',
    name: 'Regional Sales Tax 7.5%',
    ratePercent: 7.5,
    type: TaxType.flatRegional,
  );

  static const zeroTax = TaxRate(
    id: 'tax_exempt_0',
    name: 'Tax Exempt (0%)',
    ratePercent: 0.0,
    type: TaxType.exclusiveVat,
  );

  static const List<TaxRate> defaultRates = [
    standardExclusive,
    standardInclusive,
    regionalSales,
    zeroTax,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxRate && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
