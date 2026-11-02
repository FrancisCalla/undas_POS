import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/cart_item.dart';
import '../../../pos/providers/cart_provider.dart';
import 'discount_dialog.dart';
import 'quantity_input_dialog.dart';

/// Interactive cart line item tile with quantity adjustments, line discounts,
/// and live inventory cap enforcement.
class CartItemTile extends ConsumerWidget {
  final CartItem item;

  const CartItemTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space8),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name, Unit Price, and Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(product.priceCents)} each | SKU: ${product.sku}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(cartNotifierProvider.notifier).removeItem(product.id);
                },
                tooltip: 'Remove item',
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),

          // Stepper and Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Stepper
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppDimens.radiusSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: () {
                        ref.read(cartNotifierProvider.notifier).decrementItem(product.id);
                      },
                    ),
                    InkWell(
                      onTap: () async {
                        final newQty = await showDialog<int>(
                          context: context,
                          builder: (ctx) => QuantityInputDialog(item: item),
                        );
                        if (newQty != null) {
                          final res = ref
                              .read(cartNotifierProvider.notifier)
                              .setQuantity(product.id, newQty);
                          if (res == AddToCartResult.exceedsAvailableStock && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Max stock available is ${product.stockQty}.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: AppDimens.radiusSm,
                      child: Tooltip(
                        message: 'Tap to enter custom quantity',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: AppDimens.radiusSm,
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: () {
                        final result = ref
                            .read(cartNotifierProvider.notifier)
                            .addToCart(product, quantity: 1);
                        if (result == AddToCartResult.exceedsAvailableStock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot add more. Max ${product.stockQty} in stock!'),
                              backgroundColor: AppColors.warning,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Line Discount Button
              InkWell(
                onTap: () async {
                  final newDiscount = await showDialog<double>(
                    context: context,
                    builder: (ctx) => DiscountDialog(
                      title: 'Item Discount: ${product.name}',
                      currentDiscountPercent: item.discountPercent,
                    ),
                  );
                  if (newDiscount != null) {
                    ref
                        .read(cartNotifierProvider.notifier)
                        .updateItemDiscount(product.id, newDiscount);
                  }
                },
                borderRadius: AppDimens.radiusSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.discountPercent > 0
                        ? AppColors.warningBg
                        : AppColors.surfaceSubtle,
                    borderRadius: AppDimens.radiusSm,
                    border: Border.all(
                      color: item.discountPercent > 0
                          ? AppColors.warning.withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.percent,
                        size: 13,
                        color: item.discountPercent > 0
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.discountPercent > 0
                            ? '-${item.discountPercent.toStringAsFixed(0)}%'
                            : 'Discount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: item.discountPercent > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: item.discountPercent > 0
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Line Total in Minor Units
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.discountPercent > 0)
                    Text(
                      CurrencyFormatter.format(item.grossLineTotalCents),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    CurrencyFormatter.format(item.netLineTotalCents),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.radiusSm,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
