import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Modal dialog for rapid ad-hoc manual sales without needing pre-existing catalog entries.
/// Computes total automatically based on item price and quantity.
class CustomItemDialog extends StatefulWidget {
  const CustomItemDialog({super.key});

  @override
  State<CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends State<CustomItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _unitPriceCents => CurrencyFormatter.parseToCents(_priceController.text);
  int get _totalAmountCents => _unitPriceCents * _quantity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flash_on, color: AppColors.accent, size: 24),
          SizedBox(width: 8),
          Text(
            'Quick Sale / Custom Item',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusLg),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sell an item directly by entering its name, price, and quantity:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Item Name
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Item Name / Description',
                  hintText: 'e.g. Handmade Mug, Mango Shake...',
                  border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Unit Price
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  prefixText: '₱ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Quantity Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity to Sell:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: AppDimens.radiusSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Quantity Chips
              Wrap(
                spacing: 8,
                children: [1, 2, 5, 10, 20].map((q) {
                  return ChoiceChip(
                    label: Text('$q'),
                    selected: _quantity == q,
                    onSelected: (selected) {
                      if (selected) setState(() => _quantity = q);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // DYNAMIC AMOUNT PREVIEW
              Container(
                padding: const EdgeInsets.all(12),
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
                        const Text(
                          'TOTAL FOR THIS ITEM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(_unitPriceCents)} × $_quantity units',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(_totalAmountCents),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          onPressed: _unitPriceCents > 0
              ? () {
                  Navigator.of(context).pop({
                    'name': _nameController.text.trim().isEmpty
                        ? 'Custom Item'
                        : _nameController.text.trim(),
                    'unitPriceCents': _unitPriceCents,
                    'quantity': _quantity,
                  });
                }
              : null,
          child: const Text('Add to Sale'),
        ),
      ],
    );
  }
}
