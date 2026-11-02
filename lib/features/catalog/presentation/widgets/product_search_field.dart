import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../pos/providers/catalog_provider.dart';

/// Real-time search bar filtering catalog by Product Name, SKU, or Barcode ID.
class ProductSearchField extends ConsumerStatefulWidget {
  final VoidCallback onScanPressed;

  const ProductSearchField({
    super.key,
    required this.onScanPressed,
  });

  @override
  ConsumerState<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends ConsumerState<ProductSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search products by name, SKU, or barcode...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                  tooltip: 'Clear search',
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
                onPressed: widget.onScanPressed,
                tooltip: 'Scan Barcode with Camera',
              ),
              const SizedBox(width: 4),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
