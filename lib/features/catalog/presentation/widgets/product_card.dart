import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/product.dart';
import '../../../pos/providers/cart_provider.dart';
import 'add_edit_product_dialog.dart';

/// Retail POS touch tile matching the high-contrast white touch buttons in Image 2.
class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDepleted = product.isOutOfStock;
    final cartState = ref.watch(cartNotifierProvider);

    final cartItemIndex = cartState.items.indexWhere((i) => i.product.id == product.id);
    final inCartQty = cartItemIndex >= 0 ? cartState.items[cartItemIndex].quantity : 0;

    return Material(
      color: isDepleted ? const Color(0xFFF0F0F0) : Colors.white,
      child: InkWell(
        onTap: isDepleted
            ? null
            : () {
                final result = ref.read(cartNotifierProvider.notifier).addToCart(product);
                if (result == AddToCartResult.exceedsAvailableStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot add more. Only ${product.stockQty} in stock!'),
                      backgroundColor: AppColors.posOrange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AddEditProductDialog(productToEdit: product),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDepleted ? const Color(0xFFEDEDED) : Colors.white,
            border: Border.all(
              color: inCartQty > 0 ? AppColors.posLimeGreen : const Color(0xFF333333),
              width: inCartQty > 0 ? 2.5 : 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Stack(
            children: [
              // Main content: Name and Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    product.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isDepleted ? const Color(0xFF888888) : const Color(0xFF1E1E1E),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(product.priceCents),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDepleted ? const Color(0xFF999999) : const Color(0xFF4C781E),
                    ),
                  ),
                  const Spacer(),
                  // In-cart indicator or stock count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (inCartQty > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.posLimeGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$inCartQty in order',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Stock: ${product.stockQty}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDepleted ? AppColors.posRed : const Color(0xFF777777),
                            fontWeight: isDepleted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),

              // Green shopping basket/cart icon in bottom right (as in Image 2)
              Positioned(
                bottom: 0,
                right: 0,
                child: Icon(
                  Icons.shopping_basket_rounded,
                  size: 20,
                  color: isDepleted
                      ? const Color(0xFFAAAAAA)
                      : AppColors.posLimeGreenDark,
                ),
              ),

              // Edit icon on top-right corner
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AddEditProductDialog(productToEdit: product),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.edit_outlined, size: 14, color: Color(0xFF999999)),
                  ),
                ),
              ),

              // Depleted watermark
              if (isDepleted)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.posRed.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
