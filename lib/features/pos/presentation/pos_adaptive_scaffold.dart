import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../cart/domain/cart_state.dart';
import '../../catalog/presentation/widgets/category_filter_bar.dart';
import '../../catalog/presentation/widgets/product_grid.dart';
import '../../catalog/presentation/widgets/add_edit_product_dialog.dart';
import '../../cart/presentation/widgets/custom_item_dialog.dart';
import '../../checkout/presentation/order_history_dialog.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import 'widgets/terminal_action_column.dart';
import 'widgets/terminal_keypad_panel.dart';
import 'widgets/terminal_order_panel.dart';
import 'widgets/terminal_tender_bar.dart';

/// Full POS terminal interface matching the commercial touch terminal in Image 2.
/// Includes top lime-green category tabs, 3-column white touch grid, middle action column,
/// bottom quick cash tender bar, current order, 6 function buttons, and 4x3 numeric keypad.
class PosAdaptiveScaffold extends ConsumerWidget {
  const PosAdaptiveScaffold({super.key});

  void _openAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AddEditProductDialog(),
    );
  }

  void _openCustomSaleDialog(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletLandscape = screenWidth >= 750;
    final cartState = ref.watch(cartNotifierProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 44,
          titleSpacing: 12,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.posLimeGreen,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'TERMINAL #1',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'FLOWERS • CANDLES • DRINKS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            // + Add Item
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.posLimeGreen,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => _openAddProductDialog(context),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Add Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),

            // Quick Custom Sale
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.posOrange,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => _openCustomSaleDialog(context, ref),
              icon: const Icon(Icons.flash_on, size: 16),
              label: const Text('Custom Sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),

            // Order History
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white70, size: 20),
              tooltip: 'Order History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const OrderHistoryDialog(),
                );
              },
            ),

            // Terminal Settings / Reset
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
              tooltip: 'Terminal Settings',
              onSelected: (val) {
                if (val == 'reset') {
                  _confirmResetDemo(context, ref);
                } else if (val == 'add') {
                  _openAddProductDialog(context);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: AppColors.posLimeGreen),
                      SizedBox(width: 10),
                      Text('Add New Product to System'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt, size: 18, color: AppColors.posOrange),
                      SizedBox(width: 10),
                      Text('Reset Demo Catalog'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: isTabletLandscape
            ? _buildSplitScreenTablet(context, ref, cartState)
            : _buildMobilePortrait(context, ref, cartState),
    );
  }

  /// Full Terminal UI matching Image 2
  Widget _buildSplitScreenTablet(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return Container(
      color: Colors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT PANEL: Top Category Tabs + 3-Column Product Grid + Bottom Tender Bar
          Expanded(
            flex: 6,
            child: Column(
              children: [
                const CategoryFilterBar(),
                const Expanded(child: ProductGrid()),
                const TerminalTenderBar(),
              ],
            ),
          ),

          // MIDDLE COLUMN: SWAP, ADD, REMOVE, CUSTOM
          const TerminalActionColumn(),

          // RIGHT PANEL: Current Order + Bottom 6 Action Buttons & 4x3 Keypad
          SizedBox(
            width: 380,
            child: Column(
              children: [
                const Expanded(flex: 5, child: TerminalOrderPanel()),
                const Expanded(flex: 6, child: TerminalKeypadPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Mobile Layout with Sliding Bottom Order Tray
  Widget _buildMobilePortrait(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return Column(
      children: [
        const CategoryFilterBar(),
        const Expanded(child: ProductGrid()),
        if (cartState.isNotEmpty)
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: const TerminalOrderPanel(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF1E1E1E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: AppColors.posLimeGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'View Order (${cartState.totalItemCount} items)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(cartState.grandTotalCents),
                    style: const TextStyle(
                      color: AppColors.posLimeGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const TerminalTenderBar(),
      ],
    );
  }

  void _confirmResetDemo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Catalog?'),
        content: const Text(
          'This will reset the catalog to the default Flowers, Candles, and Drinks items.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.posOrange),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(catalogNotifierProvider.notifier).resetToDemo();
              ref.read(cartNotifierProvider.notifier).clearCart();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo catalog reset to Flowers, Candles & Drinks.'),
                    backgroundColor: AppColors.posLimeGreen,
                  ),
                );
              }
            },
            child: const Text('Reset Demo'),
          ),
        ],
      ),
    );
  }
}
