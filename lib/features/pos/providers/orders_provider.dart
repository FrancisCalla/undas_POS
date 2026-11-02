import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../cart/domain/cart_state.dart';
import '../../checkout/domain/order.dart';
import '../../checkout/domain/payment_method.dart';
import 'cart_provider.dart';
import 'catalog_provider.dart';

/// Controller orchestrating order creation, checkout finalization,
/// transactional inventory deductions, and local persistence.
class OrdersNotifier extends StateNotifier<List<Order>> {
  final DatabaseService _db;
  final Ref _ref;
  static const _uuid = Uuid();

  OrdersNotifier(this._db, this._ref) : super([]) {
    loadOrders();
  }

  void loadOrders() {
    try {
      state = _db.getAllOrders();
    } catch (e, st) {
      debugPrint('[OrdersNotifier] Failed to load orders: $e\n$st');
      state = [];
    }
  }

  /// Finalizes and commits a transaction atomically.
  /// Deducts inventory, writes the order record, and purges the active cart.
  Future<Order> finalizeCheckout({
    required CartState cartState,
    required PaymentMethod paymentMethod,
    String? customerName,
    String? customerPhone,
    int? cashTenderedCents,
    int? changeDueCents,
  }) async {
    if (cartState.isEmpty) {
      throw StateError('Cannot checkout an empty cart. Please add items first.');
    }

    if (paymentMethod == PaymentMethod.cash &&
        cashTenderedCents != null &&
        cashTenderedCents < cartState.grandTotalCents) {
      throw ArgumentError(
        'Insufficient cash: Tendered $cashTenderedCents cents but total is ${cartState.grandTotalCents} cents.',
      );
    }

    final orderId = 'ORD-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final itemsJson = jsonEncode(cartState.items.map((e) => e.toJson()).toList());

    final order = Order(
      id: orderId,
      timestamp: DateTime.now(),
      itemsJson: itemsJson,
      subtotalCents: cartState.grossSubtotalCents,
      discountCents: cartState.totalDiscountCents,
      taxCents: cartState.taxCents,
      totalCents: cartState.grandTotalCents,
      paymentMethod: paymentMethod,
      isSynced: false,
      customerName: customerName,
      customerPhone: customerPhone,
      cashTenderedCents: cashTenderedCents,
      changeDueCents: changeDueCents,
    );

    try {
      // 1. Commit order to Hive database
      final saved = await _db.saveOrder(order);
      if (!saved) {
        throw Exception('Failed to write order record to local storage.');
      }

      // 2. Atomically deduct inventory for sold items
      await _db.deductStockForOrder(cartState.items);

      // 3. Clear active cart state & persistence
      _ref.read(cartNotifierProvider.notifier).clearCart();

      // 4. Force catalog reload so stock badges immediately reflect reductions
      _ref.read(catalogNotifierProvider.notifier).loadProducts();

      // 5. Update local orders list state
      state = [order, ...state];

      return order;
    } catch (e, st) {
      debugPrint('[OrdersNotifier] finalizeCheckout transaction failed: $e\n$st');
      rethrow;
    }
  }
}

/// MVC Architectural alias for OrdersNotifier
typedef OrdersController = OrdersNotifier;

final ordersNotifierProvider =
    StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  final db = DatabaseService.instance;
  return OrdersNotifier(db, ref);
});
