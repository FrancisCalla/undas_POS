/// Domain entity representing a customer or retail loyalty profile.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int loyaltyPoints;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.loyaltyPoints = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'loyaltyPoints': loyaltyPoints,
  };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
