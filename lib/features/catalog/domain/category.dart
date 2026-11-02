/// Domain entity representing a product category in the POS catalog.
class Category {
  final String id;
  final String name;
  final int iconCodePoint;

  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconCodePoint': iconCodePoint,
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe59c,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
