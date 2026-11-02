import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/data/cart_repository.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/domain/cart_state.dart';
import '../../catalog/domain/product.dart';
import '../../checkout/domain/tax_rate.dart';

enum AddToCartResult {
  success,
  outOfStock,
  exceedsAvailableStock,
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository();
});

/// Controller managing reactive cart state, line-item arithmetic,
/// stock depletion prevention, discounts, and auto-save persistence.
class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const CartState()) {
    _restoreSavedCart();
  }

  void _restoreSavedCart() {
    try {
      final saved = _repository.restoreCart();
      if (saved != null) {
        state = saved;
      }
    } catch (e, st) {
      debugPrint('[CartNotifier] Failed to restore cart session: $e\n$st');
    }
  }

  /// Adds a product to the cart while strictly guarding inventory limits.
  AddToCartResult addToCart(Product product, {int quantity = 1}) {
    if (product.stockQty <= 0) {
      return AddToCartResult.outOfStock;
    }

    final safeQty = quantity <= 0 ? 1 : quantity;
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final newQuantity = existingItem.quantity + safeQty;

      if (newQuantity > product.stockQty) {
        return AddToCartResult.exceedsAvailableStock;
      }

      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = existingItem.copyWith(quantity: newQuantity);

      state = state.copyWith(items: updatedList);
    } else {
      if (safeQty > product.stockQty) {
        return AddToCartResult.exceedsAvailableStock;
      }

      final newItem = CartItem(
        product: product,
        quantity: safeQty,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }

    _persist();
    return AddToCartResult.success;
  }

  /// Sets absolute quantity for an item (e.g. entered via keypad/dialog).
  AddToCartResult setQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return AddToCartResult.success;
    }

    final existingIndex = state.items.indexWhere((i) => i.product.id == productId);
    if (existingIndex < 0) return AddToCartResult.outOfStock;

    final existingItem = state.items[existingIndex];
    if (newQuantity > existingItem.product.stockQty) {
      return AddToCartResult.exceedsAvailableStock;
    }

    final updatedList = List<CartItem>.from(state.items);
    updatedList[existingIndex] = existingItem.copyWith(quantity: newQuantity);
    state = state.copyWith(items: updatedList);
    _persist();
    return AddToCartResult.success;
  }

  /// Adds a custom ad-hoc line item directly to the active sale.
  void addCustomItem({
    required String name,
    required int unitPriceCents,
    int quantity = 1,
  }) {
    final sanitizedPrice = unitPriceCents < 0 ? 0 : unitPriceCents;
    final sanitizedQty = quantity < 1 ? 1 : quantity;

    final customProduct = Product(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      sku: 'CUSTOM',
      barcode: '',
      name: name.trim().isEmpty ? 'Custom Item' : name.trim(),
      priceCents: sanitizedPrice,
      stockQty: 999999,
      categoryId: 'cat_all',
      description: 'Quick manual sale item',
      colorValue: 0xFF0284C7,
    );

    final newItem = CartItem(
      product: customProduct,
      quantity: sanitizedQty,
    );

    state = state.copyWith(items: [...state.items, newItem]);
    _persist();
  }

  /// Decrements item quantity, removing the line item if quantity drops to 0.
  void decrementItem(String productId) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == productId);
    if (existingIndex < 0) return;

    final existingItem = state.items[existingIndex];
    if (existingItem.quantity > 1) {
      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity - 1);
      state = state.copyWith(items: updatedList);
    } else {
      removeItem(productId);
      return;
    }

    _persist();
  }

  /// Removes a line item completely from the cart.
  void removeItem(String productId) {
    final updatedList = state.items.where((i) => i.product.id != productId).toList();
    state = state.copyWith(items: updatedList);
    _persist();
  }

  /// Sets percentage discount for an individual line item (0 - 100%).
  void updateItemDiscount(String productId, double discountPercent) {
    final clamped = discountPercent.clamp(0.0, 100.0);
    final existingIndex = state.items.indexWhere((i) => i.product.id == productId);
    if (existingIndex < 0) return;

    final updatedList = List<CartItem>.from(state.items);
    updatedList[existingIndex] = updatedList[existingIndex].copyWith(discountPercent: clamped);
    state = state.copyWith(items: updatedList);
    _persist();
  }

  /// Sets global order percentage discount (0 - 100%).
  void setGlobalDiscount(double discountPercent) {
    final clamped = discountPercent.clamp(0.0, 100.0);
    state = state.copyWith(globalDiscountPercent: clamped);
    _persist();
  }

  /// Changes active tax calculation regime.
  void setTaxRate(TaxRate taxRate) {
    state = state.copyWith(taxRate: taxRate);
    _persist();
  }

  /// Resets the cart to empty and purges persistent local storage.
  void clearCart() {
    state = const CartState();
    try {
      _repository.purgeCart();
    } catch (e) {
      debugPrint('[CartNotifier] Failed to purge cart from repository: $e');
    }
  }

  void _persist() {
    try {
      _repository.persistCart(state);
    } catch (e) {
      debugPrint('[CartNotifier] Failed to persist active cart: $e');
    }
  }
}

/// MVC Architectural alias for CartNotifier
typedef CartController = CartNotifier;

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository);
});

/// Currently selected line item ID in the active order for keypad quantity adjustments.
final selectedCartItemIdProvider = StateProvider<String?>((ref) => null);
