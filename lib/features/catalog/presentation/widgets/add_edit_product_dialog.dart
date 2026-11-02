import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/product.dart';
import '../../../pos/providers/catalog_provider.dart';

/// Modal dialog allowing merchants to register items they are currently selling,
/// adjust prices, replenish stock quantities, and maintain catalog inventory.
class AddEditProductDialog extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const AddEditProductDialog({
    super.key,
    this.productToEdit,
  });

  @override
  ConsumerState<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<AddEditProductDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;

  String _selectedCategoryId = 'cat_flowers';
  int _selectedColor = 0xFF0F766E;

  static const List<int> _colorPalette = [
    0xFF0F766E, // Emerald
    0xFF0284C7, // Blue
    0xFFD97706, // Amber
    0xFF7C2D12, // Dark Brown
    0xFF78350F, // Coffee
    0xFF15803D, // Green
    0xFF4338CA, // Indigo
    0xFFEA580C, // Orange
    0xFFDC2626, // Red
    0xFF334155, // Slate
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? CurrencyFormatter.formatPlain(p.priceCents) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? '${p.stockQty}' : '25',
    );
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');

    if (p != null) {
      _selectedCategoryId = p.categoryId;
      _selectedColor = p.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.productToEdit != null;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit_note : Icons.add_business,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Edit Product / Stock' : 'Add Product to System',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusLg),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter what you are currently selling to make it instantly purchasable on terminal:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Product Name
              TextField(
                controller: _nameController,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Iced Caramel Macchiato',
                  border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Price & Stock Quantity in a responsive row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        prefixText: '₱ ',
                        hintText: '0.00',
                        border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock Units *',
                        hintText: 'e.g. 50',
                        border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: categories.any((c) => c.id == _selectedCategoryId)
                    ? _selectedCategoryId
                    : categories.first.id,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: categories
                    .where((c) => c.id != 'cat_all')
                    .map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategoryId = val);
                },
              ),
              const SizedBox(height: 12),

              // SKU & Barcode (Optional)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU (Optional)',
                        hintText: 'Auto-generated',
                        border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (Optional)',
                        hintText: 'Manual or scan ID',
                        border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Color Badge Picker
              const Text(
                'Tile Accent Color',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPalette.map((colorVal) {
                  final isSelected = _selectedColor == colorVal;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = colorVal),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.white,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 3,
                          )
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Product?'),
                  content: Text('Remove "${widget.productToEdit!.name}" from the catalog?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await ref
                      .read(catalogNotifierProvider.notifier)
                      .deleteProduct(widget.productToEdit!.id);
                  navigator.pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete product: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusMd),
          ),
          onPressed: _canSubmit ? _handleSave : null,
          child: Text(_isEditing ? 'Save Changes' : 'Add to Catalog'),
        ),
      ],
    );
  }

  bool get _canSubmit {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final priceCents = CurrencyFormatter.parseToCents(_priceController.text);
    final stock = int.tryParse(_stockController.text.trim());
    return nameValid && priceCents > 0 && stock != null && stock >= 0;
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final priceCents = CurrencyFormatter.parseToCents(_priceController.text);
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final sku = _skuController.text.trim().isNotEmpty
        ? _skuController.text.trim()
        : 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final barcode = _barcodeController.text.trim();

    try {
      final product = Product(
        id: widget.productToEdit?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
        sku: sku,
        barcode: barcode,
        name: name,
        priceCents: priceCents,
        stockQty: stock,
        categoryId: _selectedCategoryId,
        colorValue: _selectedColor,
      );

      final success = await ref.read(catalogNotifierProvider.notifier).saveProduct(product);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Product updated.' : 'Product "$name" added to catalog!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save product to database.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
