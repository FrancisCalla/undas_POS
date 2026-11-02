import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../cart/domain/cart_state.dart';
import '../domain/payment_method.dart';
import '../../pos/providers/orders_provider.dart';

/// Modal dialog handling payment method selection, cash change calculation,
/// customer identification, and transactional commitment.
class CheckoutSummaryDialog extends ConsumerStatefulWidget {
  final CartState cartState;

  const CheckoutSummaryDialog({
    super.key,
    required this.cartState,
  });

  @override
  ConsumerState<CheckoutSummaryDialog> createState() => _CheckoutSummaryDialogState();
}

class _CheckoutSummaryDialogState extends ConsumerState<CheckoutSummaryDialog> {
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  final TextEditingController _cashTenderedController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  int _cashTenderedCents = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default cash tendered to exact total cents
    _cashTenderedCents = widget.cartState.grandTotalCents;
    _cashTenderedController.text = CurrencyFormatter.formatPlain(_cashTenderedCents);
  }

  @override
  void dispose() {
    _cashTenderedController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _setCashTendered(int cents) {
    setState(() {
      _cashTenderedCents = cents;
      _cashTenderedController.text = CurrencyFormatter.formatPlain(cents);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grandTotalCents = widget.cartState.grandTotalCents;
    final changeDueCents = _cashTenderedCents - grandTotalCents;
    final isCashInsufficient = _selectedPayment == PaymentMethod.cash && changeDueCents < 0;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checkout Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Confirm payment and settle transaction',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Content Body
              Expanded(
                child: ListView(
                  children: [
                    // Total Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cartTotalBg,
                        borderRadius: AppDimens.radiusMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.cartState.totalItemCount} Items in Order',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              Text(
                                'Taxes: ${CurrencyFormatter.format(widget.cartState.taxCents)} (${widget.cartState.taxRate.name})',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(grandTotalCents),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method Segmented Selector
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: PaymentMethod.values.map((method) {
                        final isSelected = _selectedPayment == method;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPayment = method;
                                });
                              },
                              borderRadius: AppDimens.radiusMd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.surfaceSubtle,
                                  borderRadius: AppDimens.radiusMd,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      method.icon,
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      method.displayName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // CASH TENDERED & CHANGE CALCULATOR (When Cash selected)
                    if (_selectedPayment == PaymentMethod.cash) ...[
                      const Text(
                        'Cash Tendered',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Quick Cash Chips (Philippine Peso)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('Exact'),
                            onPressed: () => _setCashTendered(grandTotalCents),
                          ),
                          ActionChip(
                            label: const Text('₱50'),
                            onPressed: () => _setCashTendered(5000),
                          ),
                          ActionChip(
                            label: const Text('₱100'),
                            onPressed: () => _setCashTendered(10000),
                          ),
                          ActionChip(
                            label: const Text('₱200'),
                            onPressed: () => _setCashTendered(20000),
                          ),
                          ActionChip(
                            label: const Text('₱500'),
                            onPressed: () => _setCashTendered(50000),
                          ),
                          ActionChip(
                            label: const Text('₱1,000'),
                            onPressed: () => _setCashTendered(100000),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Custom Cash Tendered input
                      TextField(
                        controller: _cashTenderedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount Received',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _cashTenderedCents = CurrencyFormatter.parseToCents(val);
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Change Due Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCashInsufficient ? AppColors.errorBg : AppColors.successBg,
                          borderRadius: AppDimens.radiusMd,
                          border: Border.all(
                            color: isCashInsufficient
                                ? AppColors.error.withValues(alpha: 0.3)
                                : AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCashInsufficient ? 'Insufficient Amount:' : 'Change Due:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCashInsufficient ? AppColors.error : AppColors.success,
                              ),
                            ),
                            Text(
                              isCashInsufficient
                                  ? '-${CurrencyFormatter.format(changeDueCents.abs())}'
                                  : CurrencyFormatter.format(changeDueCents),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isCashInsufficient ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Customer Details (Optional)
                    const Text(
                      'Customer Profile (Optional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Name',
                              border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _customerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone / Loyalty ID',
                              border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CONFIRMATION ACTION BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.borderStrong,
                    shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusMd),
                  ),
                  onPressed: isCashInsufficient || _isProcessing
                      ? null
                      : () => _executeCommitTransaction(),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Confirm & Settle ${CurrencyFormatter.format(grandTotalCents)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeCommitTransaction() async {
    setState(() => _isProcessing = true);

    try {
      final changeDue = _cashTenderedCents - widget.cartState.grandTotalCents;

      await ref.read(ordersNotifierProvider.notifier).finalizeCheckout(
            cartState: widget.cartState,
            paymentMethod: _selectedPayment,
            customerName: _customerNameController.text.trim().isEmpty
                ? null
                : _customerNameController.text.trim(),
            customerPhone: _customerPhoneController.text.trim().isEmpty
                ? null
                : _customerPhoneController.text.trim(),
            cashTenderedCents: _selectedPayment == PaymentMethod.cash ? _cashTenderedCents : null,
            changeDueCents: _selectedPayment == PaymentMethod.cash ? changeDue : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment accepted. Order saved.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(); // Dismiss checkout modal
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction commit failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
