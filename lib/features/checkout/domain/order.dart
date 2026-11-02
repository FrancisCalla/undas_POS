import 'dart:convert';
import 'payment_method.dart';
import '../../cart/domain/cart_item.dart';

/// Domain entity representing a finalized retail sales order.
/// Compatible with offline-first synchronization backends.
class Order {
  final String id;
  final DateTime timestamp;
  final String itemsJson;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int totalCents;
  final PaymentMethod paymentMethod;
  final bool isSynced;
  final String? customerName;
  final String? customerPhone;
  final int? cashTenderedCents;
  final int? changeDueCents;

  const Order({
    required this.id,
    required this.timestamp,
    required this.itemsJson,
    required this.subtotalCents,
    required this.discountCents,
    required this.taxCents,
    required this.totalCents,
    required this.paymentMethod,
    this.isSynced = false,
    this.customerName,
    this.customerPhone,
    this.cashTenderedCents,
    this.changeDueCents,
  });

  /// Decodes the stored items back to CartItem entities for order details.
  List<CartItem> get items {
    try {
      final decoded = jsonDecode(itemsJson) as List;
      return decoded.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'itemsJson': itemsJson,
    'subtotalCents': subtotalCents,
    'discountCents': discountCents,
    'taxCents': taxCents,
    'totalCents': totalCents,
    'paymentMethod': paymentMethod.name,
    'isSynced': isSynced,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'cashTenderedCents': cashTenderedCents,
    'changeDueCents': changeDueCents,
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      itemsJson: json['itemsJson'] as String,
      subtotalCents: json['subtotalCents'] as int,
      discountCents: json['discountCents'] as int? ?? 0,
      taxCents: json['taxCents'] as int,
      totalCents: json['totalCents'] as int,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      isSynced: json['isSynced'] as bool? ?? false,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      cashTenderedCents: json['cashTenderedCents'] as int?,
      changeDueCents: json['changeDueCents'] as int?,
    );
  }
}
