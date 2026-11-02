import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/presentation/widgets/quantity_input_dialog.dart';
import '../../providers/cart_provider.dart';

/// Current order panel for reviewing and editing cart line items.
/// Displays tabular items, real-time total in Philippine Peso (PHP / ₱),
/// and interactive line selection with instant quantity adjustments.
class TerminalOrderPanel extends ConsumerWidget {
  const TerminalOrderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    final selectedItemId = ref.watch(selectedCartItemIdProvider);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    'QTY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    'PRICE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'TOTAL',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List or Empty Area
          Expanded(
            child: cartState.isEmpty
                ? const Center(
                    child: Text(
                      'READY FOR SALE\nTap products on left to add\nOr press CUSTOM to sell unlisted item',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      final isSelected = item.product.id == selectedItemId;

                      return InkWell(
                        onTap: () {
                          ref.read(selectedCartItemIdProvider.notifier).state =
                              item.product.id;
                        },
                        onDoubleTap: () async {
                          final newQty = await showDialog<int>(
                            context: context,
                            builder: (ctx) => QuantityInputDialog(item: item),
                          );
                          if (newQty != null) {
                            ref
                                .read(cartNotifierProvider.notifier)
                                .setQuantity(item.product.id, newQty);
                          }
                        },
                        onLongPress: () async {
                          final newQty = await showDialog<int>(
                            context: context,
                            builder: (ctx) => QuantityInputDialog(item: item),
                          );
                          if (newQty != null) {
                            ref
                                .read(cartNotifierProvider.notifier)
                                .setQuantity(item.product.id, newQty);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8F5D6)
                                : (index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA)),
                            border: isSelected
                                ? Border.all(color: AppColors.posLimeGreen, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Interactive QTY badge
                              InkWell(
                                onTap: () async {
                                  ref.read(selectedCartItemIdProvider.notifier).state =
                                      item.product.id;
                                  final newQty = await showDialog<int>(
                                    context: context,
                                    builder: (ctx) => QuantityInputDialog(item: item),
                                  );
                                  if (newQty != null) {
                                    ref
                                        .read(cartNotifierProvider.notifier)
                                        .setQuantity(item.product.id, newQty);
                                  }
                                },
                                child: Container(
                                  width: 38,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.posLimeGreen
                                          : const Color(0xFFEDEDED),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected
                                            ? Colors.black
                                            : const Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (item.discountPercent > 0)
                                      Text(
                                        '-${item.discountPercent.toStringAsFixed(0)}% Line Discount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.posDarkRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Text(
                                  CurrencyFormatter.format(item.product.priceCents),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  CurrencyFormatter.format(item.netLineTotalCents),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Order total in Philippine Peso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cartState.totalItemCount} ITEMS IN ORDER',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF999999),
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (cartState.totalDiscountCents > 0)
                      Text(
                        'Saved: -${CurrencyFormatter.format(cartState.totalDiscountCents)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.posLimeGreen,
                        ),
                      ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(cartState.grandTotalCents),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.posLimeGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
