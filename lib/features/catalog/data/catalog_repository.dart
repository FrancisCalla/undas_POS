import '../../../core/database/database_service.dart';
import '../domain/category.dart';
import '../domain/product.dart';

/// Repository abstracting catalog data persistence.
class CatalogRepository {
  final DatabaseService _db;

  CatalogRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  List<Product> getProducts() {
    return _db.getAllProducts();
  }

  List<Category> getCategories() {
    return _db.getAllCategories();
  }

  Future<void> saveProduct(Product product) async {
    await _db.saveProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _db.deleteProduct(productId);
  }

  Future<void> updateStock(String productId, int newStock) async {
    await _db.updateProductStock(productId, newStock);
  }

  Future<void> resetDemoData() async {
    await _db.resetDatabaseToDemo();
  }
}
