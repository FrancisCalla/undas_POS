import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/domain/cart_state.dart';
import '../../../checkout/domain/payment_method.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../../checkout/presentation/checkout_summary_dialog.dart';

/// Bottom horizontal tender bar matching Image 2:
/// [₱20] [₱50] [₱100] [₱500] [CASH] [EFTPOS]
class TerminalTenderBar extends ConsumerWidget {
  const TerminalTenderBar({super.key});

  Future<void> _quickCashPay(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    int cashTenderedCents,
  ) async {
    if (cartState.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order is empty. Please select items first!'),
          backgroundColor: AppColors.posOrange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final grandTotal = cartState.grandTotalCents;
    if (cashTenderedCents < grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tender ${CurrencyFormatter.format(cashTenderedCents)} is less than total ${CurrencyFormatter.format(grandTotal)}. Opening cash settlement dialog.',
          ),
          backgroundColor: AppColors.posOrange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Open checkout dialog to allow entering higher or exact tender
      showDialog(
        context: context,
        builder: (ctx) => CheckoutSummaryDialog(cartState: cartState),
      );
      return;
    }

    try {
      final changeDue = cashTenderedCents - grandTotal;

      // Directly finalize order
      await ref.read(ordersNotifierProvider.notifier).finalizeCheckout(
            cartState: cartState,
            paymentMethod: PaymentMethod.cash,
            cashTenderedCents: cashTenderedCents,
            changeDueCents: changeDue,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment accepted. Order saved.'),
            backgroundColor: AppColors.posLimeGreenDark,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);

    return Container(
      height: 64,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Cash Tender: ₱20
          _TenderButton(
            label: '₱20',
            color: const Color(0xFF1E1E1E),
            textColor: Colors.white,
            onTap: () => _quickCashPay(context, ref, cartState, 2000),
          ),
          const SizedBox(width: 4),

          // Quick Cash Tender: ₱50
          _TenderButton(
            label: '₱50',
            color: const Color(0xFF1E1E1E),
            textColor: Colors.white,
            onTap: () => _quickCashPay(context, ref, cartState, 5000),
          ),
          const SizedBox(width: 4),

          // Quick Cash Tender: ₱100
          _TenderButton(
            label: '₱100',
            color: const Color(0xFF1E1E1E),
            textColor: Colors.white,
            onTap: () => _quickCashPay(context, ref, cartState, 10000),
          ),
          const SizedBox(width: 4),

          // Quick Cash Tender: ₱500
          _TenderButton(
            label: '₱500',
            color: const Color(0xFF1E1E1E),
            textColor: Colors.white,
            onTap: () => _quickCashPay(context, ref, cartState, 50000),
          ),
          const SizedBox(width: 4),

          // CASH button (Lime Green)
          Expanded(
            flex: 2,
            child: Material(
              color: AppColors.posLimeGreen,
              child: InkWell(
                onTap: cartState.isEmpty
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (ctx) => CheckoutSummaryDialog(cartState: cartState),
                        );
                      },
                child: Center(
                  child: Text(
                    'CASH',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: cartState.isEmpty ? Colors.black45 : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // EFTPOS / CARD button (Amber Orange)
          Expanded(
            flex: 2,
            child: Material(
              color: AppColors.posOrange,
              child: InkWell(
                onTap: cartState.isEmpty
                    ? null
                    : () async {
                        try {
                          await ref.read(ordersNotifierProvider.notifier).finalizeCheckout(
                                cartState: cartState,
                                paymentMethod: PaymentMethod.card,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment accepted. Order saved.'),
                                backgroundColor: AppColors.posLimeGreenDark,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Card settlement error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: Center(
                  child: Text(
                    'EFTPOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: cartState.isEmpty ? Colors.black45 : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenderButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _TenderButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
