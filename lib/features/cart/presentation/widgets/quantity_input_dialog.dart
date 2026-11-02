import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/cart_item.dart';

/// Modal dialog allowing cashiers to directly set high or exact item quantities
/// with real-time total amount calculation and stock validation.
class QuantityInputDialog extends StatefulWidget {
  final CartItem item;

  const QuantityInputDialog({
    super.key,
    required this.item,
  });

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  late final TextEditingController _controller;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _controller = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateQuantity(int val) {
    final clamped = val.clamp(1, widget.item.product.stockQty);
    setState(() {
      _quantity = clamped;
      _controller.text = '$clamped';
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.item.product;
    final calculatedTotalCents = product.priceCents * _quantity;
    final maxStock = product.stockQty;
    final isExceeded = _quantity > maxStock;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set Quantity: ${product.name}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusLg),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unit Price: ${CurrencyFormatter.format(product.priceCents)} • Max Stock: $maxStock',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Quick increment chips (+1, +5, +10, +25, +50)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('1'),
                  onPressed: () => _updateQuantity(1),
                ),
                ActionChip(
                  label: const Text('5'),
                  onPressed: () => _updateQuantity(5),
                ),
                ActionChip(
                  label: const Text('10'),
                  onPressed: () => _updateQuantity(10),
                ),
                ActionChip(
                  label: const Text('+1'),
                  onPressed: () => _updateQuantity(_quantity + 1),
                ),
                ActionChip(
                  label: const Text('+5'),
                  onPressed: () => _updateQuantity(_quantity + 5),
                ),
                ActionChip(
                  label: const Text('Max Stock'),
                  onPressed: () => _updateQuantity(maxStock),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Number input field
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity to Sell',
                border: const OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _quantity = 1);
                  },
                ),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed > 0) {
                  setState(() => _quantity = parsed);
                }
              },
            ),
            const SizedBox(height: 14),

            // Dynamic calculation box: Unit Price x Quantity = Total Amount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExceeded ? AppColors.errorBg : AppColors.surfaceSubtle,
                borderRadius: AppDimens.radiusMd,
                border: Border.all(
                  color: isExceeded ? AppColors.error : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALCULATED AMOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.format(product.priceCents)} × $_quantity units',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(calculatedTotalCents),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isExceeded ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (isExceeded)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Warning: Entered $_quantity exceeds current inventory ($maxStock).',
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusMd),
          ),
          onPressed: isExceeded || _quantity <= 0
              ? null
              : () => Navigator.of(context).pop(_quantity),
          child: const Text('Apply Quantity'),
        ),
      ],
    );
  }
}
