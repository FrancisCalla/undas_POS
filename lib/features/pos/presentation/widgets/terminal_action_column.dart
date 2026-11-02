import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../cart/presentation/widgets/custom_item_dialog.dart';
import '../../../cart/presentation/widgets/quantity_input_dialog.dart';
import '../../providers/cart_provider.dart';

/// Middle vertical action column matching Image 2:
/// [SWAP]
/// [QTY]
/// [ADD]
/// [REMOVE]
/// [CUSTOM]
class TerminalActionColumn extends ConsumerWidget {
  const TerminalActionColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    final selectedItemId = ref.watch(selectedCartItemIdProvider);

    return Container(
      width: 90,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SWAP / TOGGLE
          Expanded(
            child: _ActionColumnButton(
              label: 'SWAP',
              color: const Color(0xFF5D664E),
              onTap: () {
                if (cartState.items.isNotEmpty) {
                  final currentIndex = cartState.items.indexWhere(
                    (i) => i.product.id == selectedItemId,
                  );
                  final nextIndex = (currentIndex + 1) % cartState.items.length;
                  ref.read(selectedCartItemIdProvider.notifier).state =
                      cartState.items[nextIndex].product.id;
                }
              },
            ),
          ),
          const SizedBox(height: 4),

          // QTY (Opens dynamic quantity & amount calculator dialog)
          Expanded(
            child: _ActionColumnButton(
              label: 'QTY',
              color: AppColors.posDarkBlue,
              onTap: () async {
                if (cartState.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add an item to the order first to set quantity.'),
                      backgroundColor: AppColors.posOrange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                final targetId = selectedItemId ?? cartState.items.last.product.id;
                final item = cartState.items.firstWhere(
                  (i) => i.product.id == targetId,
                  orElse: () => cartState.items.last,
                );

                final newQty = await showDialog<int>(
                  context: context,
                  builder: (ctx) => QuantityInputDialog(item: item),
                );

                if (newQty != null) {
                  final res = ref.read(cartNotifierProvider.notifier).setQuantity(item.product.id, newQty);
                  if (res == AddToCartResult.exceedsAvailableStock && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Entered quantity exceeds available stock (${item.product.stockQty}).'),
                        backgroundColor: AppColors.posOrange,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 4),

          // ADD (+1 to selected item in cart)
          Expanded(
            child: _ActionColumnButton(
              label: 'ADD',
              color: AppColors.posOlive,
              onTap: () {
                if (cartState.items.isEmpty) return;
                final targetId = selectedItemId ?? cartState.items.last.product.id;
                final item = cartState.items.firstWhere(
                  (i) => i.product.id == targetId,
                  orElse: () => cartState.items.last,
                );
                final res = ref.read(cartNotifierProvider.notifier).addToCart(item.product, quantity: 1);
                if (res == AddToCartResult.exceedsAvailableStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot add more. Max ${item.product.stockQty} in stock!'),
                      backgroundColor: AppColors.posOrange,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 4),

          // REMOVE (-1 from selected item in cart)
          Expanded(
            child: _ActionColumnButton(
              label: 'REMOVE',
              color: AppColors.posOlive,
              onTap: () {
                if (cartState.items.isEmpty) return;
                final targetId = selectedItemId ?? cartState.items.last.product.id;
                ref.read(cartNotifierProvider.notifier).decrementItem(targetId);
              },
            ),
          ),
          const SizedBox(height: 4),

          // CUSTOM / DIRECT ITEM
          Expanded(
            child: _ActionColumnButton(
              label: 'CUSTOM',
              color: AppColors.posTeal,
              onTap: () async {
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionColumnButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionColumnButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
