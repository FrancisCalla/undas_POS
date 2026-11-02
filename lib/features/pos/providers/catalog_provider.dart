import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/domain/product.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

/// Controller managing product catalog state, category selection,
/// searching, and CRUD operations with error catching.
class CatalogNotifier extends StateNotifier<List<Product>> {
  final CatalogRepository _repository;

  CatalogNotifier(this._repository) : super([]) {
    loadProducts();
  }

  void loadProducts() {
    try {
      state = _repository.getProducts();
    } catch (e, st) {
      debugPrint('[CatalogNotifier] Error loading products: $e\n$st');
      state = [];
    }
  }

  Future<void> reload() async {
    loadProducts();
  }

  Future<void> resetToDemo() async {
    try {
      await _repository.resetDemoData();
      loadProducts();
    } catch (e, st) {
      debugPrint('[CatalogNotifier] Failed to reset demo catalog: $e\n$st');
    }
  }

  Future<bool> saveProduct(Product product) async {
    try {
      await _repository.saveProduct(product);
      loadProducts();
      return true;
    } catch (e, st) {
      debugPrint('[CatalogNotifier] Failed to save product ${product.id}: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _repository.deleteProduct(productId);
      loadProducts();
      return true;
    } catch (e, st) {
      debugPrint('[CatalogNotifier] Failed to delete product $productId: $e\n$st');
      return false;
    }
  }
}

/// MVC Architectural alias for CatalogNotifier
typedef CatalogController = CatalogNotifier;

final catalogNotifierProvider =
    StateNotifierProvider<CatalogNotifier, List<Product>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repository);
});

final categoriesProvider = Provider<List<Category>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  try {
    return repository.getCategories();
  } catch (e) {
    debugPrint('[categoriesProvider] Error fetching categories: $e');
    return [];
  }
});

final selectedCategoryIdProvider = StateProvider<String>((ref) => 'cat_all');

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Reactively computes the displayed catalog grid based on active category and search filter.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(catalogNotifierProvider);
  final selectedCat = ref.watch(selectedCategoryIdProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return products.where((product) {
    // 1. Category Filter
    final matchesCategory = selectedCat == 'cat_all' || product.categoryId == selectedCat;
    if (!matchesCategory) return false;

    // 2. Search Query (matches Name, SKU, or Barcode)
    if (query.isEmpty) return true;
    final matchesName = product.name.toLowerCase().contains(query);
    final matchesSku = product.sku.toLowerCase().contains(query);
    final matchesBarcode = product.barcode.toLowerCase().contains(query);

    return matchesName || matchesSku || matchesBarcode;
  }).toList();
});
