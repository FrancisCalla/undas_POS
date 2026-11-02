import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../pos/providers/cart_provider.dart';
import 'cart_item_tile.dart';
import 'custom_item_dialog.dart';
import 'discount_dialog.dart';
import 'tax_selector_widget.dart';

/// Complete reactive cart sidebar pane displaying real-time line items,
/// global discounts, multi-regime tax calculations, and checkout triggers.
class CartPane extends ConsumerWidget {
  final VoidCallback onCheckoutPressed;

  const CartPane({
    super.key,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Column(
        children: [
          // 1. CART HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Current Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppDimens.radiusSm,
                  ),
                  child: Text(
                    '${cartState.totalItemCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flash_on, color: AppColors.accent, size: 20),
                  tooltip: 'Quick Custom Sale',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _openCustomItemDialog(context, ref),
                ),
                const SizedBox(width: 8),
                if (cartState.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      _showClearConfirmation(context, ref);
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // 2. ITEMS LIST / EMPTY STATE
          Expanded(
            child: cartState.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.space24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Cart is empty',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap items on the catalog or add a custom sale.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                            ),
                            onPressed: () => _openCustomItemDialog(context, ref),
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text('Direct Custom Sale'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimens.space12),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(item: cartState.items[index]);
                    },
                  ),
          ),

          // 3. SETTINGS & FINANCIAL SUMMARY
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tax Structure Selector
                const TaxSelectorWidget(),
                const SizedBox(height: 10),

                // Order-Level Discount Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Discount',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: cartState.globalDiscountPercent > 0
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                      onPressed: cartState.isEmpty
                          ? null
                          : () async {
                              final newDiscount = await showDialog<double>(
                                context: context,
                                builder: (ctx) => DiscountDialog(
                                  title: 'Order-Level Discount',
                                  currentDiscountPercent: cartState.globalDiscountPercent,
                                ),
                              );
                              if (newDiscount != null) {
                                ref
                                    .read(cartNotifierProvider.notifier)
                                    .setGlobalDiscount(newDiscount);
                              }
                            },
                      icon: const Icon(Icons.discount_outlined, size: 16),
                      label: Text(
                        cartState.globalDiscountPercent > 0
                            ? '-${cartState.globalDiscountPercent.toStringAsFixed(0)}%'
                            : 'Apply Discount',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12, color: AppColors.border),

                // Subtotal Row
                _SummaryRow(
                  label: 'Gross Subtotal',
                  value: CurrencyFormatter.format(cartState.grossSubtotalCents),
                ),
                if (cartState.totalDiscountCents > 0)
                  _SummaryRow(
                    label: 'Total Discounts',
                    value: '-${CurrencyFormatter.format(cartState.totalDiscountCents)}',
                    valueColor: AppColors.warning,
                  ),
                _SummaryRow(
                  label: 'Tax (${cartState.taxRate.ratePercent.toStringAsFixed(1)}%)',
                  value: CurrencyFormatter.format(cartState.taxCents),
                ),
                const SizedBox(height: 8),

                // Total Payable Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cartTotalBg,
                    borderRadius: AppDimens.radiusMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL DUE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            'Inclusive of taxes',
                            style: TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(cartState.grandTotalCents),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // CHECKOUT ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.borderStrong,
                      shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusMd),
                    ),
                    onPressed: cartState.isEmpty ? null : onCheckoutPressed,
                    icon: const Icon(Icons.payment, size: 20),
                    label: Text(
                      'Checkout (${CurrencyFormatter.format(cartState.grandTotalCents)})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomItemDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const CustomItemDialog(),
    );
    if (result != null) {
      ref.read(cartNotifierProvider.notifier).addCustomItem(
            name: result['name'] as String,
            unitPriceCents: result['unitPriceCents'] as int,
            quantity: result['quantity'] as int,
          );
    }
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Active Cart?'),
        content: const Text(
          'This will remove all items and reset discounts. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).clearCart();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
