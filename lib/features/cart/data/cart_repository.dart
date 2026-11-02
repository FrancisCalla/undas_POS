import '../../../core/database/database_service.dart';
import '../domain/cart_state.dart';

/// Repository ensuring transactional recovery of cart contents across sudden terminations.
class CartRepository {
  final DatabaseService _db;

  CartRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  Future<void> persistCart(CartState cart) async {
    await _db.saveActiveCart(cart);
  }

  CartState? restoreCart() {
    return _db.getActiveCart();
  }

  Future<void> purgeCart() async {
    await _db.clearActiveCart();
  }
}
