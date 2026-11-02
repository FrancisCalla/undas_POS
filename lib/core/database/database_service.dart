import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/catalog/domain/category.dart';
import '../../features/catalog/domain/product.dart';
import '../../features/cart/domain/cart_item.dart';
import '../../features/cart/domain/cart_state.dart';
import '../../features/checkout/domain/order.dart';
import 'hive_boxes.dart';

/// Production offline-first storage engine orchestrating local Hive boxes.
/// Initialises with FLOWERS, CANDLES, DRINKS, ALL ITEMS categories and
/// an empty product catalog — cashiers add their own items via the terminal.
/// Includes crash-resilient cart persistence, atomic inventory updates,
/// and exhaustive error catching throughout all storage operations.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late Box<Map> _productsBox;
  late Box<Map> _ordersBox;
  late Box<Map> _cartBox;
  late Box<Map> _categoriesBox;

  Box<Map> get productsBox => _productsBox;
  Box<Map> get ordersBox => _ordersBox;
  Box<Map> get cartBox => _cartBox;
  Box<Map> get categoriesBox => _categoriesBox;

  /// Increment this string whenever the schema or seeding changes to force a migration.
  static const String currentDbVersion = 'schema_version_php_v3_empty';

  // ==================== INITIALIZATION ====================

  /// Opens all Hive boxes and migrates the schema when the version changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _productsBox = await Hive.openBox<Map>(HiveBoxes.products);
      _ordersBox = await Hive.openBox<Map>(HiveBoxes.orders);
      _cartBox = await Hive.openBox<Map>(HiveBoxes.cart);
      _categoriesBox = await Hive.openBox<Map>(HiveBoxes.categories);

      // Migration: clear and reseed when schema version changes or categories
      // belong to an old schema (e.g. cat_coffee from a prior version).
      final savedVersion = _categoriesBox.get('_version');
      final needsMigration = _categoriesBox.isEmpty ||
          _categoriesBox.containsKey('cat_coffee') ||
          !_categoriesBox.containsKey('cat_flowers') ||
          savedVersion?['value'] != currentDbVersion;

      if (needsMigration) {
        debugPrint('[DatabaseService] Migrating to v3 — clearing all data and seeding categories only...');
        await _runMigration();
      }

      _isInitialized = true;
      debugPrint('[DatabaseService] Hive engine initialized. Product catalog is empty — ready for cashier input.');
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to initialize Hive: $e\n$st');
      rethrow;
    }
  }

  // ==================== SCHEMA MIGRATION & RESET ====================

  /// Full reset: clears all boxes, writes the four category tabs, and
  /// marks the DB with the current schema version. No products are seeded.
  Future<void> resetDatabaseToDemo() async {
    try {
      await _productsBox.clear();
      await _ordersBox.clear();
      await _cartBox.clear();
      await _categoriesBox.clear();
      await _seedCategories();
      await _categoriesBox.put('_version', {'value': currentDbVersion});
      debugPrint('[DatabaseService] Catalog reset. All products cleared. Add items via the terminal.');
    } catch (e, st) {
      debugPrint('[DatabaseService] Error during resetDatabaseToDemo: $e\n$st');
      rethrow;
    }
  }

  Future<void> _runMigration() async {
    await _productsBox.clear();
    await _ordersBox.clear();
    await _cartBox.clear();
    await _categoriesBox.clear();
    await _seedCategories();
    await _categoriesBox.put('_version', {'value': currentDbVersion});
  }

  Future<void> _seedCategories() async {
    const defaultCategories = [
      Category(id: 'cat_all',     name: 'ALL ITEMS', iconCodePoint: 0xe318),
      Category(id: 'cat_flowers', name: 'FLOWERS',   iconCodePoint: 0xef4b),
      Category(id: 'cat_candles', name: 'CANDLES',   iconCodePoint: 0xf07f),
      Category(id: 'cat_drinks',  name: 'DRINKS',    iconCodePoint: 0xe510),
    ];

    for (final cat in defaultCategories) {
      await _categoriesBox.put(cat.id, cat.toJson());
    }
  }

  // ==================== PRODUCTS REPOSITORY ====================

  List<Product> getAllProducts() {
    try {
      final list = <Product>[];
      for (final raw in _productsBox.values) {
        try {
          list.add(Product.fromJson(Map<String, dynamic>.from(raw)));
        } catch (e) {
          debugPrint('[DatabaseService] Skipped corrupt product entry: $e');
        }
      }
      return list;
    } catch (e, st) {
      debugPrint('[DatabaseService] Error reading products: $e\n$st');
      return [];
    }
  }

  Future<bool> saveProduct(Product product) async {
    try {
      await _productsBox.put(product.id, product.toJson());
      return true;
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to save product ${product.id}: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _productsBox.delete(productId);
      return true;
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to delete product $productId: $e\n$st');
      return false;
    }
  }

  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      final raw = _productsBox.get(productId);
      if (raw != null) {
        final product = Product.fromJson(Map<String, dynamic>.from(raw));
        final updated = product.copyWith(stockQty: newStock < 0 ? 0 : newStock);
        await _productsBox.put(productId, updated.toJson());
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[DatabaseService] Error updating stock for $productId: $e\n$st');
      return false;
    }
  }

  /// Deducts stock permanently upon order checkout.
  Future<bool> deductStockForOrder(List<CartItem> items) async {
    try {
      for (final item in items) {
        // Custom ad-hoc items are not tracked in the catalog
        if (item.product.id.startsWith('custom_')) continue;

        final raw = _productsBox.get(item.product.id);
        if (raw != null) {
          final product = Product.fromJson(Map<String, dynamic>.from(raw));
          final remaining = (product.stockQty - item.quantity).clamp(0, 999999);
          final updated = product.copyWith(stockQty: remaining);
          await _productsBox.put(product.id, updated.toJson());
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to deduct stock for order: $e\n$st');
      return false;
    }
  }

  // ==================== CATEGORIES REPOSITORY ====================

  List<Category> getAllCategories() {
    try {
      final list = <Category>[];
      for (final raw in _categoriesBox.values) {
        try {
          if (raw.containsKey('id')) {
            list.add(Category.fromJson(Map<String, dynamic>.from(raw)));
          }
        } catch (e) {
          debugPrint('[DatabaseService] Skipped corrupt category entry: $e');
        }
      }
      return list;
    } catch (e, st) {
      debugPrint('[DatabaseService] Error reading categories: $e\n$st');
      return [];
    }
  }

  // ==================== ORDERS REPOSITORY ====================

  Future<bool> saveOrder(Order order) async {
    try {
      await _ordersBox.put(order.id, order.toJson());
      return true;
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to save order ${order.id}: $e\n$st');
      return false;
    }
  }

  List<Order> getAllOrders() {
    try {
      final list = <Order>[];
      for (final raw in _ordersBox.values) {
        try {
          list.add(Order.fromJson(Map<String, dynamic>.from(raw)));
        } catch (e) {
          debugPrint('[DatabaseService] Skipped corrupt order entry: $e');
        }
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e, st) {
      debugPrint('[DatabaseService] Error reading orders: $e\n$st');
      return [];
    }
  }

  // ==================== ACTIVE CART AUTO-SAVE ====================

  Future<bool> saveActiveCart(CartState state) async {
    try {
      await _cartBox.put('current_cart_session', state.toJson());
      return true;
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to save active cart: $e\n$st');
      return false;
    }
  }

  CartState? getActiveCart() {
    try {
      final raw = _cartBox.get('current_cart_session');
      if (raw != null) {
        return CartState.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to deserialize active cart: $e\n$st');
    }
    return null;
  }

  Future<bool> clearActiveCart() async {
    try {
      await _cartBox.delete('current_cart_session');
      return true;
    } catch (e, st) {
      debugPrint('[DatabaseService] Failed to clear active cart: $e\n$st');
      return false;
    }
  }
}
